/*-------------------------------------------------------------------------
 *
 * miscadmin.h
 *	  This file contains general postgres administration and initialization
 *	  stuff that used to be spread out between the following files:
 *		globals.h						global variables
 *		pdir.h							directory path crud
 *		pinit.h							postgres initialization
 *		pmod.h							processing modes
 *	  Over time, this has also become the preferred place for widely known
 *	  resource-limitation stuff, such as work_mem and check_stack_depth().
 *
 * Portions Copyright (c) 1996-2014, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/miscadmin.h
 *
 * NOTES
 *	  some of the information in this file should be moved to other files.
 *
 *-------------------------------------------------------------------------
 */
#ifndef MISCADMIN_H
#define MISCADMIN_H

#include <signal.h>

#include "pgtime.h"				/* for pg_time_t */


#define PG_VERSIONSTR "postgres (Greengage Database) " PG_VERSION "\n"
#define PG_BACKEND_VERSIONSTR "postgres (Greengage Database) " PG_VERSION "\n"

#define InvalidPid				(-1)


/*****************************************************************************
 *	  System interrupt and critical section handling
 *
 * There are two types of interrupts that a running backend needs to accept
 * without messing up its state: QueryCancel (SIGINT) and ProcDie (SIGTERM).
 * In both cases, we need to be able to clean up the current transaction
 * gracefully, so we can't respond to the interrupt instantaneously ---
 * there's no guarantee that internal data structures would be self-consistent
 * if the code is interrupted at an arbitrary instant.  Instead, the signal
 * handlers set flags that are checked periodically during execution.
 *
 * The CHECK_FOR_INTERRUPTS() macro is called at strategically located spots
 * where it is normally safe to accept a cancel or die interrupt.  In some
 * cases, we invoke CHECK_FOR_INTERRUPTS() inside low-level subroutines that
 * might sometimes be called in contexts that do *not* want to allow a cancel
 * or die interrupt.  The HOLD_INTERRUPTS() and RESUME_INTERRUPTS() macros
 * allow code to ensure that no cancel or die interrupt will be accepted,
 * even if CHECK_FOR_INTERRUPTS() gets called in a subroutine.  The interrupt
 * will be held off until CHECK_FOR_INTERRUPTS() is done outside any
 * HOLD_INTERRUPTS() ... RESUME_INTERRUPTS() section.
 *
 * There is also a mechanism to prevent query cancel interrupts, while still
 * allowing die interrupts: HOLD_CANCEL_INTERRUPTS() and
 * RESUME_CANCEL_INTERRUPTS().
 *
 * Special mechanisms are used to let an interrupt be accepted when we are
 * waiting for a lock or when we are waiting for command input (but, of
 * course, only if the interrupt holdoff counter is zero).  See the
 * related code for details.
 *
 * A lost connection is handled similarly, although the loss of connection
 * does not raise a signal, but is detected when we fail to write to the
 * socket. If there was a signal for a broken connection, we could make use of
 * it by setting ClientConnectionLost in the signal handler.
 *
 * A related, but conceptually distinct, mechanism is the "critical section"
 * mechanism.  A critical section not only holds off cancel/die interrupts,
 * but causes any ereport(ERROR) or ereport(FATAL) to become ereport(PANIC)
 * --- that is, a system-wide reset is forced.  Needless to say, only really
 * *critical* code should be marked as a critical section!	Currently, this
 * mechanism is only used for XLOG-related code.
 *
 *****************************************************************************/

/* in globals.c */
/* these are marked volatile because they are set by signal handlers: */
extern PGDLLIMPORT volatile bool InterruptPending;
extern PGDLLIMPORT volatile bool QueryCancelPending;
extern PGDLLIMPORT volatile bool QueryCancelCleanup; /* GPDB only */
extern PGDLLIMPORT volatile bool QueryFinishPending;
extern PGDLLIMPORT volatile bool ProcDiePending;
extern PGDLLIMPORT volatile sig_atomic_t ConfigReloadPending;

extern PGDLLIMPORT volatile sig_atomic_t CheckClientConnectionPending;
extern volatile bool ClientConnectionLost;

/* these are marked volatile because they are examined by signal handlers: */
extern PGDLLIMPORT volatile bool ImmediateInterruptOK;
extern PGDLLIMPORT volatile bool ImmediateDieOK;
extern PGDLLIMPORT volatile bool TermSignalReceived;
extern PGDLLIMPORT volatile int32 InterruptHoldoffCount;
extern PGDLLIMPORT volatile int32 QueryCancelHoldoffCount;
extern PGDLLIMPORT volatile int32 CritSectionCount;

