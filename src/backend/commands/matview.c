/*-------------------------------------------------------------------------
 *
 * matview.c
 *	  materialized view support
 *
 * Portions Copyright (c) 1996-2014, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/commands/matview.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/appendonlywriter.h"
#include "access/htup_details.h"
#include "access/multixact.h"
#include "access/xact.h"
#include "catalog/catalog.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/oid_dispatch.h"
#include "catalog/pg_am.h"
#include "catalog/pg_opclass.h"
#include "catalog/pg_operator.h"
#include "cdb/cdbaocsam.h"
#include "cdb/cdbappendonlyam.h"
#include "cdb/cdbvars.h"
#include "commands/cluster.h"
#include "commands/matview.h"
#include "commands/tablecmds.h"
#include "commands/tablespace.h"
#include "commands/queue.h"
#include "executor/executor.h"
#include "executor/spi.h"
#include "miscadmin.h"
#include "parser/parse_relation.h"
#include "rewrite/rewriteHandler.h"
#include "storage/lmgr.h"
#include "storage/smgr.h"
#include "tcop/tcopprot.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/resscheduler.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"


typedef struct
{
	DestReceiver pub;			/* publicly-known function pointers */
	Oid			transientoid;	/* OID of new heap into which to store */
	Oid			oldreloid;
	bool		concurrent;
	bool		skipData;
	/* These fields are filled by transientrel_startup: */
	Relation	transientrel;	/* relation to write to */
	CommandId	output_cid;		/* cmin to insert in output tuples */
	int			hi_options;		/* heap_insert performance options */
	BulkInsertState bistate;	/* bulk insert state */

	struct AppendOnlyInsertDescData *ao_insertDesc; /* descriptor to AO tables */
	struct AOCSInsertDescData *aocs_insertDes;      /* descriptor for aocs */
} DR_transientrel;

static int	matview_maintenance_depth = 0;

static RefreshClause* MakeRefreshClause(bool concurrent, bool skipData, RangeVar *relation);
static void transientrel_startup(DestReceiver *self, int operation, TupleDesc typeinfo);
static void transientrel_receive(TupleTableSlot *slot, DestReceiver *self);
static void transientrel_shutdown(DestReceiver *self);
static void transientrel_destroy(DestReceiver *self);
static void refresh_matview_datafill(DestReceiver *dest, Query *query,
						 const char *queryString,RefreshClause *refreshClause);
static char *make_temptable_name_n(char *tempname, int n);
static void refresh_by_match_merge(Oid matviewOid, Oid tempOid, Oid relowner,
						 int save_sec_context);
static void refresh_by_heap_swap(Oid matviewOid, Oid OIDNewHeap);
static bool is_usable_unique_index(Relation indexRel);
static void OpenMatViewIncrementalMaintenance(void);
static void CloseMatViewIncrementalMaintenance(void);

/*
 * SetMatViewPopulatedState
 *		Mark a materialized view as populated, or not.
 *
 * NOTE: caller must be holding an appropriate lock on the relation.
 */
void
SetMatViewPopulatedState(Relation relation, bool newstate)
{
	Relation	pgrel;
	HeapTuple	tuple;

	Assert(relation->rd_rel->relkind == RELKIND_MATVIEW);

	/*
	 * Update relation's pg_class entry.  Crucial side-effect: other backends
	 * (and this one too!) are sent SI message to make them rebuild relcache
	 * entries.
	 */
	pgrel = heap_open(RelationRelationId, RowExclusiveLock);
	tuple = SearchSysCacheCopy1(RELOID,
								ObjectIdGetDatum(RelationGetRelid(relation)));
	if (!HeapTupleIsValid(tuple))
		elog(ERROR, "cache lookup failed for relation %u",
			 RelationGetRelid(relation));

	((Form_pg_class) GETSTRUCT(tuple))->relispopulated = newstate;

	CatalogTupleUpdate(pgrel, &tuple->t_self, tuple);

	heap_freetuple(tuple);
	heap_close(pgrel, RowExclusiveLock);

	/*
	 * Advance command counter to make the updated pg_class row locally
	 * visible.
	 */
	CommandCounterIncrement();
}

static RefreshClause*
MakeRefreshClause(bool concurrent, bool skipData, RangeVar *relation)
{
	RefreshClause *refreshClause;
	refreshClause = makeNode(RefreshClause);

	refreshClause->concurrent = concurrent;
	refreshClause->skipData = skipData;
	refreshClause->relation = relation;

	return refreshClause;
}

