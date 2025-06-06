/*-------------------------------------------------------------------------
 *
 * copy_fetch.c
 *	  Functions for using a data directory as the source.
 *
 * Portions Copyright (c) 2013-2015, PostgreSQL Global Development Group
 *
 *-------------------------------------------------------------------------
 */
#include "postgres_fe.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#include "datapagemap.h"
#include "fetch.h"
#include "file_ops.h"
#include "filemap.h"
#include "logging.h"
#include "pg_rewind.h"

#include "catalog/catalog.h"

static void recurse_dir(const char *datadir, const char *path,
			process_file_callback_t callback);

static void execute_pagemap(datapagemap_t *pagemap, const char *path);

/*
 * Traverse through all files in a data directory, calling 'callback'
 * for each file.
 */
void
traverse_datadir(const char *datadir, process_file_callback_t callback)
{
	recurse_dir(datadir, NULL, callback);
}

/*
 * recursive part of traverse_datadir
 *
 * parentpath is the current subdirectory's path relative to datadir,
 * or NULL at the top level.
 */
static void
recurse_dir(const char *datadir, const char *parentpath,
			process_file_callback_t callback)
{
	DIR		   *xldir;
	struct dirent *xlde;
	char		fullparentpath[MAXPGPATH];

	if (parentpath)
		snprintf(fullparentpath, MAXPGPATH, "%s/%s", datadir, parentpath);
	else
		snprintf(fullparentpath, MAXPGPATH, "%s", datadir);

	xldir = opendir(fullparentpath);
	if (xldir == NULL)
		pg_fatal("could not open directory \"%s\": %s\n",
				 fullparentpath, strerror(errno));

	while (errno = 0, (xlde = readdir(xldir)) != NULL)
	{
		struct stat fst;
		char		fullpath[MAXPGPATH * 2];
		char		path[MAXPGPATH * 2];

		if (strcmp(xlde->d_name, ".") == 0 ||
			strcmp(xlde->d_name, "..") == 0)
			continue;

		snprintf(fullpath, sizeof(fullpath), "%s/%s", fullparentpath, xlde->d_name);

		if (lstat(fullpath, &fst) < 0)
		{
			if (errno == ENOENT)
			{
				/*
				 * File doesn't exist anymore. This is ok, if the new master
				 * is running and the file was just removed. If it was a data
				 * file, there should be a WAL record of the removal. If it
				 * was something else, it couldn't have been anyway.
				 *
				 * TODO: But complain if we're processing the target dir!
				 */
			}
			else
				pg_fatal("could not stat file \"%s\": %s\n",
						 fullpath, strerror(errno));
		}

		if (parentpath)
			snprintf(path, sizeof(path), "%s/%s", parentpath, xlde->d_name);
		else
			snprintf(path, sizeof(path), "%s", xlde->d_name);

		if (S_ISREG(fst.st_mode))
			callback(path, FILE_TYPE_REGULAR, fst.st_size, NULL);
		else if (S_ISFIFO(fst.st_mode))
		{
			/* Greengage uses FIFO for pgsql_tmp files. */
			callback(path, FILE_TYPE_FIFO, fst.st_size, NULL);
		}
		else if (S_ISDIR(fst.st_mode))
		{
			callback(path, FILE_TYPE_DIRECTORY, 0, NULL);
			/* recurse to handle subdirectories */
			recurse_dir(datadir, path, callback);
		}
#ifndef WIN32
		else if (S_ISLNK(fst.st_mode))
#else
		else if (pgwin32_is_junction(fullpath))
#endif
		{
#if defined(HAVE_READLINK) || defined(WIN32)
			char		link_target[MAXPGPATH];
			int			len;

			len = readlink(fullpath, link_target, sizeof(link_target));
			if (len < 0)
				pg_fatal("could not read symbolic link \"%s\": %s\n",
						 fullpath, strerror(errno));
			if (len >= sizeof(link_target))
				pg_fatal("symbolic link \"%s\" target is too long\n",
						 fullpath);
			link_target[len] = '\0';

			if(parentpath && strcmp(parentpath, "pg_tblspc") == 0)
			{
				/* Lop off the dbid before sending the link target. */
				char *file_sep_before_dbid_in_link_target = strrchr(link_target, '/');
				*file_sep_before_dbid_in_link_target = '\0';
			}

			callback(path, FILE_TYPE_SYMLINK, 0, link_target);

			/*
			 * If it's a symlink within pg_tblspc, we need to recurse into it,
			 * to process all the tablespaces.  We also follow a symlink if
			 * it's for pg_xlog.  Symlinks elsewhere are ignored.
			 */
			if ((parentpath && strcmp(parentpath, "pg_tblspc") == 0) ||
				strcmp(path, "pg_xlog") == 0)
				recurse_dir(datadir, path, callback);
#else
			pg_fatal("\"%s\" is a symbolic link, but symbolic links are not supported on this platform\n",
					 fullpath);
#endif   /* HAVE_READLINK */
		}
	}

	if (errno)
		pg_fatal("could not read directory \"%s\": %s\n",
				 fullparentpath, strerror(errno));

	if (closedir(xldir))
		pg_fatal("could not close directory \"%s\": %s\n",
				 fullparentpath, strerror(errno));
}

