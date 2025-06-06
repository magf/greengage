/*
 *	pg_upgrade.c
 *
 *	main source file
 *
 *	Copyright (c) 2010-2014, PostgreSQL Global Development Group
 *	Portions Copyright (c) 2016-Present, Pivotal Software Inc
 *	contrib/pg_upgrade/pg_upgrade.c
 */

/*
 *	To simplify the upgrade process, we force certain system values to be
 *	identical between old and new clusters:
 *
 *	We control all assignments of pg_class.oid (and relfilenode) so toast
 *	oids are the same between old and new clusters.  This is important
 *	because toast oids are stored as toast pointers in user tables.
 *
 *	While pg_class.oid and pg_class.relfilenode are initially the same
 *	in a cluster, they can diverge due to CLUSTER, REINDEX, or VACUUM
 *	FULL.  In the new cluster, pg_class.oid and pg_class.relfilenode will
 *	be the same and will match the old pg_class.oid value.  Because of
 *	this, old/new pg_class.relfilenode values will not match if CLUSTER,
 *	REINDEX, or VACUUM FULL have been performed in the old cluster.
 *
 *	We control all assignments of pg_type.oid because these oids are stored
 *	in user composite type values.
 *
 *	We control all assignments of pg_enum.oid because these oids are stored
 *	in user tables as enum values.
 *
 *	We control all assignments of pg_authid.oid because these oids are stored
 *	in pg_largeobject_metadata.
 */



#include "postgres_fe.h"

#include "pg_upgrade.h"

#ifdef HAVE_LANGINFO_H
#include <langinfo.h>
#endif

#include "greengage/old_tablespace_file_parser_observer.h"
#include "greengage/pg_upgrade_greengage.h"

static void prepare_new_cluster(void);
static void prepare_new_databases(void);
static void create_new_objects(void);
static void copy_clog_xlog_xid(void);
static void set_frozenxids(bool minmxid_only);
static void setup(char *argv0, bool *live_check);
static void cleanup(void);
static void	get_restricted_token(const char *progname);

static void copy_subdir_files(char *subdir);

#ifdef WIN32
static int	CreateRestrictedProcess(char *cmd, PROCESS_INFORMATION *processInfo, const char *progname);
#endif

ClusterInfo old_cluster,
			new_cluster;
OSInfo		os_info;

char	   *output_files[] = {
	SERVER_LOG_FILE,
#ifdef WIN32
	/* unique file for pg_ctl start */
	SERVER_START_LOG_FILE,
#endif
	UTILITY_LOG_FILE,
	INTERNAL_LOG_FILE,
	NULL
};

#ifdef WIN32
static char *restrict_env;
#endif

/* This is the database used by pg_dumpall to restore global tables */
#define GLOBAL_DUMP_DB	"postgres"

ClusterInfo old_cluster,
			new_cluster;
OSInfo		os_info;

void
OldTablespaceFileParser_invalid_access_error_for_row(int invalid_row_index)
{
	pg_fatal("attempted to read an invalid row from an old tablespace file. row index %d",
	         invalid_row_index);
}

void
OldTablespaceFileParser_invalid_access_error_for_field(int invalid_row_index, int invalid_field_index)
{
	pg_fatal("attempted to read an invalid field from an old tablespace file. row index %d, field index %d",
	         invalid_row_index, invalid_field_index);
}