/*
 * ExecRefreshMatView -- execute a REFRESH MATERIALIZED VIEW command
 *
 * This refreshes the materialized view by creating a new table and swapping
 * the relfilenodes of the new table and the old materialized view, so the OID
 * of the original materialized view is preserved. Thus we do not lose GRANT
 * nor references to this materialized view.
 *
 * If WITH NO DATA was specified, this is effectively like a TRUNCATE;
 * otherwise it is like a TRUNCATE followed by an INSERT using the SELECT
 * statement associated with the materialized view.  The statement node's
 * skipData field shows whether the clause was used.
 *
 * Indexes are rebuilt too, via REINDEX. Since we are effectively bulk-loading
 * the new heap, it's better to create the indexes afterwards than to fill them
 * incrementally while we load.
 *
 * The matview's "populated" state is changed based on whether the contents
 * reflect the result set of the materialized view's query.
 */
void
ExecRefreshMatView(RefreshMatViewStmt *stmt, const char *queryString,
				   ParamListInfo params, char *completionTag)
{
	Oid			matviewOid;
	Relation	matviewRel;
	RewriteRule *rule;
	List	   *actions;
	Query	   *dataQuery;
	Oid			tableSpace;
	Oid			relowner;
	Oid			OIDNewHeap;
	DestReceiver *dest;
	bool		concurrent;
	LOCKMODE	lockmode;
	Oid			save_userid;
	int			save_sec_context;
	int			save_nestlevel;
	bool 		createAoBlockDirectory;
	RefreshClause *refreshClause;

	/* MATERIALIZED_VIEW_FIXME: Refresh MatView is not MPP-fied. */

	/* Determine strength of lock needed. */
	concurrent = stmt->concurrent;
	lockmode = concurrent ? ExclusiveLock : AccessExclusiveLock;

	/*
	 * Get a lock until end of transaction.
	 */
	matviewOid = RangeVarGetRelidExtended(stmt->relation,
										  lockmode, false, false,
										  RangeVarCallbackOwnsTable, NULL);
	matviewRel = heap_open(matviewOid, NoLock);
	relowner = matviewRel->rd_rel->relowner;

	/*
	 * Switch to the owner's userid, so that any functions are run as that
	 * user.  Also lock down security-restricted operations and arrange to
	 * make GUC variable changes local to this command.
	 */
	GetUserIdAndSecContext(&save_userid, &save_sec_context);
	SetUserIdAndSecContext(relowner,
						   save_sec_context | SECURITY_RESTRICTED_OPERATION);
	save_nestlevel = NewGUCNestLevel();

	/* Make sure it is a materialized view. */
	if (matviewRel->rd_rel->relkind != RELKIND_MATVIEW)
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("\"%s\" is not a materialized view",
						RelationGetRelationName(matviewRel))));

	/* Check that CONCURRENTLY is not specified if not populated. */
	if (concurrent && !RelationIsPopulated(matviewRel))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("CONCURRENTLY cannot be used when the materialized view is not populated")));

	/* Check that conflicting options have not been specified. */
	if (concurrent && stmt->skipData)
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
				 errmsg("CONCURRENTLY and WITH NO DATA options cannot be used together")));

	/* We don't allow an oid column for a materialized view. */
	Assert(!matviewRel->rd_rel->relhasoids);

	/*
	 * Check that everything is correct for a refresh. Problems at this point
	 * are internal errors, so elog is sufficient.
	 */
	if (matviewRel->rd_rel->relhasrules == false ||
		matviewRel->rd_rules->numLocks < 1)
		elog(ERROR,
			 "materialized view \"%s\" is missing rewrite information",
			 RelationGetRelationName(matviewRel));

	if (matviewRel->rd_rules->numLocks > 1)
		elog(ERROR,
			 "materialized view \"%s\" has too many rules",
			 RelationGetRelationName(matviewRel));

	rule = matviewRel->rd_rules->rules[0];
	if (rule->event != CMD_SELECT || !(rule->isInstead))
		elog(ERROR,
			 "the rule for materialized view \"%s\" is not a SELECT INSTEAD OF rule",
			 RelationGetRelationName(matviewRel));

	actions = rule->actions;
	if (list_length(actions) != 1)
		elog(ERROR,
			 "the rule for materialized view \"%s\" is not a single action",
			 RelationGetRelationName(matviewRel));

	/*
	 * Check that there is a unique index with no WHERE clause on
	 * one or more columns of the materialized view if CONCURRENTLY
	 * is specified.
	 */
	if (concurrent)
	{
		List		*indexoidlist = RelationGetIndexList(matviewRel);
		ListCell 	*indexoidscan;
		bool		hasUniqueIndex = false;

		foreach(indexoidscan, indexoidlist)
		{
			Oid			indexoid = lfirst_oid(indexoidscan);
			Relation	indexRel;
			Form_pg_index	indexStruct;

			indexRel = index_open(indexoid, AccessShareLock);
			indexStruct = indexRel->rd_index;

			if (indexStruct->indisunique &&
				IndexIsValid(indexStruct) &&
				RelationGetIndexExpressions(indexRel) == NIL &&
				RelationGetIndexPredicate(indexRel) == NIL &&
				indexStruct->indnatts > 0)
			{
				hasUniqueIndex = true;
				index_close(indexRel, AccessShareLock);
				break;
			}

			index_close(indexRel, AccessShareLock);
		}

		list_free(indexoidlist);

		if (!hasUniqueIndex)
			ereport(ERROR,
					(errcode(ERRCODE_OBJECT_NOT_IN_PREREQUISITE_STATE),
					 errmsg("cannot refresh materialized view \"%s\" concurrently",
							quote_qualified_identifier(get_namespace_name(RelationGetNamespace(matviewRel)),
													   RelationGetRelationName(matviewRel))),
					 errhint("Create a unique index with no WHERE clause on one or more columns of the materialized view.")));
	}

	/*
	 * Check for active uses of the relation in the current transaction, such
	 * as open scans.
	 *
	 * NB: We count on this to protect us against problems with refreshing the
	 * data using HEAP_INSERT_FROZEN.
	 */
	CheckTableNotInUse(matviewRel, "REFRESH MATERIALIZED VIEW");

	/*
	 * Tentatively mark the matview as populated or not (this will roll back
	 * if we fail later).
	 */
	SetMatViewPopulatedState(matviewRel, !stmt->skipData);

	/*
	 * The stored query was rewritten at the time of the MV definition, but
	 * has not been scribbled on by the planner.
	 *
	 * GPDB: using original query directly may cause dangling pointers if
	 * shared-inval-queue is overflow, which will cause rebuild the matview
	 * relation. when rebuilding matview relation(relcache), it is found
	 * that oldRel->rule(parentStmtType = PARENTSTMTTYPE_REFRESH_MATVIEW)
	 * is not equal to newRel->rule(parentStmtType = PARENTSTMTTYPE_NONE),
	 * caused oldRel->rule(dataQuery) to be released
	 */
	dataQuery = copyObject((Query *) linitial(actions));
	Assert(IsA(dataQuery, Query));

	dataQuery->parentStmtType = PARENTSTMTTYPE_REFRESH_MATVIEW;

	/* Concurrent refresh builds new data in temp tablespace, and does diff. */
	if (concurrent)
		tableSpace = GetDefaultTablespace(RELPERSISTENCE_TEMP);
	else
		tableSpace = matviewRel->rd_rel->reltablespace;

	/* If an AO temp table has index, we need to create it. */
	createAoBlockDirectory = matviewRel->rd_rel->relhasindex;

	/*
	 * Create the transient table that will receive the regenerated data. Lock
	 * it against access by any other process until commit (by which time it
	 * will be gone).
	 */
	OIDNewHeap = make_new_heap(matviewOid, tableSpace, concurrent,
							   ExclusiveLock, createAoBlockDirectory, true);
	LockRelationOid(OIDNewHeap, AccessExclusiveLock);
	dest = CreateTransientRelDestReceiver(OIDNewHeap, matviewOid, concurrent, stmt->skipData);

	refreshClause = MakeRefreshClause(concurrent, stmt->skipData, stmt->relation);

	dataQuery->intoPolicy = matviewRel->rd_cdbpolicy;
	/* Generate the data, if wanted. */
	refresh_matview_datafill(dest, dataQuery, queryString, refreshClause);

	heap_close(matviewRel, NoLock);

	/* Make the matview match the newly generated data. */
	if (concurrent)
	{
		int			old_depth = matview_maintenance_depth;

		PG_TRY();
		{
			refresh_by_match_merge(matviewOid, OIDNewHeap, relowner,
								   save_sec_context);
		}
		PG_CATCH();
		{
			matview_maintenance_depth = old_depth;
			PG_RE_THROW();
		}
		PG_END_TRY();
		Assert(matview_maintenance_depth == old_depth);
	}
	else
		refresh_by_heap_swap(matviewOid, OIDNewHeap);

	/* Roll back any GUC changes */
	AtEOXact_GUC(false, save_nestlevel);

	/* Restore userid and security context */
	SetUserIdAndSecContext(save_userid, save_sec_context);
}

