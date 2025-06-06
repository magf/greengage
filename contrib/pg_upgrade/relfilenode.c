/*
 *	relfilenode.c
 *
 *	relfilenode functions
 *
 *	Copyright (c) 2010-2014, PostgreSQL Global Development Group
 *	contrib/pg_upgrade/relfilenode.c
 */

#include "postgres_fe.h"

#include "pg_upgrade.h"

#include "catalog/pg_class.h"
#include "access/aomd.h"
#include "access/appendonlytid.h"
#include "access/htup_details.h"
#include "access/transam.h"

#include "greengage/pg_upgrade_greengage.h"

static void transfer_single_new_db(FileNameMap *maps, int size, char *old_tablespace);
static void transfer_relfile(FileNameMap *map, const char *suffix);
static bool transfer_relfile_segment(int segno, FileNameMap *map, const char *suffix);
static void transfer_ao(FileNameMap *map);
static bool transfer_ao_perFile(const int segno, void *ctx);

/*
 * transfer_all_new_tablespaces()
 *
 * Responsible for upgrading all database. invokes routines to generate mappings and then
 * physically link the databases.
 */
void
transfer_all_new_tablespaces(DbInfoArr *old_db_arr, DbInfoArr *new_db_arr,
							 char *old_pgdata, char *new_pgdata)
{
	prep_status("%s user relation files\n",
	  user_opts.transfer_mode == TRANSFER_MODE_LINK ? "Linking" : "Copying");

	/*
	 * Transfering files by tablespace is tricky because a single database can
	 * use multiple tablespaces.  For non-parallel mode, we just pass a NULL
	 * tablespace path, which matches all tablespaces.  In parallel mode, we
	 * pass the default tablespace and all user-created tablespaces and let
	 * those operations happen in parallel.
	 *
	 * GPDB: Disable pg_upgrade's broken parallel tablespace transfer to make the rest
	 * of the parallelism from the --jobs flag usable now to get a performance
	 * boost.
	 */
	if (true) /* (user_opts.jobs <= 1) */
		parallel_transfer_all_new_dbs(old_db_arr, new_db_arr, old_pgdata,
									  new_pgdata, NULL);
	else
	{
		int			tblnum;

		/* transfer default tablespace */
		parallel_transfer_all_new_dbs(old_db_arr, new_db_arr, old_pgdata,
									  new_pgdata, old_pgdata);

		for (tblnum = 0; tblnum < os_info.num_old_tablespaces; tblnum++)
			parallel_transfer_all_new_dbs(old_db_arr,
										  new_db_arr,
										  old_pgdata,
										  new_pgdata,
										  os_info.old_tablespaces[tblnum]);
		/* reap all children */
		while (reap_child(true) == true)
			;
	}

	end_progress_output();
	check_ok();

	return;
}


/*
 * transfer_all_new_dbs()
 *
 * Responsible for upgrading all database. invokes routines to generate mappings and then
 * physically link the databases.
 */
void
transfer_all_new_dbs(DbInfoArr *old_db_arr, DbInfoArr *new_db_arr,
					 char *old_pgdata, char *new_pgdata, char *old_tablespace)
{
	int			old_dbnum,
				new_dbnum;

	/* Scan the old cluster databases and transfer their files */
	for (old_dbnum = new_dbnum = 0;
		 old_dbnum < old_db_arr->ndbs;
		 old_dbnum++, new_dbnum++)
	{
		DbInfo	   *old_db = &old_db_arr->dbs[old_dbnum],
				   *new_db = NULL;
		FileNameMap *mappings;
		int			n_maps;

		/*
		 * Advance past any databases that exist in the new cluster but not in
		 * the old, e.g. "postgres".  (The user might have removed the
		 * 'postgres' database from the old cluster.)
		 */
		for (; new_dbnum < new_db_arr->ndbs; new_dbnum++)
		{
			new_db = &new_db_arr->dbs[new_dbnum];
			if (strcmp(old_db->db_name, new_db->db_name) == 0)
				break;
		}

		if (new_dbnum >= new_db_arr->ndbs)
			pg_fatal("old database \"%s\" not found in the new cluster\n",
					 old_db->db_name);

		n_maps = 0;
		mappings = gen_db_file_maps(old_db, new_db, &n_maps, old_pgdata,
									new_pgdata);

		if (n_maps)
		{
			print_maps(mappings, n_maps, new_db->db_name);

			transfer_single_new_db(mappings, n_maps, old_tablespace);
		}
		/* We allocate something even for n_maps == 0 */
		pg_free(mappings);
	}

	return;
}