/* in tcop/postgres.c */
extern void ProcessInterrupts(const char* filename, int lineno);

/* Hook get notified when QueryCancelPending or ProcDiePending is raised */
typedef void (*cancel_pending_hook_type) (void);
extern PGDLLIMPORT cancel_pending_hook_type cancel_pending_hook;

/*
 * We don't want to include the entire vmem_tracker.h, and so,
 * declare the only function we use from vmem_tracker.h.
 */
extern void RedZoneHandler_DetectRunawaySession(void);

/*
 * These should be in backoff.h, but we need the in CHECK_FOR_INTERRUPTS(),
 * and we don't want to include the entire backoff.h here.
 */
extern int backoffTickCounter;
extern int gp_resqueue_priority_local_interval;

extern void BackoffBackendTickExpired(void);

/*
 * Whether request on cancel or termination have arrived?
 */
static inline bool
CancelRequested()
{
	return InterruptPending && (ProcDiePending || QueryCancelPending);
}

static inline void
BackoffBackendTick(void)
{
	backoffTickCounter++;

	if (backoffTickCounter >= gp_resqueue_priority_local_interval)
	{
		/* Enough time has passed. Perform backoff. */
		BackoffBackendTickExpired();
	}
}

#ifndef WIN32

#define CHECK_FOR_INTERRUPTS() \
do { \
	if (InterruptPending) \
		ProcessInterrupts(__FILE__, __LINE__); \
	BackoffBackendTick(); \
	ReportOOMConsumption(); \
	RedZoneHandler_DetectRunawaySession();\
} while(0)

#else							/* WIN32 */

#define CHECK_FOR_INTERRUPTS() \
do { \
	if (UNBLOCKED_SIGNAL_QUEUE()) \
		pgwin32_dispatch_queued_signals(); \
	if (InterruptPending) \
		ProcessInterrupts(__FILE__, __LINE__); \
} while(0)
#endif   /* WIN32 */


#define HOLD_INTERRUPTS() \
do { \
	if (InterruptHoldoffCount < 0) \
		elog(PANIC, "Hold interrupt holdoff count is bad (%d)", InterruptHoldoffCount); \
	InterruptHoldoffCount++; \
} while(0)

#define RESUME_INTERRUPTS() \
do { \
	if (InterruptHoldoffCount <= 0) \
		elog(PANIC, "Resume interrupt holdoff count is bad (%d)", InterruptHoldoffCount); \
	InterruptHoldoffCount--; \
} while(0)

#define HOLD_CANCEL_INTERRUPTS() \
do{ \
    if (QueryCancelHoldoffCount < 0) \
        elog(PANIC, "Hold cancel interrupt holdoff count is bad (%d)", QueryCancelHoldoffCount); \
    QueryCancelHoldoffCount++; \
} while(0)

#define RESUME_CANCEL_INTERRUPTS() \
do { \
    if (QueryCancelHoldoffCount <= 0) \
        elog(PANIC, "Resume cancel interrupt holdoff count is bad (%d)", QueryCancelHoldoffCount); \
    QueryCancelHoldoffCount--; \
} while(0)

#define START_CRIT_SECTION() \
do { \
	if (CritSectionCount < 0) \
		elog(PANIC, "Start critical section count is bad (%d)", CritSectionCount); \
	CritSectionCount++; \
} while(0)

#define END_CRIT_SECTION() \
do { \
	if (CritSectionCount <= 0) \
		elog(PANIC, "End critical section count is bad (%d)", CritSectionCount); \
	CritSectionCount--; \
} while(0)

/* check CritSectionCount without modification */
#define ASSERT_IN_CRIT_SECTION() \
do { \
	Assert(CritSectionCount > 0); \
} while(0)

/*****************************************************************************
 *	  globals.h --															 *
 *****************************************************************************/

/*
 * from utils/init/globals.c
 */
extern pid_t PostmasterPid;
extern bool IsPostmasterEnvironment;
extern PGDLLIMPORT bool IsUnderPostmaster;
extern bool IsBackgroundWorker;
extern bool IsBinaryUpgrade;
extern bool ConvertMasterDataDirToSegment;

extern PGDLLIMPORT bool ExitOnAnyError;

extern PGDLLIMPORT char *DataDir;