/*
 * refresh_matview_datafill
 */
static void
refresh_matview_datafill(DestReceiver *dest, Query *query,
						 const char *queryString, RefreshClause *refreshClause)
{
	List	   *rewritten;
	PlannedStmt *plan;
	QueryDesc  *queryDesc;
	Query	   *copied_query;

	/*
	 * Greengage specific behavior:
	 * MPP architecture need to make sure OIDs of the temp table are the same
	 * among QD and all QEs. It stores the OID in the static variable dispatch_oids.
	 * This variable will be consumed for each dispatch.
	 *
	 * During planning, Greengage might pre-evalute some function expr, this will
	 * lead to dispatch if the function is in SQL or PLPGSQL and consume the above
	 * static variable. So later refresh matview's dispatch will not find the
	 * oid on QEs.
	 *
	 * We first store the OIDs information in a local variable, and then restore
	 * it for later refresh matview's dispatch to solve the above issue.
	 *
	 * See Github Issue for details: https://github.com/GreengageDB/greengage/issues/11956
	 */
	List       *saved_dispatch_oids = SaveOidAssignments();

	/* Lock and rewrite, using a copy to preserve the original query. */
	copied_query = copyObject(query);
	AcquireRewriteLocks(copied_query, true, false);
	rewritten = QueryRewrite(copied_query);

	/* SELECT should never rewrite to more or less than one SELECT query */
	if (list_length(rewritten) != 1)
		elog(ERROR, "unexpected rewrite result for REFRESH MATERIALIZED VIEW");
	query = (Query *) linitial(rewritten);

	/* Check for user-requested abort. */
	CHECK_FOR_INTERRUPTS();

	/* Plan the query which will generate data for the refresh. */
	plan = pg_plan_query(query, 0, NULL);

	plan->refreshClause = refreshClause;

	/*
	 * Use a snapshot with an updated command ID to ensure this query sees
	 * results of any previously executed queries.  (This could only matter if
	 * the planner executed an allegedly-stable function that changed the
	 * database contents, but let's do it anyway to be safe.)
	 */
	PushCopiedSnapshot(GetActiveSnapshot());
	UpdateActiveSnapshotCommandId();

	/* Create a QueryDesc, redirecting output to our tuple receiver */
	queryDesc = CreateQueryDesc(plan, queryString,
								GetActiveSnapshot(), InvalidSnapshot,
								dest, NULL, 0);

	if (gp_enable_gpperfmon && Gp_role == GP_ROLE_DISPATCH)
	{
		Assert(queryString);
		gpmon_qlog_query_submit(queryDesc->gpmon_pkt);
		gpmon_qlog_query_text(queryDesc->gpmon_pkt,
				queryString,
				application_name,
				GetResqueueName(GetResQueueId()),
				GetResqueuePriority(GetResQueueId()));
	}

	RestoreOidAssignments(saved_dispatch_oids);

	/* call ExecutorStart to prepare the plan for execution */
	ExecutorStart(queryDesc, EXEC_FLAG_WITHOUT_OIDS);

	/* run the plan */
	ExecutorRun(queryDesc, ForwardScanDirection, 0L);

	/* and clean up */
	ExecutorFinish(queryDesc);
	ExecutorEnd(queryDesc);

	FreeQueryDesc(queryDesc);

	PopActiveSnapshot();
}