/*
 * transfer_single_new_db()
 *
 * create links for mappings stored in "maps" array.
 */
static void
transfer_single_new_db(FileNameMap *maps, int size, char *old_tablespace)
{
	int			mapnum;
	bool		vm_crashsafe_match = true;

	/*
	 * Do the old and new cluster disagree on the crash-safetiness of the vm
	 * files?  If so, do not copy them.
	 */
	if (old_cluster.controldata.cat_ver < VISIBILITY_MAP_CRASHSAFE_CAT_VER &&
		new_cluster.controldata.cat_ver >= VISIBILITY_MAP_CRASHSAFE_CAT_VER)
		vm_crashsafe_match = false;

	for (mapnum = 0; mapnum < size; mapnum++)
	{
		if (old_tablespace == NULL ||
			strcmp(maps[mapnum].old_tablespace, old_tablespace) == 0)
		{
			RelType type = maps[mapnum].type;

			if (type == AO || type == AOCS)
			{
				transfer_ao(&maps[mapnum]);
			}
			else
			{
				/* transfer primary file */
				transfer_relfile(&maps[mapnum], "");

				/* fsm/vm files added in PG 8.4 */
				if (GET_MAJOR_VERSION(old_cluster.major_version) >= 804)
				{
					/*
					 * Copy/link any fsm and vm files, if they exist
					 */
					transfer_relfile(&maps[mapnum], "_fsm");
					if (vm_crashsafe_match)
						transfer_relfile(&maps[mapnum], "_vm");
				}
			}
		}
	}
}

/*
 * transfer_relfile()
 *
 * Copy or link file from old cluster to new one.
 */
static void
transfer_relfile(FileNameMap *map, const char *type_suffix)
{
	int			segno;

	/*
	 * Now copy/link any related segments as well. Remember, PG breaks large
	 * files into 1GB segments, the first segment has no extension, subsequent
	 * segments are named relfilenode.1, relfilenode.2, relfilenode.3. copied.
	 */
	for (segno = 0;; segno++)
	{
		if (!transfer_relfile_segment(segno, map, type_suffix))
			break;
	}
}

/*
 * GPDB: the body of transfer_relfile(), above, has moved into this function to
 * facilitate the implementation of transfer_ao().
 *
 * Returns true if the segment file was found, and false if it was not. Failures
 * during transfer are fatal. The case where we cannot find the segment-zero
 * file (the one without an extent suffix) for a relation is also fatal, since
 * we expect that to exist for both heap and AO tables in any case.
 *
 */