extern PGDLLIMPORT int NBuffers;
extern PGDLLIMPORT int MaxBackends;
extern PGDLLIMPORT int MaxConnections;
extern PGDLLIMPORT int max_worker_processes;
extern int gp_workfile_max_entries;

extern PGDLLIMPORT int MyProcPid;
extern PGDLLIMPORT pg_time_t MyStartTime;
extern PGDLLIMPORT struct Port *MyProcPort;
extern int32 MyCancelKey;
extern int	MyPMChildSlot;

extern char OutputFileName[];
extern PGDLLIMPORT char my_exec_path[];
extern char pkglib_path[];

#ifdef EXEC_BACKEND
extern char postgres_exec_path[];
#endif

extern PGDLLIMPORT int gpperfmon_port; 

/* for pljava */
extern PGDLLIMPORT char* pljava_vmoptions;
extern PGDLLIMPORT char* pljava_classpath;
extern PGDLLIMPORT int   pljava_statement_cache_size;
extern PGDLLIMPORT bool  pljava_debug;
extern PGDLLIMPORT bool  pljava_release_lingering_savepoints;
extern PGDLLIMPORT bool  pljava_classpath_insecure;

/*
 * done in storage/backendid.h for now.
 *
 * extern BackendId    MyBackendId;
 */
extern PGDLLIMPORT Oid MyDatabaseId;

extern PGDLLIMPORT Oid MyDatabaseTableSpace;

/*
 * Date/Time Configuration
 *
 * DateStyle defines the output formatting choice for date/time types:
 *	USE_POSTGRES_DATES specifies traditional Postgres format
 *	USE_ISO_DATES specifies ISO-compliant format
 *	USE_SQL_DATES specifies Oracle/Ingres-compliant format
 *	USE_GERMAN_DATES specifies German-style dd.mm/yyyy
 *
 * DateOrder defines the field order to be assumed when reading an
 * ambiguous date (anything not in YYYY-MM-DD format, with a four-digit
 * year field first, is taken to be ambiguous):
 *	DATEORDER_YMD specifies field order yy-mm-dd
 *	DATEORDER_DMY specifies field order dd-mm-yy ("European" convention)
 *	DATEORDER_MDY specifies field order mm-dd-yy ("US" convention)
 *
 * In the Postgres and SQL DateStyles, DateOrder also selects output field
 * order: day comes before month in DMY style, else month comes before day.
 *
 * The user-visible "DateStyle" run-time parameter subsumes both of these.
 */

/* valid DateStyle values */
#define USE_POSTGRES_DATES		0
#define USE_ISO_DATES			1
#define USE_SQL_DATES			2
#define USE_GERMAN_DATES		3
#define USE_XSD_DATES			4

/* valid DateOrder values */
#define DATEORDER_YMD			0
#define DATEORDER_DMY			1
#define DATEORDER_MDY			2

extern PGDLLIMPORT int DateStyle;
extern PGDLLIMPORT int DateOrder;

/*
 * IntervalStyles
 *	 INTSTYLE_POSTGRES			   Like Postgres < 8.4 when DateStyle = 'iso'
 *	 INTSTYLE_POSTGRES_VERBOSE	   Like Postgres < 8.4 when DateStyle != 'iso'
 *	 INTSTYLE_SQL_STANDARD		   SQL standard interval literals
 *	 INTSTYLE_ISO_8601			   ISO-8601-basic formatted intervals
 */
#define INTSTYLE_POSTGRES			0
#define INTSTYLE_POSTGRES_VERBOSE	1
#define INTSTYLE_SQL_STANDARD		2
#define INTSTYLE_ISO_8601			3

extern PGDLLIMPORT int IntervalStyle;

#define MAXTZLEN		10		/* max TZ name len, not counting tr. null */

extern bool enableFsync;
extern PGDLLIMPORT bool allowSystemTableMods;
extern PGDLLIMPORT int planner_work_mem;
extern PGDLLIMPORT int work_mem;
extern PGDLLIMPORT int maintenance_work_mem;
extern PGDLLIMPORT int statement_mem;
extern PGDLLIMPORT int max_statement_mem;
extern PGDLLIMPORT int gp_vmem_limit_per_query;

extern int	VacuumCostPageHit;
extern int	VacuumCostPageMiss;
extern int	VacuumCostPageDirty;
extern int	VacuumCostLimit;
extern int	VacuumCostDelay;