DestReceiver *
CreateTransientRelDestReceiver(Oid transientoid, Oid oldreloid, bool concurrent, bool skipdata)

{
	DR_transientrel *self = (DR_transientrel *) palloc0(sizeof(DR_transientrel));

	self->pub.receiveSlot = transientrel_receive;
	self->pub.rStartup = transientrel_startup;
	self->pub.rShutdown = transientrel_shutdown;
	self->pub.rDestroy = transientrel_destroy;
	self->pub.mydest = DestTransientRel;
	self->transientoid = transientoid;
	self->oldreloid = oldreloid;
	self->concurrent = concurrent;
	self->skipData = skipdata;

	return (DestReceiver *) self;
}

void
transientrel_init(QueryDesc *queryDesc)
{
	Oid			matviewOid;
	Relation	matviewRel;
	Oid			tableSpace;
	Oid			OIDNewHeap;
	bool		concurrent;
	LOCKMODE	lockmode;
	bool 		createAoBlockDirectory;
	RefreshClause *refreshClause;

	refreshClause = queryDesc->plannedstmt->refreshClause;
	/* Determine strength of lock needed. */
	concurrent = refreshClause->concurrent;
	lockmode = concurrent ? ExclusiveLock : AccessExclusiveLock;

	/*
	 * Get a lock until end of transaction.
	 */
	matviewOid = RangeVarGetRelidExtended(refreshClause->relation,
										  lockmode, false, false,
										  RangeVarCallbackOwnsTable, NULL);
	matviewRel = heap_open(matviewOid, NoLock);

	/*
	 * Tentatively mark the matview as populated or not (this will roll back
	 * if we fail later).
	 */
	SetMatViewPopulatedState(matviewRel, !refreshClause->skipData);

	/* Concurrent refresh builds new data in temp tablespace, and does diff. */
	if (concurrent)
	{
		tableSpace = GetDefaultTablespace(RELPERSISTENCE_TEMP);
	}
	else
	{
		tableSpace = matviewRel->rd_rel->reltablespace;
	}

	/* If an AO temp table has index, we need to create it. */
	createAoBlockDirectory = matviewRel->rd_rel->relhasindex;

	/*
	 * Create the transient table that will receive the regenerated data. Lock
	 * it against access by any other process until commit (by which time it
	 * will be gone).
	 */
	OIDNewHeap = make_new_heap(matviewOid, tableSpace, concurrent,
							   ExclusiveLock, createAoBlockDirectory, false);
	LockRelationOid(OIDNewHeap, AccessExclusiveLock);

	queryDesc->dest = CreateTransientRelDestReceiver(OIDNewHeap, matviewOid, concurrent,
													 refreshClause->skipData);

	heap_close(matviewRel, NoLock);
}