int
main(int argc, char **argv)
{
	char	   *sequence_script_file_name = NULL;
	char	   *analyze_script_file_name = NULL;
	char	   *deletion_script_file_name = NULL;
	bool		live_check = false;
	step_timer 	t;

	/* Ensure that all files created by pg_upgrade are non-world-readable */
	umask(S_IRWXG | S_IRWXO);

	parseCommandLine(argc, argv);

	INSTR_TIME_SET_CURRENT(t.start_time);

	get_restricted_token(os_info.progname);

	adjust_data_dir(&old_cluster);

	if(!is_skip_target_check())
		adjust_data_dir(&new_cluster);

	setup(argv[0], &live_check);

	report_progress(NULL, CHECK, "Checking cluster compatibility");
	output_check_banner(live_check);

	check_cluster_versions();

	get_sock_dir(&old_cluster, live_check);

	if(!is_skip_target_check())
		get_sock_dir(&new_cluster, false);

	/* not skipped for is_skip_target_check because of some checks on
	 * old_cluster are done independently of new_cluster
	 */
	check_cluster_compatibility(live_check);

	check_and_dump_old_cluster(live_check, &sequence_script_file_name);


	/* -- NEW -- */
	if(!is_skip_target_check())
	{
		start_postmaster(&new_cluster, true);
		check_new_cluster();
	}

	log_with_timing(&t, "\nPerforming Consistency Checks took");
	report_clusters_compatible();

	pg_log(PG_REPORT, "\nPerforming Upgrade\n");
	pg_log(PG_REPORT, "------------------\n");

	INSTR_TIME_SET_CURRENT(t.start_time);

	prepare_new_cluster();

	stop_postmaster(false);

	/*
	 * Destructive Changes to New Cluster
	 */

	copy_clog_xlog_xid();

	/*
	 * GPDB: This used to be right before syncing the data directory to disk
	 * but is needed here before create_new_objects() due to our usage of a
	 * preserved oid list. When creating new objects on the target cluster,
	 * objects that do not have a preassigned oid will try to get a new oid
	 * from the oid counter. This works in upstream Postgres but can be slow
	 * in GPDB because the new oid is checked against the preserved oid
	 * list. If the new oid is in the preserved oid list, a new oid is
	 * generated from the oid counter until a valid oid is found. In
	 * production scenarios, it would be very common to have a very, very
	 * large preserved oid list and starting the oid counter from
	 * FirstNormalObjectId (16384) would make object creation slower than
	 * usual near the beginning of pg_restore. To prevent pg_restore
	 * performance degradation from so many invalid new oids from the oid
	 * counter, bump the oid counter to what the source cluster has via
	 * pg_resetxlog. If the preserved oid list logic is removed from
	 * pg_upgrade, move this step back to where it was before.
	 */
	prep_status("Setting next OID for new cluster");
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  "\"%s/pg_resetxlog\" --binary-upgrade -o %u \"%s\"",
			  new_cluster.bindir, old_cluster.controldata.chkpnt_nxtoid,
			  new_cluster.pgdata);
	check_ok();

	/*
	 * In upgrading from GPDB4, copy the pg_distributedlog over in vanilla.
	 * The assumption that this works needs to be verified
	 */
	copy_subdir_files("pg_distributedlog");

	/* New now using xids of the old system */

	/* -- NEW -- */
	start_postmaster(&new_cluster, true);

	if (is_greengage_dispatcher_mode())
	{
		prepare_new_databases();

		create_new_objects();
	}
	else
	{
		/*
		 * GPDB: We run set_frozenxids, update_db_xids, and freeze_master_data
		 * to update relfrozenxid and relminmxid for all applicable relations
		 * according to the master. This same catalog was copied over to the
		 * segments to initialize their catalog but the relfrozenxid and
		 * relminmxid should reflect the values from the corresponding segment
		 * database. So, update the xids on the segments for user and catalog
		 * tables. If this step is not done on segments, subsequent vacuum
		 * freeze can complain that the xmin <some low number> from before
		 * relfrozenxid <some higher number>.
		 */
		set_frozenxids(false);
	}

	invalidate_indexes();

	/*
	 * Since freeze_master_data() was executed on the copied master, the xmin of
	 * the tuples (yet to be copied/linked) for the user created tables can be
	 * lower than the relfrozenxid updated with vacuum freeze.
	 * So, it's safe / better to update the relfrozenxid, relminmxid for the
	 * relations using datfrozenxid which is the lowest available relfrozenxid
	 * for all the relation in the source database and datminmxid which is the minimum
	 * of relminmxid for all the relations in source database. This ensures that the
	 * xmin of the tuples will not be higher than relfrozenxid for the relation.
	 * Otherwise, vacuuming those tables once data is copied/linked will error out.
	 */
	if (!is_greengage_dispatcher_mode())
		update_db_xids();

	stop_postmaster(false);

	/*
	 * Most failures happen in create_new_objects(), which has completed at
	 * this point.  We do this here because it is just before linking, which
	 * will link the old and new cluster data files, preventing the old
	 * cluster from being safely started once the new cluster is started.
	 */
	if (user_opts.transfer_mode == TRANSFER_MODE_LINK)
		disable_old_cluster();

	transfer_all_new_tablespaces(&old_cluster.dbarr, &new_cluster.dbarr,
								 old_cluster.pgdata, new_cluster.pgdata);

	/*
	 * Tuples of gp_fastsequence are being upgraded using relfilenode transfer.
	 * Freezing coordinator's data must happen after relfilenodes land. We also
	 * need to fix the tuple's xmin to ensure they are lower than the
	 * relfrozenxid. Otherwise subsequent vacuums may fail.
	 */
	if (is_greengage_dispatcher_mode())
	{
		start_postmaster(&new_cluster, true);

		update_db_xids();
		freeze_master_data();

		stop_postmaster(false);
	}

	/* For non-master segments, uniquify the system identifier. */
	if (!is_greengage_dispatcher_mode())
		reset_system_identifier();

	prep_status("Sync data directory to disk");
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  "\"%s/initdb\" --sync-only \"%s\"", new_cluster.bindir,
			  new_cluster.pgdata);
	check_ok();

	create_script_for_cluster_analyze(&analyze_script_file_name);
	create_script_for_old_cluster_deletion(&deletion_script_file_name);

	issue_warnings_and_set_wal_level(sequence_script_file_name);

	log_with_timing(&t, "\nPerforming Upgrade took");

	pg_log(PG_REPORT, "\nUpgrade Complete\n");
	pg_log(PG_REPORT, "----------------\n");

	report_progress(NULL, DONE, "Upgrade complete");
	close_progress();

	output_completion_banner(analyze_script_file_name,
							 deletion_script_file_name);

	pg_free(analyze_script_file_name);
	pg_free(deletion_script_file_name);
	pg_free(sequence_script_file_name);

	cleanup();

	return 0;
}