extern int	VacuumPageHit;
extern int	VacuumPageMiss;
extern int	VacuumPageDirty;

extern int	VacuumCostBalance;
extern bool VacuumCostActive;

extern int gp_vmem_protect_limit;
extern int gp_vmem_protect_gang_cache_limit;
extern int gp_max_parallel_cursors;

/* in tcop/postgres.c */

#if defined(__ia64__) || defined(__ia64)
typedef struct
{
	char	   *stack_base_ptr;
	char	   *register_stack_base_ptr;
} pg_stack_base_t;
#else
typedef char *pg_stack_base_t;
#endif

extern pg_stack_base_t set_stack_base(void);
extern void restore_stack_base(pg_stack_base_t base);
extern void check_stack_depth(void);
extern bool stack_is_too_deep(void);

extern void PostgresSigHupHandler(SIGNAL_ARGS);

/* in tcop/utility.c */
extern void PreventCommandIfReadOnly(const char *cmdname);
extern void PreventCommandDuringRecovery(const char *cmdname);

/* in utils/misc/guc.c */
extern int	trace_recovery_messages;
extern int	trace_recovery(int trace_level);

/*
 * database which is used by dtx recovery, gdd, fts, etc for catalog access.
 * We are not using template1 since it seems that users would like to recreate
 * the template1 database for customization sometimes. That means template1
 * could be dropped and then recreated and thus that will break dtx recovery,
 * gdd, fts, etc. Also template1 is the default template for the 'create
 * database' command. Using template1 will make that command fail: "ERROR:
 * source database "template1" is being accessed by other users" "DETAIL:
 * There are 2 other sessions using the database."
 */
#define DB_FOR_COMMON_ACCESS	"postgres"

/*****************************************************************************
 *	  pdir.h --																 *
 *			POSTGRES directory path definitions.                             *
 *****************************************************************************/

/* flags to be OR'd to form sec_context */
#define SECURITY_LOCAL_USERID_CHANGE	0x0001
#define SECURITY_RESTRICTED_OPERATION	0x0002

extern char *DatabasePath;

/* now in utils/init/miscinit.c */
extern void SetDatabasePath(const char *path);

extern char *GetUserNameFromId(Oid roleid);
extern Oid	GetUserId(void);
extern Oid	GetOuterUserId(void);
extern Oid	GetSessionUserId(void);
extern void 	SetSessionUserId(Oid, bool);
extern Oid	GetAuthenticatedUserId(void);
extern bool IsAuthenticatedUserSuperUser(void);
extern void GetUserIdAndSecContext(Oid *userid, int *sec_context);
extern void SetUserIdAndSecContext(Oid userid, int sec_context);
extern bool InLocalUserIdChange(void);
extern bool InSecurityRestrictedOperation(void);
extern void GetUserIdAndContext(Oid *userid, bool *sec_def_context);
extern void SetUserIdAndContext(Oid userid, bool sec_def_context);
extern void InitializeSessionUserId(const char *rolename);
extern void InitializeSessionUserIdStandalone(void);
extern void SetSessionAuthorization(Oid userid, bool is_superuser);
extern Oid	GetCurrentRoleId(void);
extern void SetCurrentRoleId(Oid roleid, bool is_superuser);

extern void SetDataDir(const char *dir);
extern void ChangeToDataDir(void);

/* in utils/misc/superuser.c */
extern bool superuser(void);	/* current user is superuser */
extern bool procRoleIsSuperuser(void); /* proc role id is superuser */
extern bool superuser_arg(Oid roleid);	/* given user is superuser */


/*****************************************************************************
 *	  pmod.h --																 *
 *			POSTGRES processing mode definitions.                            *
 *****************************************************************************/

/*
 * Description:
 *		There are three processing modes in POSTGRES.  They are
 * BootstrapProcessing or "bootstrap," InitProcessing or
 * "initialization," and NormalProcessing or "normal."
 *
 * The first two processing modes are used during special times. When the
 * system state indicates bootstrap processing, transactions are all given
 * transaction id "one" and are consequently guaranteed to commit. This mode
 * is used during the initial generation of template databases.
 *
 * Initialization mode: used while starting a backend, until all normal
 * initialization is complete.  Some code behaves differently when executed
 * in this mode to enable system bootstrapping.
 *
 * If a POSTGRES backend process is in normal mode, then all code may be
 * executed normally.
 */