/*
 * transientrel_startup --- executor startup
 */
static void
transientrel_startup(DestReceiver *self, int operation, TupleDesc typeinfo)
{
	DR_transientrel *myState = (DR_transientrel *) self;
	Relation	transientrel;

	transientrel = heap_open(myState->transientoid, NoLock);

	/*
	 * Fill private fields of myState for use by later routines
	 */
	myState->transientrel = transientrel;
	myState->output_cid = GetCurrentCommandId(true);

	/*
	 * We can skip WAL-logging the insertions, unless PITR or streaming
	 * replication is in use. We can skip the FSM in any case.
	 */
	myState->hi_options = HEAP_INSERT_SKIP_FSM | HEAP_INSERT_FROZEN;
	if (!XLogIsNeeded())
		myState->hi_options |= HEAP_INSERT_SKIP_WAL;
	myState->bistate = GetBulkInsertState();

	/* Not using WAL requires smgr_targblock be initially invalid */
	Assert(RelationGetTargetBlock(transientrel) == InvalidBlockNumber);
}

/*
 * transientrel_receive --- receive one tuple
 */
static void
transientrel_receive(TupleTableSlot *slot, DestReceiver *self)
{
	DR_transientrel *myState = (DR_transientrel *) self;

	if (myState->skipData)
		return;

	/*
	 * get the heap tuple out of the tuple table slot, making sure we have a
	 * writable copy
	 */

	if (RelationIsAoRows(myState->transientrel))
	{
		AOTupleId	aoTupleId;
		MemTuple	tuple;

		tuple = ExecCopySlotMemTuple(slot);
		if (myState->ao_insertDesc == NULL)
			myState->ao_insertDesc = appendonly_insert_init(myState->transientrel, RESERVED_SEGNO, false);

		appendonly_insert(myState->ao_insertDesc, tuple, InvalidOid, &aoTupleId);
		pfree(tuple);
	}
	else if (RelationIsAoCols(myState->transientrel))
	{
		if(myState->aocs_insertDes == NULL)
			myState->aocs_insertDes = aocs_insert_init(myState->transientrel, RESERVED_SEGNO, false);

		aocs_insert(myState->aocs_insertDes, slot);
	}
	else
	{
		HeapTuple	tuple;

		/*
		 * get the heap tuple out of the tuple table slot, making sure we have a
		 * writable copy
		 */
		tuple = ExecMaterializeSlot(slot);

		/*
		 * force assignment of new OID (see comments in ExecInsert)
		 */
		if (myState->transientrel->rd_rel->relhasoids)
			HeapTupleSetOid(tuple, InvalidOid);

		heap_insert(myState->transientrel,
					tuple,
					myState->output_cid,
					myState->hi_options,
					myState->bistate,
					GetCurrentTransactionId());

		/* We know this is a newly created relation, so there are no indexes */
	}


	/* We know this is a newly created relation, so there are no indexes */
}

/*
 * transientrel_shutdown --- executor end
 */
static void
transientrel_shutdown(DestReceiver *self)
{
	DR_transientrel *myState = (DR_transientrel *) self;

	FreeBulkInsertState(myState->bistate);

	/* If we skipped using WAL, must heap_sync before commit */
	if (myState->hi_options & HEAP_INSERT_SKIP_WAL)
		heap_sync(myState->transientrel);

	if (RelationIsAoRows(myState->transientrel) && myState->ao_insertDesc)
		appendonly_insert_finish(myState->ao_insertDesc);
	else if (RelationIsAoCols(myState->transientrel) && myState->aocs_insertDes)
		aocs_insert_finish(myState->aocs_insertDes);

	/* close transientrel, but keep lock until commit */
	heap_close(myState->transientrel, NoLock);

	myState->transientrel = NULL;
	if (Gp_role == GP_ROLE_EXECUTE && !myState->concurrent)
		refresh_by_heap_swap(myState->oldreloid, myState->transientoid);
}

/*
 * transientrel_destroy --- release DestReceiver object
 */
static void
transientrel_destroy(DestReceiver *self)
{
	pfree(self);
}


/*
 * Given a qualified temporary table name, append an underscore followed by
 * the given integer, to make a new table name based on the old one.
 *
 * This leaks memory through palloc(), which won't be cleaned up until the
 * current memory memory context is freed.
 */
static char *
make_temptable_name_n(char *tempname, int n)
{
	StringInfoData namebuf;

	initStringInfo(&namebuf);
	appendStringInfoString(&namebuf, tempname);
	appendStringInfo(&namebuf, "_%i", n);
	return namebuf.data;
}