/*
 * Copy a file from source to target, between 'begin' and 'end' offsets.
 *
 * If 'trunc' is true, any existing file with the same name is truncated.
 */
static void
rewind_copy_file_range(const char *path, off_t begin, off_t end, bool trunc)
{
	char		buf[BLCKSZ];
	char		srcpath[MAXPGPATH];
	int			srcfd;

	snprintf(srcpath, sizeof(srcpath), "%s/%s", datadir_source, path);

	srcfd = open(srcpath, O_RDONLY | PG_BINARY, 0);
	if (srcfd < 0)
		pg_fatal("could not open source file \"%s\": %s\n",
				 srcpath, strerror(errno));

	if (lseek(srcfd, begin, SEEK_SET) == -1)
		pg_fatal("could not seek in source file: %s\n", strerror(errno));

	open_target_file(path, trunc);

	while (end - begin > 0)
	{
		int			readlen;
		int			len;

		if (end - begin > sizeof(buf))
			len = sizeof(buf);
		else
			len = end - begin;

		readlen = read(srcfd, buf, len);

		if (readlen < 0)
			pg_fatal("could not read file \"%s\": %s\n",
					 srcpath, strerror(errno));
		else if (readlen == 0)
			pg_fatal("unexpected EOF while reading file \"%s\"\n", srcpath);

		write_target_range(buf, begin, readlen);
		begin += readlen;
	}

	if (close(srcfd) != 0)
		pg_fatal("could not close file \"%s\": %s\n", srcpath, strerror(errno));
}

/*
 * Copy all relation data files from datadir_source to datadir_target, which
 * are marked in the given data page map.
 */
void
copy_executeFileMap(filemap_t *map)
{
	file_entry_t *entry;
	int			i;

	for (i = 0; i < map->narray; i++)
	{
		entry = map->array[i];
		execute_pagemap(&entry->target_pages_to_overwrite, entry->path);

		switch (entry->action)
		{
			case FILE_ACTION_NONE:
				/* ok, do nothing.. */
				break;

			case FILE_ACTION_COPY:
				rewind_copy_file_range(entry->path, 0, entry->source_size, true);
				break;

			case FILE_ACTION_TRUNCATE:
				truncate_target_file(entry->path, entry->source_size);
				break;

			case FILE_ACTION_COPY_TAIL:
				rewind_copy_file_range(entry->path, entry->target_size,
									   entry->source_size, false);
				break;

			case FILE_ACTION_CREATE:
				create_target(entry);
				break;

			case FILE_ACTION_REMOVE:
				remove_target(entry);
				break;

			case FILE_ACTION_UNDECIDED:
				pg_fatal("no action decided for \"%s\"", entry->path);
				break;
		}
	}

	close_target_file();
}

static void
execute_pagemap(datapagemap_t *pagemap, const char *path)
{
	datapagemap_iterator_t *iter;
	BlockNumber blkno;
	off_t		offset;

	iter = datapagemap_iterate(pagemap);
	while (datapagemap_next(iter, &blkno))
	{
		offset = blkno * BLCKSZ;
		rewind_copy_file_range(path, offset, offset + BLCKSZ, false);
		/* Ok, this block has now been copied from new data dir to old */
	}
	pg_free(iter);
}