static bool
transfer_relfile_segment(int segno, FileNameMap *map, const char *type_suffix)
{
	const char *msg;
	char		old_file[MAXPGPATH * 3];
	char		new_file[MAXPGPATH * 3];
	char		new_file_fsm[MAXPGPATH * 3];
	char		new_file_vm[MAXPGPATH * 3];
	int			fd;
	char		extent_suffix[65];
	bool is_ao_or_aocs = (map->type == AO || map->type == AOCS);

	/*
	 * Extra indentation is on purpose, to reduce merge conflicts with upstream.
	 */

		if (segno == 0)
			extent_suffix[0] = '\0';
		else
			snprintf(extent_suffix, sizeof(extent_suffix), ".%d", segno);

		snprintf(old_file, sizeof(old_file), "%s%s/%u/%u%s%s",
				 map->old_tablespace,
				 map->old_tablespace_suffix,
				 map->old_db_oid,
				 map->old_relfilenode,
				 type_suffix,
				 extent_suffix);
		snprintf(new_file, sizeof(new_file), "%s%s/%u/%u%s%s",
				 map->new_tablespace,
				 map->new_tablespace_suffix,
				 map->new_db_oid,
				 map->new_relfilenode,
				 type_suffix,
				 extent_suffix);
		snprintf(new_file_fsm, sizeof(new_file_fsm), "%s%s/%u/%u%s%s",
				map->new_tablespace,
				map->new_tablespace_suffix,
				map->new_db_oid,
				map->new_relfilenode,
				"_fsm",
				extent_suffix);
		snprintf(new_file_vm, sizeof(new_file_vm), "%s%s/%u/%u%s%s",
				map->new_tablespace,
				map->new_tablespace_suffix,
				map->new_db_oid,
				map->new_relfilenode,
				"_vm",
				extent_suffix);

		/* Is it an extent, fsm, or vm file?
		 */
		if (type_suffix[0] != '\0' || segno != 0  || is_ao_or_aocs)
		{
			/* Did file open fail? */
			if ((fd = open(old_file, O_RDONLY, 0)) == -1)
			{
				if (errno == ENOENT)
				{
					if (is_ao_or_aocs && segno == 0)
					{
						/*
						 * In GPDB 5, an AO table's baserelfilenode may not exists
						 * after vacuum.  However, in GPDB 6 this is not the case as
						 * baserelfilenode is expected to always exist.  In order to
						 * align with GPDB 6 expectations we copy an empty
						 * baserelfilenode in the scenario where it didn't exist in
						 * GPDB 5.
						 */
						Assert(GET_MAJOR_VERSION(old_cluster.major_version) <= 803);
						fd = open(new_file, O_CREAT, S_IRUSR|S_IWUSR);
						if (fd == -1)
							pg_fatal("error while creating empty file \"%s.%s\" (\"%s\" to \"%s\"): %s\n",
									 map->nspname, map->relname, old_file, new_file,
									 getErrorText());
						return true;
					}
					else
						return false;
				}
				else
					pg_fatal("error while checking for file existence \"%s.%s\" (\"%s\" to \"%s\"): %s\n",
							 map->nspname, map->relname, old_file, new_file,
							 getErrorText());
			}
			close(fd);
		}

	unlink(new_file);

	/*
	 * Because gpupgrade needs to copy MDD to segments in order to bootstrap
	 * upgrade segments, coordinator's relfilenodes, _fsm, _vm files will end up
	 * on segments. Normally this is ok since the files will end up being
	 * overwritten. However, there is an edge case where there can be data in a
	 * table on coordinator, but no data on the segment. Examples of such tables
	 * where this can occur are pg_ao(cs)seg tables. If this edge case happens,
	 * The new segment's table will end up with old segment's relfilenode and new
	 * coordinator's _fsm and _vm file. The _fsm and _vm files don't get
	 * overwritten because they aren't supposed to exist on the segment.
	 * Attempting to run VACUUM on this table after upgrade completes will
	 * result in a similar error below.
	 *
	 * ERROR:  could not read block 0 in file "base/16394/16393": read only 0 of 32768 bytes
	 *
	 * To prevent this failure, delete any _fsm or _vm files that should not exist
	 */
	if (type_suffix[0] == '\0')
	{
		unlink(new_file_fsm);
		unlink(new_file_vm);
	}

	/* Copying files might take some time, so give feedback. */
	pg_log(PG_STATUS, "%s", old_file);

		if (user_opts.transfer_mode == TRANSFER_MODE_COPY)
		{
			pg_log(PG_VERBOSE, "copying \"%s\" to \"%s\"\n", old_file, new_file);

			if ((msg = copyFile(old_file, new_file, true)) != NULL)
				pg_fatal("error while copying relation \"%s.%s\" (\"%s\" to \"%s\"): %s\n",
						 map->nspname, map->relname, old_file, new_file, msg);
		}
		else
		{
			pg_log(PG_VERBOSE, "linking \"%s\" to \"%s\"\n", old_file, new_file);

			if ((msg = linkFile(old_file, new_file)) != NULL)
				pg_fatal("error while creating link for relation \"%s.%s\" (\"%s\" to \"%s\"): %s\n",
						 map->nspname, map->relname, old_file, new_file, msg);
		}

	return true;
}

struct transfer_ao_callback_ctx {
	FileNameMap *map;
};

static void
transfer_ao(FileNameMap *map)
{
	struct transfer_ao_callback_ctx upgradeFiles = { 0 };

	transfer_relfile_segment(0, map, "");

	upgradeFiles.map = map;

  ao_foreach_extent_file(transfer_ao_perFile, &upgradeFiles);
}

static bool
transfer_ao_perFile(const int segno, void *ctx)
{
	const struct transfer_ao_callback_ctx *upgradeFiles = ctx;

	if (!transfer_relfile_segment(segno, upgradeFiles->map , ""))
		return false;

	return true;
}