/*
 * refresh_by_match_merge
 *
 * Refresh a materialized view with transactional semantics, while allowing
 * concurrent reads.
 *
 * This is called after a new version of the data has been created in a
 * temporary table.  It performs a full outer join against the old version of
 * the data, producing "diff" results.  This join cannot work if there are any
 * duplicated rows in either the old or new versions, in the sense that every
 * column would compare as equal between the two rows.  It does work correctly
 * in the face of rows which have at least one NULL value, with all non-NULL
 * columns equal.  The behavior of NULLs on equality tests and on UNIQUE
 * indexes turns out to be quite convenient here; the tests we need to make
 * are consistent with default behavior.  If there is at least one UNIQUE
 * index on the materialized view, we have exactly the guarantee we need.
 *
 * The temporary table used to hold the diff results contains just the TID of
 * the old record (if matched) and the ROW from the new table as a single
 * column of complex record type (if matched).
 *
 * Once we have the diff table, we perform set-based DELETE and INSERT
 * operations against the materialized view, and discard both temporary
 * tables.
 *
 * Everything from the generation of the new data to applying the differences
 * takes place under cover of an ExclusiveLock, since it seems as though we
 * would want to prohibit not only concurrent REFRESH operations, but also
 * incremental maintenance.  It also doesn't seem reasonable or safe to allow
 * SELECT FOR UPDATE or SELECT FOR SHARE on rows being updated or deleted by
 * this command.
 */