#ifdef WIN32
typedef BOOL(WINAPI * __CreateRestrictedToken) (HANDLE, DWORD, DWORD, PSID_AND_ATTRIBUTES, DWORD, PLUID_AND_ATTRIBUTES, DWORD, PSID_AND_ATTRIBUTES, PHANDLE);

/* Windows API define missing from some versions of MingW headers */
#ifndef  DISABLE_MAX_PRIVILEGE
#define DISABLE_MAX_PRIVILEGE	0x1
#endif

/*
* Create a restricted token and execute the specified process with it.
*
* Returns 0 on failure, non-zero on success, same as CreateProcess().
*
* On NT4, or any other system not containing the required functions, will
* NOT execute anything.
*/
static int
CreateRestrictedProcess(char *cmd, PROCESS_INFORMATION *processInfo, const char *progname)
{
	BOOL		b;
	STARTUPINFO si;
	HANDLE		origToken;
	HANDLE		restrictedToken;
	SID_IDENTIFIER_AUTHORITY NtAuthority = { SECURITY_NT_AUTHORITY };
	SID_AND_ATTRIBUTES dropSids[2];
	__CreateRestrictedToken _CreateRestrictedToken = NULL;
	HANDLE		Advapi32Handle;

	ZeroMemory(&si, sizeof(si));
	si.cb = sizeof(si);

	Advapi32Handle = LoadLibrary("ADVAPI32.DLL");
	if (Advapi32Handle != NULL)
	{
		_CreateRestrictedToken = (__CreateRestrictedToken)GetProcAddress(Advapi32Handle, "CreateRestrictedToken");
	}

	if (_CreateRestrictedToken == NULL)
	{
		fprintf(stderr, _("%s: WARNING: cannot create restricted tokens on this platform\n"), progname);
		if (Advapi32Handle != NULL)
			FreeLibrary(Advapi32Handle);
		return 0;
	}

	/* Open the current token to use as a base for the restricted one */
	if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ALL_ACCESS, &origToken))
	{
		fprintf(stderr, _("%s: could not open process token: error code %lu\n"), progname, GetLastError());
		return 0;
	}

	/* Allocate list of SIDs to remove */
	ZeroMemory(&dropSids, sizeof(dropSids));
	if (!AllocateAndInitializeSid(&NtAuthority, 2,
		SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0,
		0, &dropSids[0].Sid) ||
		!AllocateAndInitializeSid(&NtAuthority, 2,
		SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_POWER_USERS, 0, 0, 0, 0, 0,
		0, &dropSids[1].Sid))
	{
		fprintf(stderr, _("%s: could not allocate SIDs: error code %lu\n"), progname, GetLastError());
		return 0;
	}

	b = _CreateRestrictedToken(origToken,
						DISABLE_MAX_PRIVILEGE,
						sizeof(dropSids) / sizeof(dropSids[0]),
						dropSids,
						0, NULL,
						0, NULL,
						&restrictedToken);

	FreeSid(dropSids[1].Sid);
	FreeSid(dropSids[0].Sid);
	CloseHandle(origToken);
	FreeLibrary(Advapi32Handle);

	if (!b)
	{
		fprintf(stderr, _("%s: could not create restricted token: error code %lu\n"), progname, GetLastError());
		return 0;
	}

