/*-------------------------------------------------------------------------
 *
 *	common.c
 *		Common support routines for bin/scripts/
 *
 *
 * Portions Copyright (c) 1996-2014, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/bin/scripts/common.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres_fe.h"

#include <signal.h>
#include <unistd.h>

#include "common.h"
#include "dumputils.h"
#include "fe_utils/connect.h"

static void SetCancelConn(PGconn *conn);
static void ResetCancelConn(void);

static PGcancel *volatile cancelConn = NULL;

#ifdef WIN32
static CRITICAL_SECTION cancelConnLock;
#endif

/*
 * Provide strictly harmonized handling of --help and --version
 * options.
 */
void
handle_help_version_opts(int argc, char *argv[],
						 const char *fixed_progname, help_handler hlp)
{
	if (argc > 1)
	{
		if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-?") == 0)
		{
			hlp(get_progname(argv[0]));
			exit(0);
		}
		if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-V") == 0)
		{
			printf("%s (Greengage Database) " PG_VERSION "\n", fixed_progname);
			exit(0);
		}
	}
}


/*
 * Make a database connection with the given parameters.  An
 * interactive password prompt is automatically issued if required.
 */
PGconn *
connectDatabase(const char *dbname, const char *pghost,
				const char *pgport, const char *pguser,
				enum trivalue prompt_password, const char *progname,
				bool echo, bool fail_ok)
{
	PGconn	   *conn;
	char	   *password = NULL;
	bool		new_pass;

	if (prompt_password == TRI_YES)
		password = simple_prompt("Password: ", 100, false);

	/*
	 * Start the connection.  Loop until we have a password if requested by
	 * backend.
	 */
	do
	{
#define PARAMS_ARRAY_SIZE	7
		const char **keywords = pg_malloc(PARAMS_ARRAY_SIZE * sizeof(*keywords));
		const char **values = pg_malloc(PARAMS_ARRAY_SIZE * sizeof(*values));

		keywords[0] = "host";
		values[0] = pghost;
		keywords[1] = "port";
		values[1] = pgport;
		keywords[2] = "user";
		values[2] = pguser;
		keywords[3] = "password";
		values[3] = password;
		keywords[4] = "dbname";
		values[4] = dbname;
		keywords[5] = "fallback_application_name";
		values[5] = progname;
		keywords[6] = NULL;
		values[6] = NULL;

		new_pass = false;
		conn = PQconnectdbParams(keywords, values, true);

		free(keywords);
		free(values);

		if (!conn)
		{
			fprintf(stderr, _("%s: could not connect to database %s\n"),
					progname, dbname);
			exit(1);
		}

		if (PQstatus(conn) == CONNECTION_BAD &&
			PQconnectionNeedsPassword(conn) &&
			password == NULL &&
			prompt_password != TRI_NO)
		{
			PQfinish(conn);
			password = simple_prompt("Password: ", 100, false);
			new_pass = true;
		}
	} while (new_pass);

	if (password)
		free(password);

	/* check to see that the backend connection was successfully made */
	if (PQstatus(conn) == CONNECTION_BAD)
	{
		if (fail_ok)
		{
			PQfinish(conn);
			return NULL;
		}
		fprintf(stderr, _("%s: could not connect to database %s: %s"),
				progname, dbname, PQerrorMessage(conn));
		exit(1);
	}

	PQclear(executeQuery(conn, ALWAYS_SECURE_SEARCH_PATH_SQL,
						 progname, echo));

	return conn;
}

/*
 * Try to connect to the appropriate maintenance database.
 */
PGconn *
connectMaintenanceDatabase(const char *maintenance_db,
						   const char *pghost, const char *pgport,
						   const char *pguser, enum trivalue prompt_password,
						   const char *progname, bool echo)
{
	PGconn	   *conn;

	/* If a maintenance database name was specified, just connect to it. */
	if (maintenance_db)
		return connectDatabase(maintenance_db, pghost, pgport, pguser,
							   prompt_password, progname, echo, false);

	/* Otherwise, try postgres first and then template1. */
	conn = connectDatabase("postgres", pghost, pgport, pguser, prompt_password,
						   progname, echo, true);
	if (!conn)
		conn = connectDatabase("template1", pghost, pgport, pguser,
							   prompt_password, progname, echo, false);

	return conn;
}

/*
 * Run a query, return the results, exit program on failure.
 */
PGresult *
executeQuery(PGconn *conn, const char *query, const char *progname, bool echo)
{
	PGresult   *res;

	if (echo)
		printf("%s\n", query);

	res = PQexec(conn, query);
	if (!res ||
		PQresultStatus(res) != PGRES_TUPLES_OK)
	{
		fprintf(stderr, _("%s: query failed: %s"),
				progname, PQerrorMessage(conn));
		fprintf(stderr, _("%s: query was: %s\n"),
				progname, query);
		PQfinish(conn);
		exit(1);
	}

	return res;
}