static void
refresh_by_match_merge(Oid matviewOid, Oid tempOid, Oid relowner,
					   int save_sec_context)
{
	StringInfoData querybuf;
	Relation	matviewRel;
	Relation	tempRel;
	char	   *matviewname;
	char	   *tempname;
	char	   *diffname;
	TupleDesc	tupdesc;
	bool		foundUniqueIndex;
	List	   *indexoidlist;
	ListCell   *indexoidscan;
	int16		relnatts;
	Oid		   *opUsedForQual;
	char 	   *distributed;

	initStringInfo(&querybuf);
	matviewRel = heap_open(matviewOid, NoLock);
	matviewname = quote_qualified_identifier(get_namespace_name(RelationGetNamespace(matviewRel)),
										RelationGetRelationName(matviewRel));
	tempRel = heap_open(tempOid, NoLock);
	tempname = quote_qualified_identifier(get_namespace_name(RelationGetNamespace(tempRel)),
										  RelationGetRelationName(tempRel));
	diffname = make_temptable_name_n(tempname, 2);

	relnatts = matviewRel->rd_rel->relnatts;

	/* Open SPI context. */
	if (SPI_connect() != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed");

	/* Analyze the temp table with the new contents. */
	appendStringInfo(&querybuf, "ANALYZE %s", tempname);
	if (SPI_exec(querybuf.data, 0) != SPI_OK_UTILITY)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);

	/*
	 * We need to ensure that there are not duplicate rows without NULLs in
	 * the new data set before we can count on the "diff" results.  Check for
	 * that in a way that allows showing the first duplicated row found.  Even
	 * after we pass this test, a unique index on the materialized view may
	 * find a duplicate key problem.
	 */
	resetStringInfo(&querybuf);
	appendStringInfo(&querybuf,
					 "SELECT newdata FROM %s newdata "
					 "WHERE newdata IS NOT NULL AND EXISTS "
					 "(SELECT 1 FROM %s newdata2 WHERE newdata2 IS NOT NULL "
					 "AND newdata2 OPERATOR(pg_catalog.*=) newdata "
					 "AND newdata2.ctid OPERATOR(pg_catalog.<>) "
					 "newdata.ctid and newdata2.gp_segment_id = "
					 "newdata.gp_segment_id)",
					 tempname, tempname);
	if (SPI_execute(querybuf.data, false, 1) != SPI_OK_SELECT)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);
	if (SPI_processed > 0)
	{
		/*
		 * Note that this ereport() is returning data to the user.  Generally,
		 * we would want to make sure that the user has been granted access to
		 * this data.  However, REFRESH MAT VIEW is only able to be run by the
		 * owner of the mat view (or a superuser) and therefore there is no
		 * need to check for access to data in the mat view.
		 */
		ereport(ERROR,
				(errcode(ERRCODE_CARDINALITY_VIOLATION),
				 errmsg("new data for \"%s\" contains duplicate rows without any null columns",
						RelationGetRelationName(matviewRel)),
				 errdetail("Row: %s",
			SPI_getvalue(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1))));
	}

	SetUserIdAndSecContext(relowner,
						   save_sec_context | SECURITY_LOCAL_USERID_CHANGE);

	/* Get distribute key of matview */
	distributed =  TextDatumGetCString(DirectFunctionCall1(pg_get_table_distributedby,
														   ObjectIdGetDatum(matviewOid)));

	/* Start building the query for creating the diff table. */
	resetStringInfo(&querybuf);

	appendStringInfo(&querybuf,
					 "CREATE TEMP TABLE %s AS "
					 "SELECT mv.ctid AS tid, mv.gp_segment_id as sid, newdata.* "
					 "FROM %s mv FULL JOIN %s newdata ON (",
					 diffname, matviewname, tempname);

	/*
	 * Get the list of index OIDs for the table from the relcache, and look up
	 * each one in the pg_index syscache.  We will test for equality on all
	 * columns present in all unique indexes which only reference columns and
	 * include all rows.
	 */
	tupdesc = matviewRel->rd_att;
	opUsedForQual = (Oid *) palloc0(sizeof(Oid) * relnatts);
	foundUniqueIndex = false;

	indexoidlist = RelationGetIndexList(matviewRel);

	foreach(indexoidscan, indexoidlist)
	{
		Oid			indexoid = lfirst_oid(indexoidscan);
		Relation	indexRel;

		indexRel = index_open(indexoid, RowExclusiveLock);
		if (is_usable_unique_index(indexRel))
		{
			Form_pg_index indexStruct = indexRel->rd_index;
			int			numatts = indexStruct->indnatts;
			oidvector  *indclass;
			Datum		indclassDatum;
			bool		isnull;
			int			i;

			/* Must get indclass the hard way. */
			indclassDatum = SysCacheGetAttr(INDEXRELID,
											indexRel->rd_indextuple,
											Anum_pg_index_indclass,
											&isnull);
			Assert(!isnull);
			indclass = (oidvector *) DatumGetPointer(indclassDatum);

			/* Add quals for all columns from this index. */
			for (i = 0; i < numatts; i++)
			{
				int			attnum = indexStruct->indkey.values[i];
				Oid			opclass = indclass->values[i];
				Form_pg_attribute attr = TupleDescAttr(tupdesc, attnum - 1);
				Oid			attrtype = attr->atttypid;
				HeapTuple	cla_ht;
				Form_pg_opclass cla_tup;
				Oid			opfamily;
				Oid			opcintype;
				Oid			op;
				const char *leftop;
				const char *rightop;

				/*
				 * Identify the equality operator associated with this index
				 * column.  First we need to look up the column's opclass.
				 */
				cla_ht = SearchSysCache1(CLAOID, ObjectIdGetDatum(opclass));
				if (!HeapTupleIsValid(cla_ht))
					elog(ERROR, "cache lookup failed for opclass %u", opclass);
				cla_tup = (Form_pg_opclass) GETSTRUCT(cla_ht);
				Assert(cla_tup->opcmethod == BTREE_AM_OID);
				opfamily = cla_tup->opcfamily;
				opcintype = cla_tup->opcintype;
				ReleaseSysCache(cla_ht);

				op = get_opfamily_member(opfamily, opcintype, opcintype,
										 BTEqualStrategyNumber);
				if (!OidIsValid(op))
					elog(ERROR, "missing operator %d(%u,%u) in opfamily %u",
						 BTEqualStrategyNumber, opcintype, opcintype, opfamily);

				/*
				 * If we find the same column with the same equality semantics
				 * in more than one index, we only need to emit the equality
				 * clause once.
				 *
				 * Since we only remember the last equality operator, this
				 * code could be fooled into emitting duplicate clauses given
				 * multiple indexes with several different opclasses ... but
				 * that's so unlikely it doesn't seem worth spending extra
				 * code to avoid.
				 */
				if (opUsedForQual[attnum - 1] == op)
					continue;
				opUsedForQual[attnum - 1] = op;

				/*
				 * Actually add the qual, ANDed with any others.
				 */
				if (foundUniqueIndex)
					appendStringInfoString(&querybuf, " AND ");

				leftop = quote_qualified_identifier("newdata",
													NameStr(attr->attname));
				rightop = quote_qualified_identifier("mv",
													 NameStr(attr->attname));

				generate_operator_clause(&querybuf,
										 leftop, attrtype,
										 op,
										 rightop, attrtype);

				foundUniqueIndex = true;
			}
		}

		/* Keep the locks, since we're about to run DML which needs them. */
		index_close(indexRel, NoLock);
	}

	list_free(indexoidlist);

	/*
	 * There must be at least one unique index on the matview.
	 *
	 * ExecRefreshMatView() checks that after taking the exclusive lock on
	 * the matview. So at least one unique index is guaranteed to exist here
	 * because the lock is still being held.
	 */
	Assert(foundUniqueIndex);



	appendStringInfoString(&querybuf,
						   " AND newdata OPERATOR(pg_catalog.*=) mv) "
						   "WHERE newdata IS NULL OR mv IS NULL "
						   "ORDER BY tid ");
	appendStringInfoString(&querybuf, distributed);

	/* Create the temporary "diff" table. */
	if (SPI_exec(querybuf.data, 0) != SPI_OK_UTILITY)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);

	SetUserIdAndSecContext(relowner,
						   save_sec_context | SECURITY_RESTRICTED_OPERATION);

	/*
	 * We have no further use for data from the "full-data" temp table, but we
	 * must keep it around because its type is referenced from the diff table.
	 */

	/* Analyze the diff table. */
	resetStringInfo(&querybuf);
	appendStringInfo(&querybuf, "ANALYZE %s", diffname);
	if (SPI_exec(querybuf.data, 0) != SPI_OK_UTILITY)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);

	OpenMatViewIncrementalMaintenance();

	/* Deletes must come before inserts; do them first. */
	resetStringInfo(&querybuf);
	appendStringInfo(&querybuf,
					 "DELETE FROM %s mv WHERE exists "
					 "(SELECT diff.tid FROM %s diff "
					 "WHERE diff.tid = mv.ctid and diff.sid = mv.gp_segment_id and"
	 				 " diff.tid IS NOT NULL)",
					 matviewname, diffname);
	if (SPI_exec(querybuf.data, 0) != SPI_OK_DELETE)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);

	/* Inserts go last. */
	resetStringInfo(&querybuf);
	appendStringInfo(&querybuf, "INSERT INTO %s SELECT", matviewname);
	for (int i = 0; i < tupdesc->natts; ++i)
	{
		Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
		if (i == tupdesc->natts - 1)
			appendStringInfo(&querybuf, " %s", NameStr(attr->attname));
		else
			appendStringInfo(&querybuf, " %s,", NameStr(attr->attname));
	}
	appendStringInfo(&querybuf,
					 " FROM %s diff WHERE tid IS NULL",
					 diffname);
	if (SPI_exec(querybuf.data, 0) != SPI_OK_INSERT)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);

	/* We're done maintaining the materialized view. */
	CloseMatViewIncrementalMaintenance();
	heap_close(tempRel, NoLock);
	heap_close(matviewRel, NoLock);

	/* Clean up temp tables. */
	resetStringInfo(&querybuf);
	appendStringInfo(&querybuf, "DROP TABLE %s, %s", diffname, tempname);
	if (SPI_exec(querybuf.data, 0) != SPI_OK_UTILITY)
		elog(ERROR, "SPI_exec failed: %s", querybuf.data);

	/* Close SPI context. */
	if (SPI_finish() != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed");
}