#ifndef __CYGWIN__
	AddUserToTokenDacl(restrictedToken);
#endif

	if (!CreateProcessAsUser(restrictedToken,
							NULL,
							cmd,
							NULL,
							NULL,
							TRUE,
							CREATE_SUSPENDED,
							NULL,
							NULL,
							&si,
							processInfo))

	{
		fprintf(stderr, _("%s: could not start process for command \"%s\": error code %lu\n"), progname, cmd, GetLastError());
		return 0;
	}

	return ResumeThread(processInfo->hThread);
}
#endif

static void
get_restricted_token(const char *progname)
{
#ifdef WIN32

	/*
	* Before we execute another program, make sure that we are running with a
	* restricted token. If not, re-execute ourselves with one.
	*/

	if ((restrict_env = getenv("PG_RESTRICT_EXEC")) == NULL
		|| strcmp(restrict_env, "1") != 0)
	{
		PROCESS_INFORMATION pi;
		char	   *cmdline;

		ZeroMemory(&pi, sizeof(pi));

		cmdline = pg_strdup(GetCommandLine());

		putenv("PG_RESTRICT_EXEC=1");

		if (!CreateRestrictedProcess(cmdline, &pi, progname))
		{
			fprintf(stderr, _("%s: could not re-execute with restricted token: error code %lu\n"), progname, GetLastError());
		}
		else
		{
			/*
			* Successfully re-execed. Now wait for child process to capture
			* exitcode.
			*/
			DWORD		x;

			CloseHandle(pi.hThread);
			WaitForSingleObject(pi.hProcess, INFINITE);

			if (!GetExitCodeProcess(pi.hProcess, &x))
			{
				fprintf(stderr, _("%s: could not get exit code from subprocess: error code %lu\n"), progname, GetLastError());
				exit(1);
			}
			exit(x);
		}
	}
#endif
}

static void
setup(char *argv0, bool *live_check)
{
	char		exec_path[MAXPGPATH];	/* full path to my executable */

	/*
	 * make sure the user has a clean environment, otherwise, we may confuse
	 * libpq when we connect to one (or both) of the servers.
	 */
	check_pghost_envvar();

	verify_directories();

	/* no postmasters should be running, except for a live check */
	if (pid_lock_file_exists(old_cluster.pgdata))
	{
		/*
		 * If we have a postmaster.pid file, try to start the server.  If it
		 * starts, the pid file was stale, so stop the server.  If it doesn't
		 * start, assume the server is running.  If the pid file is left over
		 * from a server crash, this also allows any committed transactions
		 * stored in the WAL to be replayed so they are not lost, because WAL
		 * files are not transfered from old to new servers.  We later check
		 * for a clean shutdown.
		 */
		if (start_postmaster(&old_cluster, false))
			stop_postmaster(false);
		else
		{
			if (!user_opts.check)
				pg_fatal("There seems to be a postmaster servicing the old cluster.\n"
						 "Please shutdown that postmaster and try again.\n");
			else
				*live_check = true;
		}
	}

	/* same goes for the new postmaster */
	if(!is_skip_target_check())
	{
		if (pid_lock_file_exists(new_cluster.pgdata))
		{
			if (start_postmaster(&new_cluster, false))
				stop_postmaster(false);
			else
				pg_fatal("There seems to be a postmaster servicing the new cluster.\n"
						 "Please shutdown that postmaster and try again.\n");
		}
	}

	/* get path to pg_upgrade executable */
	if (find_my_exec(argv0, exec_path) < 0)
		pg_fatal("Could not get path name to pg_upgrade: %s\n", getErrorText());

	/* Trim off program name and keep just path */
	*last_dir_separator(exec_path) = '\0';
	canonicalize_path(exec_path);
	os_info.exec_path = pg_strdup(exec_path);
}