/*
 * As above for a SQL command (which returns nothing).
 */
void
executeCommand(PGconn *conn, const char *query,
			   const char *progname, bool echo)
{
	PGresult   *res;

	if (echo)
		printf("%s\n", query);

	res = PQexec(conn, query);
	if (!res ||
		PQresultStatus(res) != PGRES_COMMAND_OK)
	{
		fprintf(stderr, _("%s: query failed: %s"),
				progname, PQerrorMessage(conn));
		fprintf(stderr, _("%s: query was: %s\n"),
				progname, query);
		PQfinish(conn);
		exit(1);
	}

	PQclear(res);
}


/*
 * As above for a SQL maintenance command (returns command success).
 * Command is executed with a cancel handler set, so Ctrl-C can
 * interrupt it.
 */
bool
executeMaintenanceCommand(PGconn *conn, const char *query, bool echo)
{
	PGresult   *res;
	bool		r;

	if (echo)
		printf("%s\n", query);

	SetCancelConn(conn);
	res = PQexec(conn, query);
	ResetCancelConn();

	r = (res && PQresultStatus(res) == PGRES_COMMAND_OK);

	if (res)
		PQclear(res);

	return r;
}


/*
 * Split TABLE[(COLUMNS)] into TABLE and [(COLUMNS)] portions.  When you
 * finish using them, pg_free(*table).  *columns is a pointer into "spec",
 * possibly to its NUL terminator.
 */
static void
split_table_columns_spec(const char *spec, int encoding,
						 char **table, const char **columns)
{
	bool		inquotes = false;
	const char *cp = spec;

	/*
	 * Find the first '(' not identifier-quoted.  Based on
	 * dequote_downcase_identifier().
	 */
	while (*cp && (*cp != '(' || inquotes))
	{
		if (*cp == '"')
		{
			if (inquotes && cp[1] == '"')
				cp++;			/* pair does not affect quoting */
			else
				inquotes = !inquotes;
			cp++;
		}
		else
			cp += PQmblen(cp, encoding);
	}
	*table = pg_strdup(spec);
	(*table)[cp - spec] = '\0'; /* no strndup */
	*columns = cp;
}

/*
 * Break apart TABLE[(COLUMNS)] of "spec".  With the reset_val of search_path
 * in effect, have regclassin() interpret the TABLE portion.  Append to "buf"
 * the qualified name of TABLE, followed by any (COLUMNS).  Exit on failure.
 * We use this to interpret --table=foo under the search path psql would get,
 * in advance of "ANALYZE public.foo" under the always-secure search path.
 */
void
appendQualifiedRelation(PQExpBuffer buf, const char *spec,
						PGconn *conn, const char *progname, bool echo)
{
	char	   *table;
	const char *columns;
	PQExpBufferData sql;
	PGresult   *res;
	int			ntups;

	split_table_columns_spec(spec, PQclientEncoding(conn), &table, &columns);

	/*
	 * Query must remain ABSOLUTELY devoid of unqualified names.  This would
	 * be unnecessary given a regclassin() variant taking a search_path
	 * argument.
	 */
	initPQExpBuffer(&sql);
	appendPQExpBufferStr(&sql,
						 "SELECT c.relname, ns.nspname\n"
						 " FROM pg_catalog.pg_class c,"
						 " pg_catalog.pg_namespace ns\n"
						 " WHERE c.relnamespace OPERATOR(pg_catalog.=) ns.oid\n"
						 "  AND c.oid OPERATOR(pg_catalog.=) ");
	appendStringLiteralConn(&sql, table, conn);
	appendPQExpBufferStr(&sql, "::pg_catalog.regclass;");

	executeCommand(conn, "RESET search_path", progname, echo);

	/*
	 * One row is a typical result, as is a nonexistent relation ERROR.
	 * regclassin() unconditionally accepts all-digits input as an OID; if no
	 * relation has that OID; this query returns no rows.  Catalog corruption
	 * might elicit other row counts.
	 */
	res = executeQuery(conn, sql.data, progname, echo);
	ntups = PQntuples(res);
	if (ntups != 1)
	{
		fprintf(stderr,
				ngettext("%s: query returned %d row instead of one: %s\n",
						 "%s: query returned %d rows instead of one: %s\n",
						 ntups),
				progname, ntups, sql.data);
		PQfinish(conn);
		exit(1);
	}
	appendPQExpBufferStr(buf,
						 fmtQualifiedId(PQserverVersion(conn),
										PQgetvalue(res, 0, 1),
										PQgetvalue(res, 0, 0)));
	appendPQExpBufferStr(buf, columns);
	PQclear(res);
	termPQExpBuffer(&sql);
	pg_free(table);

	PQclear(executeQuery(conn, ALWAYS_SECURE_SEARCH_PATH_SQL,
						 progname, echo));
}