/*
 * Swap the physical files of the target and transient tables, then rebuild
 * the target's indexes and throw away the transient table.  Security context
 * swapping is handled by the called function, so it is not needed here.
 */
static void
refresh_by_heap_swap(Oid matviewOid, Oid OIDNewHeap)
{
	finish_heap_swap(matviewOid, OIDNewHeap,
					 false, /* is_system_catalog */
					 false, /* swap_toast_by_content */
					 false, /* swap_stats */
					 true, /* check_constraints */
					 true, /* is_internal */
					 RecentXmin, ReadNextMultiXactId());
}

/*
 * Check whether specified index is usable for match merge.
 */
static bool
is_usable_unique_index(Relation indexRel)
{
	Form_pg_index indexStruct = indexRel->rd_index;

	/*
	 * Must be unique, valid, immediate, non-partial, and be defined over
	 * plain user columns (not expressions).  We also require it to be a
	 * btree.  Even if we had any other unique index kinds, we'd not know how
	 * to identify the corresponding equality operator, nor could we be sure
	 * that the planner could implement the required FULL JOIN with non-btree
	 * operators.
	 */
	if (indexStruct->indisunique &&
		indexStruct->indimmediate &&
		indexRel->rd_rel->relam == BTREE_AM_OID &&
		IndexIsValid(indexStruct) &&
		RelationGetIndexPredicate(indexRel) == NIL &&
		indexStruct->indnatts > 0)
	{
		/*
		 * The point of groveling through the index columns individually is to
		 * reject both index expressions and system columns.  Currently,
		 * matviews couldn't have OID columns so there's no way to create an
		 * index on a system column; but maybe someday that wouldn't be true,
		 * so let's be safe.
		 */
		int			numatts = indexStruct->indnatts;
		int			i;

		for (i = 0; i < numatts; i++)
		{
			int			attnum = indexStruct->indkey.values[i];

			if (attnum <= 0)
				return false;
		}
		return true;
	}
	return false;
}


/*
 * This should be used to test whether the backend is in a context where it is
 * OK to allow DML statements to modify materialized views.  We only want to
 * allow that for internal code driven by the materialized view definition,
 * not for arbitrary user-supplied code.
 *
 * While the function names reflect the fact that their main intended use is
 * incremental maintenance of materialized views (in response to changes to
 * the data in referenced relations), they are initially used to allow REFRESH
 * without blocking concurrent reads.
 */
bool
MatViewIncrementalMaintenanceIsEnabled(void)
{
	if (Gp_role == GP_ROLE_EXECUTE)
		return true;
	else
		return matview_maintenance_depth > 0;
}

static void
OpenMatViewIncrementalMaintenance(void)
{
	matview_maintenance_depth++;
}

static void
CloseMatViewIncrementalMaintenance(void)
{
	matview_maintenance_depth--;
	Assert(matview_maintenance_depth >= 0);
}