static void
prepare_new_cluster(void)
{
	/*
	 * It would make more sense to freeze after loading the schema, but that
	 * would cause us to lose the frozenids restored by the load. We use
	 * --analyze so autovacuum doesn't update statistics later
	 *
	 * GPDB: after we've copied the master data directory to the segments,
	 * AO tables can't be analyzed because their aoseg tuple counts don't match
	 * those on disk. We therefore skip this step for segments.
	 */
	if (is_greengage_dispatcher_mode())
	{
		prep_status("Analyzing all rows in the new cluster");
		exec_prog(UTILITY_LOG_FILE, NULL, true, true,
				  PG_OPTIONS_UTILITY_MODE
				  "\"%s/vacuumdb\" %s --all --analyze %s",
				  new_cluster.bindir, cluster_conn_opts(&new_cluster),
				  log_opts.verbose ? "--verbose" : "");
		check_ok();
	}

	/*
	 * We do freeze after analyze so pg_statistic is also frozen. template0 is
	 * not frozen here, but data rows were frozen by initdb, and we set its
	 * datfrozenxid, relfrozenxids, and relminmxid later to match the new xid
	 * counter later.
	 */
	prep_status("Freezing all rows on the new cluster");
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  PG_OPTIONS_UTILITY_MODE
			  "\"%s/vacuumdb\" %s --all --freeze %s",
			  new_cluster.bindir, cluster_conn_opts(&new_cluster),
			  log_opts.verbose ? "--verbose" : "");
	check_ok();

}


static void
prepare_new_databases(void)
{
	/*
	 * Before we restore anything, set frozenxids of initdb-created tables.
	 */
	set_frozenxids(false);

	/*
	 * Now restore global objects (roles and tablespaces).
	 */
	prep_status("Restoring global objects in the new cluster");

	/*
	 * Install support functions in the global-object restore database to
	 * preserve pg_authid.oid.  pg_dumpall uses 'template0' as its template
	 * database so objects we add into 'template1' are not propogated.  They
	 * are removed on pg_upgrade exit.
	 */
	install_support_functions_in_new_db("template1");

	/*
	 * We have to create the databases first so we can install support
	 * functions in all the other databases.  Ideally we could create the
	 * support functions in template1 but pg_dumpall creates database using
	 * the template0 template.
	 */
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  PG_OPTIONS_UTILITY_MODE
			  "\"%s/psql\" " EXEC_PSQL_ARGS " %s -f \"%s\"",
			  new_cluster.bindir, cluster_conn_opts(&new_cluster),
			  GLOBALS_DUMP_FILE);
	check_ok();

	/* we load this to get a current list of databases */
	get_db_and_rel_infos(&new_cluster);
}


static void
create_new_objects(void)
{
	int			dbnum;

	prep_status("Adding support functions to new cluster");

	/*
	 * Technically, we only need to install these support functions in new
	 * databases that also exist in the old cluster, but for completeness we
	 * process all new databases.
	 */
	for (dbnum = 0; dbnum < new_cluster.dbarr.ndbs; dbnum++)
	{
		DbInfo	   *new_db = &new_cluster.dbarr.dbs[dbnum];

		/* skip db we already installed */
		if (strcmp(new_db->db_name, "template1") != 0)
			install_support_functions_in_new_db(new_db->db_name);
	}
	check_ok();

	prep_status("Restoring database schemas in the new cluster\n");

	for (dbnum = 0; dbnum < old_cluster.dbarr.ndbs; dbnum++)
	{
		char		sql_file_name[MAXPGPATH],
					log_file_name[MAXPGPATH];
		DbInfo	   *old_db = &old_cluster.dbarr.dbs[dbnum];
		PQExpBufferData connstr,
					escaped_connstr;

		initPQExpBuffer(&connstr);
		appendPQExpBuffer(&connstr, "dbname=");
		appendConnStrVal(&connstr, old_db->db_name);
		initPQExpBuffer(&escaped_connstr);
		appendShellString(&escaped_connstr, connstr.data);
		termPQExpBuffer(&connstr);

		pg_log(PG_STATUS, "%s", old_db->db_name);
		snprintf(sql_file_name, sizeof(sql_file_name), DB_DUMP_FILE_MASK, old_db->db_oid);
		snprintf(log_file_name, sizeof(log_file_name), DB_DUMP_LOG_FILE_MASK, old_db->db_oid);

		/*
		 * pg_dump only produces its output at the end, so there is little
		 * parallelism if using the pipe.
		 */
		parallel_exec_prog(log_file_name,
						   NULL,
		 PG_OPTIONS_UTILITY_MODE
		 "\"%s/pg_restore\" %s --exit-on-error --binary-upgrade --verbose --dbname %s \"%s\"",
						   new_cluster.bindir,
						   cluster_conn_opts(&new_cluster),
						   escaped_connstr.data,
						   sql_file_name);

		termPQExpBuffer(&escaped_connstr);
	}

	/* reap all children */
	while (reap_child(true) == true)
		;

	end_progress_output();
	check_ok();

	/*
	 * We don't have minmxids for databases or relations in pre-9.3
	 * clusters, so set those after we have restored the schema.
	 */
	if (GET_MAJOR_VERSION(old_cluster.major_version) < 903)
		set_frozenxids(true);

	/* regenerate now that we have objects in the databases */
	get_db_and_rel_infos(&new_cluster);

	uninstall_support_functions_from_new_cluster();

}