typedef enum ProcessingMode
{
	BootstrapProcessing,		/* bootstrap creation of template database */
	InitProcessing,				/* initializing system */
	NormalProcessing			/* normal processing */
} ProcessingMode;

extern ProcessingMode Mode;

#define IsBootstrapProcessingMode() (Mode == BootstrapProcessing)
#define IsInitProcessingMode()		(Mode == InitProcessing)
#define IsNormalProcessingMode()	(Mode == NormalProcessing)

#define GetProcessingMode() Mode

#define SetProcessingMode(mode) \
	do { \
		AssertArg((mode) == BootstrapProcessing || \
				  (mode) == InitProcessing || \
				  (mode) == NormalProcessing); \
		Mode = (mode); \
	} while(0)


/*
 * Auxiliary-process type identifiers.  These used to be in bootstrap.h
 * but it seems saner to have them here, with the ProcessingMode stuff.
 * The MyAuxProcType global is defined and set in bootstrap.c.
 */

typedef enum
{
	NotAnAuxProcess = -1,
	CheckerProcess = 0,
	BootstrapProcess,
	StartupProcess,
	BgWriterProcess,
	CheckpointerProcess,
	WalWriterProcess,
	WalReceiverProcess,

	NUM_AUXPROCTYPES			/* Must be last! */
} AuxProcType;

extern AuxProcType MyAuxProcType;

#define AmBootstrapProcess()		(MyAuxProcType == BootstrapProcess)
#define AmStartupProcess()			(MyAuxProcType == StartupProcess)
#define AmBackgroundWriterProcess() (MyAuxProcType == BgWriterProcess)
#define AmCheckpointerProcess()		(MyAuxProcType == CheckpointerProcess)
#define AmWalWriterProcess()		(MyAuxProcType == WalWriterProcess)
#define AmWalReceiverProcess()		(MyAuxProcType == WalReceiverProcess)


/*****************************************************************************
 *	  pinit.h --															 *
 *			POSTGRES initialization and cleanup definitions.                 *
 *****************************************************************************/

/* in utils/init/postinit.c */
extern bool FindMyDatabase(const char *dbname, Oid *db_id, Oid *db_tablespace);
extern void pg_split_opts(char **argv, int *argcp, char *optstr);
extern void InitializeMaxBackends(void);
extern void InitPostgres(const char *in_dbname, Oid dboid, const char *username,
			 char *out_dbname);
extern void BaseInit(void);

/* in utils/init/miscinit.c */
extern bool IgnoreSystemIndexes;
extern PGDLLIMPORT bool process_shared_preload_libraries_in_progress;
extern char *session_preload_libraries_string;
extern char *shared_preload_libraries_string;
extern char *local_preload_libraries_string;

/*
 * As of 9.1, the contents of the data-directory lock file are:
 *
 * line #
 *		1	postmaster PID (or negative of a standalone backend's PID)
 *		2	data directory path
 *		3	postmaster start timestamp (time_t representation)
 *		4	port number
 *		5	first Unix socket directory path (empty if none)
 *		6	first listen_address (IP address or "*"; empty if no TCP port)
 *		7	shared memory key (not present on Windows)
 *
 * Lines 6 and up are added via AddToDataDirLockFile() after initial file
 * creation.
 *
 * The socket lock file, if used, has the same contents as lines 1-5.
 */
#define LOCK_FILE_LINE_PID			1
#define LOCK_FILE_LINE_DATA_DIR		2
#define LOCK_FILE_LINE_START_TIME	3
#define LOCK_FILE_LINE_PORT			4
#define LOCK_FILE_LINE_SOCKET_DIR	5
#define LOCK_FILE_LINE_LISTEN_ADDR	6
#define LOCK_FILE_LINE_SHMEM_KEY	7

extern void CreateDataDirLockFile(bool amPostmaster);
extern void CreateSocketLockFile(const char *socketfile, bool amPostmaster,
					 const char *socketDir);
extern void TouchSocketLockFiles(void);
extern void AddToDataDirLockFile(int target_line, const char *str);
extern bool RecheckDataDirLockFile(void);
extern void ValidatePgVersion(const char *path);
extern void process_shared_preload_libraries(void);
extern void process_session_preload_libraries(void);
extern void pg_bindtextdomain(const char *domain);
extern bool has_rolreplication(Oid roleid);

/* in access/transam/xlog.c */
extern bool BackupInProgress(void);
extern void CancelBackup(void);

#endif   /* MISCADMIN_H */