/*
 * Check yes/no answer in a localized way.  1=yes, 0=no, -1=neither.
 */

/* translator: abbreviation for "yes" */
#define PG_YESLETTER gettext_noop("y")
/* translator: abbreviation for "no" */
#define PG_NOLETTER gettext_noop("n")

bool
yesno_prompt(const char *question)
{
	char		prompt[256];

	/*------
	   translator: This is a question followed by the translated options for
	   "yes" and "no". */
	snprintf(prompt, sizeof(prompt), _("%s (%s/%s) "),
			 _(question), _(PG_YESLETTER), _(PG_NOLETTER));

	for (;;)
	{
		char	   *resp;

		resp = simple_prompt(prompt, 1, true);

		if (strcmp(resp, _(PG_YESLETTER)) == 0)
		{
			free(resp);
			return true;
		}
		else if (strcmp(resp, _(PG_NOLETTER)) == 0)
		{
			free(resp);
			return false;
		}

		free(resp);
		printf(_("Please answer \"%s\" or \"%s\".\n"),
			   _(PG_YESLETTER), _(PG_NOLETTER));
	}
}

/*
 * SetCancelConn
 *
 * Set cancelConn to point to the current database connection.
 */
static void
SetCancelConn(PGconn *conn)
{
	PGcancel   *oldCancelConn;

#ifdef WIN32
	EnterCriticalSection(&cancelConnLock);
#endif

	/* Free the old one if we have one */
	oldCancelConn = cancelConn;

	/* be sure handle_sigint doesn't use pointer while freeing */
	cancelConn = NULL;

	if (oldCancelConn != NULL)
		PQfreeCancel(oldCancelConn);

	cancelConn = PQgetCancel(conn);

#ifdef WIN32
	LeaveCriticalSection(&cancelConnLock);
#endif
}

/*
 * ResetCancelConn
 *
 * Free the current cancel connection, if any, and set to NULL.
 */
static void
ResetCancelConn(void)
{
	PGcancel   *oldCancelConn;

#ifdef WIN32
	EnterCriticalSection(&cancelConnLock);
#endif

	oldCancelConn = cancelConn;

	/* be sure handle_sigint doesn't use pointer while freeing */
	cancelConn = NULL;

	if (oldCancelConn != NULL)
		PQfreeCancel(oldCancelConn);

#ifdef WIN32
	LeaveCriticalSection(&cancelConnLock);
#endif
}

#ifndef WIN32
/*
 * Handle interrupt signals by canceling the current command,
 * if it's being executed through executeMaintenanceCommand(),
 * and thus has a cancelConn set.
 */
static void
handle_sigint(SIGNAL_ARGS)
{
	int			save_errno = errno;
	char		errbuf[256];

	/* Send QueryCancel if we are processing a database query */
	if (cancelConn != NULL)
	{
		if (PQcancel(cancelConn, errbuf, sizeof(errbuf)))
			fprintf(stderr, _("Cancel request sent\n"));
		else
			fprintf(stderr, _("Could not send cancel request: %s"), errbuf);
	}

	errno = save_errno;			/* just in case the write changed it */
}

void
setup_cancel_handler(void)
{
	pqsignal(SIGINT, handle_sigint);
}
#else							/* WIN32 */

/*
 * Console control handler for Win32. Note that the control handler will
 * execute on a *different thread* than the main one, so we need to do
 * proper locking around those structures.
 */
static BOOL WINAPI
consoleHandler(DWORD dwCtrlType)
{
	char		errbuf[256];

	if (dwCtrlType == CTRL_C_EVENT ||
		dwCtrlType == CTRL_BREAK_EVENT)
	{
		/* Send QueryCancel if we are processing a database query */
		EnterCriticalSection(&cancelConnLock);
		if (cancelConn != NULL)
		{
			if (PQcancel(cancelConn, errbuf, sizeof(errbuf)))
				fprintf(stderr, _("Cancel request sent\n"));
			else
				fprintf(stderr, _("Could not send cancel request: %s"), errbuf);
		}
		LeaveCriticalSection(&cancelConnLock);

		return TRUE;
	}
	else
		/* Return FALSE for any signals not being handled */
		return FALSE;
}

void
setup_cancel_handler(void)
{
	InitializeCriticalSection(&cancelConnLock);

	SetConsoleCtrlHandler(consoleHandler, TRUE);
}

#endif   /* WIN32 */