/*
 * Delete the given subdirectory contents from the new cluster
 */
static void
remove_new_subdir(char *subdir, bool rmtopdir)
{
	char		new_path[MAXPGPATH];

	prep_status("Deleting files from new %s", subdir);

	snprintf(new_path, sizeof(new_path), "%s/%s", new_cluster.pgdata, subdir);
	if (!rmtree(new_path, rmtopdir))
		pg_fatal("could not delete directory \"%s\"\n", new_path);

	check_ok();
}

/*
 * Copy the files from the old cluster into it
 */
static void
copy_subdir_files(char *subdir)
{
	char		old_path[MAXPGPATH];
	char		new_path[MAXPGPATH];

	remove_new_subdir(subdir, true);

	snprintf(old_path, sizeof(old_path), "%s/%s", old_cluster.pgdata, subdir);
	snprintf(new_path, sizeof(new_path), "%s/%s", new_cluster.pgdata, subdir);

	prep_status("Copying old %s to new server", subdir);

	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
#ifndef WIN32
			  "cp -Rf \"%s\" \"%s\"",
#else
	/* flags: everything, no confirm, quiet, overwrite read-only */
			  "xcopy /e /y /q /r \"%s\" \"%s\\\"",
#endif
			  old_path, new_path);

	check_ok();
}


static void
copy_clog_xlog_xid(void)
{
	/* copy old commit logs to new data dir */
	copy_subdir_files("pg_clog");

	prep_status("Setting oldest XID for new cluster");
	exec_prog(UTILITY_LOG_FILE, NULL, true,
			  true, "\"%s/pg_resetxlog\" --binary-upgrade -f -u %u \"%s\"",
			  new_cluster.bindir, old_cluster.controldata.chkpnt_oldstxid,
			  new_cluster.pgdata);
	check_ok();

	/* set the next transaction id and epoch of the new cluster */
	prep_status("Setting next transaction ID and epoch for new cluster");
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  "\"%s/pg_resetxlog\" --binary-upgrade -f -x %u \"%s\"",
			  new_cluster.bindir, old_cluster.controldata.chkpnt_nxtxid,
			  new_cluster.pgdata);
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  "\"%s/pg_resetxlog\" --binary-upgrade -f -e %u \"%s\"",
			  new_cluster.bindir, old_cluster.controldata.chkpnt_nxtepoch,
			  new_cluster.pgdata);
	check_ok();

	/*
	 * If the old server is before the MULTIXACT_FORMATCHANGE_CAT_VER change
	 * (see pg_upgrade.h) and the new server is after, then we don't copy
	 * pg_multixact files, but we need to reset pg_control so that the new
	 * server doesn't attempt to read multis older than the cutoff value.
	 */
	if (old_cluster.controldata.cat_ver >= MULTIXACT_FORMATCHANGE_CAT_VER &&
		new_cluster.controldata.cat_ver >= MULTIXACT_FORMATCHANGE_CAT_VER)
	{
		copy_subdir_files("pg_multixact/offsets");
		copy_subdir_files("pg_multixact/members");

		prep_status("Setting next multixact ID and offset for new cluster");

		/*
		 * we preserve all files and contents, so we must preserve both "next"
		 * counters here and the oldest multi present on system.
		 */
		exec_prog(UTILITY_LOG_FILE, NULL, true, true,
				  "\"%s/pg_resetxlog\" --binary-upgrade -O %u -m %u,%u \"%s\"",
				  new_cluster.bindir,
				  old_cluster.controldata.chkpnt_nxtmxoff,
				  old_cluster.controldata.chkpnt_nxtmulti,
				  old_cluster.controldata.chkpnt_oldstMulti,
				  new_cluster.pgdata);
		check_ok();
	}
	else if (new_cluster.controldata.cat_ver >= MULTIXACT_FORMATCHANGE_CAT_VER)
	{
		/*
		 * Remove offsets/0000 file created by initdb that no longer matches
		 * the new multi-xid value.  "members" starts at zero so no need to
		 * remove it.
		 */
		remove_new_subdir("pg_multixact/offsets", false);

		prep_status("Setting oldest multixact ID on new cluster");

		/*
		 * We don't preserve files in this case, but it's important that the
		 * oldest multi is set to the latest value used by the old system, so
		 * that multixact.c returns the empty set for multis that might be
		 * present on disk.  We set next multi to the value following that; it
		 * might end up wrapped around (i.e. 0) if the old cluster had
		 * next=MaxMultiXactId, but multixact.c can cope with that just fine.
		 */
		exec_prog(UTILITY_LOG_FILE, NULL, true, true,
				  "\"%s/pg_resetxlog\" --binary-upgrade -m %u,%u \"%s\"",
				  new_cluster.bindir,
				  old_cluster.controldata.chkpnt_nxtmulti + 1,
				  old_cluster.controldata.chkpnt_nxtmulti,
				  new_cluster.pgdata);
		check_ok();
	}

	/* now reset the wal archives in the new cluster */
	prep_status("Resetting WAL archives");
	exec_prog(UTILITY_LOG_FILE, NULL, true, true,
			  /* use timeline 1 to match controldata and no WAL history file */
			  "\"%s/pg_resetxlog\" --binary-upgrade -l 00000001%s \"%s\"", new_cluster.bindir,
			  old_cluster.controldata.nextxlogfile + 8,
			  new_cluster.pgdata);
	check_ok();
}


/*
 *	set_frozenxids()
 *
 * This is called on the new cluster before we restore anything, with
 * minmxid_only = false.  Its purpose is to ensure that all initdb-created
 * vacuumable tables have relfrozenxid/relminmxid matching the old cluster's
 * xid/mxid counters.  We also initialize the datfrozenxid/datminmxid of the
 * built-in databases to match.
 *
 * As we create user tables later, their relfrozenxid/relminmxid fields will
 * be restored properly by the binary-upgrade restore script.  Likewise for
 * user-database datfrozenxid/datminmxid.  However, if we're upgrading from a
 * pre-9.3 database, which does not store per-table or per-DB minmxid, then
 * the relminmxid/datminmxid values filled in by the restore script will just
 * be zeroes.
 *
 * GPDB: We've disabled the relfrozenxid/relminmxid preservation in the
 * binary-upgrade restore scripts in favor of doing bulk pg_class updates
 * mainly via update_db_xids().
 *
 * Hence, with a pre-9.3 source database, a second call occurs after
 * everything is restored, with minmxid_only = true.  This pass will
 * initialize all tables and databases, both those made by initdb and user
 * objects, with the desired minmxid value.  frozenxid values are left alone.
 */
static void
set_frozenxids(bool minmxid_only)
{
	int			dbnum;
	PGconn	   *conn,
			   *conn_template1;
	PGresult   *dbres;
	int			ntups;
	int			i_datname;
	int			i_datallowconn;

	if (!minmxid_only)
		prep_status("Setting frozenxid and minmxid counters in new cluster");
	else
		prep_status("Setting minmxid counter in new cluster");

	conn_template1 = connectToServer(&new_cluster, "template1");

	/*
	 * GPDB doesn't allow hacking the catalogs without setting
	 * allow_system_table_mods first.
	 */
	PQclear(executeQueryOrDie(conn_template1,
							  "set allow_system_table_mods=true"));

	if (!minmxid_only)
		/* set pg_database.datfrozenxid */
		PQclear(executeQueryOrDie(conn_template1,
								  "UPDATE pg_catalog.pg_database "
								  "SET	datfrozenxid = '%u'",
								  old_cluster.controldata.chkpnt_nxtxid));

	/* set pg_database.datminmxid */
	PQclear(executeQueryOrDie(conn_template1,
							  "UPDATE pg_catalog.pg_database "
							  "SET	datminmxid = '%u'",
							  old_cluster.controldata.chkpnt_nxtmulti));

	/* get database names */
	dbres = executeQueryOrDie(conn_template1,
							  "SELECT	datname, datallowconn "
							  "FROM	pg_catalog.pg_database");

	i_datname = PQfnumber(dbres, "datname");
	i_datallowconn = PQfnumber(dbres, "datallowconn");

	ntups = PQntuples(dbres);
	for (dbnum = 0; dbnum < ntups; dbnum++)
	{

		char	   *datname = PQgetvalue(dbres, dbnum, i_datname);
		char	   *escaped_datname = NULL;
		char	   *datallowconn = PQgetvalue(dbres, dbnum, i_datallowconn);


		/*
		 * We must update databases where datallowconn = false, e.g.
		 * template0, because autovacuum increments their datfrozenxids,
		 * relfrozenxids, and relminmxid  even if autovacuum is turned off,
		 * and even though all the data rows are already frozen  To enable
		 * this, we temporarily change datallowconn.
		 */
		if (strcmp(datallowconn, "f") == 0)
		{
			escaped_datname = pg_malloc(strlen(datname) * 2 + 1);
			PQescapeStringConn(conn_template1, escaped_datname, datname, strlen(datname), NULL);
			PQclear(executeQueryOrDie(conn_template1,
									  "UPDATE pg_catalog.pg_database "
									  "SET	datallowconn = true "
									  "WHERE datname = '%s'", escaped_datname));
		}

		conn = connectToServer(&new_cluster, datname);

		/*
		 * GPDB doesn't allow hacking the catalogs without setting
		 * allow_system_table_mods first.
		 */
		PQclear(executeQueryOrDie(conn, "set allow_system_table_mods=true"));

		if (!minmxid_only)
			/* set pg_class.relfrozenxid */
			PQclear(executeQueryOrDie(conn,
									  "UPDATE	pg_catalog.pg_class "
									  "SET	relfrozenxid = '%u' "
			/*
			 * only heap, materialized view, and TOAST are vacuumed
			 * exclude relations with external storage as well as AO and CO tables
			 *
			 * The logic here should keep consistent with function
			 * should_have_valid_relfrozenxid().
			 *
			 * Notes: if we ever backport this to Greenplum 5X, remove 'm' first
			 * and then replace 'M' with 'm', because 'm' used to be RELKIND
			 * visimap in 4.3/5X, not matview
			 */
									  "WHERE	(relkind IN ('r', 'm', 't') "
									  "AND NOT relfrozenxid = 0) "
									  "OR (relkind IN ('t', 'o', 'b', 'M'))",
									  old_cluster.controldata.chkpnt_nxtxid));

		/* set pg_class.relminmxid */
		PQclear(executeQueryOrDie(conn,
								  "UPDATE	pg_catalog.pg_class "
								  "SET	relminmxid = '%u' "
		/* only heap, materialized view, and TOAST are vacuumed */
								  "WHERE	relkind IN ('r', 'm', 't')",
								  old_cluster.controldata.chkpnt_nxtmulti));
		PQfinish(conn);

		/* Reset datallowconn flag */
		if (strcmp(datallowconn, "f") == 0)
		{
			PQclear(executeQueryOrDie(conn_template1,
									  "UPDATE pg_catalog.pg_database "
									  "SET	datallowconn = false "
									  "WHERE datname = '%s'", escaped_datname));
			pg_free(escaped_datname);
		}
	}

	PQclear(dbres);

	PQfinish(conn_template1);

	check_ok();
}

static void
cleanup(void)
{
	fclose(log_opts.internal);

	/* Remove dump and log files? */
	if (!log_opts.retain)
	{
		int			dbnum;
		char	  **filename;

		for (filename = output_files; *filename != NULL; filename++)
			unlink(*filename);

		/* remove dump files */
		unlink(GLOBALS_DUMP_FILE);

		if (old_cluster.dbarr.dbs)
			for (dbnum = 0; dbnum < old_cluster.dbarr.ndbs; dbnum++)
			{
				char		sql_file_name[MAXPGPATH],
							log_file_name[MAXPGPATH];
				DbInfo	   *old_db = &old_cluster.dbarr.dbs[dbnum];

				snprintf(sql_file_name, sizeof(sql_file_name), DB_DUMP_FILE_MASK, old_db->db_oid);
				unlink(sql_file_name);

				snprintf(log_file_name, sizeof(log_file_name), DB_DUMP_LOG_FILE_MASK, old_db->db_oid);
				unlink(log_file_name);
			}
	}
}
