//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2012 EMC Corp.
//
//	@filename:
//		CQueryMutators.cpp
//
//	@doc:
//		Implementation of methods used during translating a GPDB Query object into a
//		DXL Tree
//
//	@test:
//
//---------------------------------------------------------------------------

extern "C" {
#include "postgres.h"

#include "nodes/makefuncs.h"
#include "nodes/parsenodes.h"
#include "nodes/plannodes.h"
#include "optimizer/walkers.h"
}

#include "gpopt/base/CUtils.h"
#include "gpopt/gpdbwrappers.h"
#include "gpopt/mdcache/CMDAccessor.h"
#include "gpopt/mdcache/CMDAccessorUtils.h"
#include "gpopt/translate/CQueryMutators.h"
#include "gpopt/translate/CTranslatorDXLToPlStmt.h"
#include "naucrates/md/IMDAggregate.h"
#include "naucrates/md/IMDScalarOp.h"
#include "naucrates/md/IMDTypeBool.h"

using namespace gpdxl;
using namespace gpmd;


//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GroupingListContainsPrimaryKey
//
//	@doc:
//		Checks if list grouping_list contains all columns from conkeys of
//		Primary Key in relation conrelid. grouping_list is treated as flat
//		list of SortGroupClauses, other nodes are ignored.
//		Important note: grouping_list should not have duplicate values.
//---------------------------------------------------------------------------
BOOL
CQueryMutators::GroupingListContainsPrimaryKey(Query *query,
											   List *grouping_list,
											   List *conkeys, Oid conrelid)
{
	ListCell *lgc;
	ULONG found_col_cnt = 0;

	// Check if conkeys set is a subset of grouping columns set.
	ForEach(lgc, grouping_list)
	{
		Node *grpcl = (Node *) lfirst(lgc);

		if (NULL == grpcl || !IsA(grpcl, SortGroupClause))
		{
			continue;
		}

		SortGroupClause *sgc = (SortGroupClause *) grpcl;
		Node *expr = gpdb::GetSortGroupClauseExpr(sgc, query->targetList);

		if (!IsA(expr, Var))
		{
			continue;
		}

		Var *var = (Var *) expr;

		RangeTblEntry *rte =
			(RangeTblEntry *) gpdb::ListNth(query->rtable, var->varno - 1);

		if (0 == var->varlevelsup && rte->relid == conrelid &&
			gpdb::ListMemberInt(conkeys, var->varattno))
		{
			found_col_cnt++;
		}
	}

	// check that all conkeys were found
	return (gpdb::ListLength(conkeys) == found_col_cnt);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::AddMissingGroupClauseMutator
//
//	@doc:
//		Traverses the groupClause, adds new SortGroupClause (defined by m_gc
//		field in context) to all grouping lists where m_gc has functional
//		dependency.
//---------------------------------------------------------------------------
Node *
CQueryMutators::AddMissingGroupClauseMutator(
	Node *node, SContextFixGroupDependentTargets *context)
{
	if (NULL == node)
	{
		return NULL;
	}

	if (IsA(node, SortGroupClause))
	{
		if (context->m_parent_is_grouping_clause)
		{
			// In case the SortGroupClause is direct element of groupsets list
			// of GroupingClause, we treat it in a special way - consider
			// it like a 1-element list.
			List *ls = ListMake1(node);
			Node *new_node = AddMissingGroupClauseMutator((Node *) ls, context);
			gpdb::ListFree(ls);
			return new_node;
		}
		return (Node *) gpdb::CopyObject(node);
	}

	if (IsA(node, GroupingClause))
	{
		GroupingClause *original_grouping_clause = (GroupingClause *) node;
		GroupingClause *new_grouping_clause = MakeNode(GroupingClause);
		new_grouping_clause->groupType = original_grouping_clause->groupType;
		ListCell *l;
		ForEach(l, original_grouping_clause->groupsets)
		{
			Node *n = (Node *) lfirst(l);
			// need to add this flag before processing of every element of the
			// groupsets list, because nested lists may rewrite it
			context->m_parent_is_grouping_clause = true;
			new_grouping_clause->groupsets =
				gpdb::LAppend(new_grouping_clause->groupsets,
							  AddMissingGroupClauseMutator(n, context));
		}
		return (Node *) new_grouping_clause;
	}

	if (IsA(node, List))
	{
		// construct new list
		List *original_list = (List *) node;
		List *new_list = NIL;
		ListCell *l;
		context->m_parent_is_grouping_clause = false;
		ForEach(l, original_list)
		{
			Node *n = (Node *) lfirst(l);
			new_list = gpdb::LAppendUnique(
				new_list, AddMissingGroupClauseMutator(n, context));
		}

		if (GroupingListContainsPrimaryKey(context->m_query, new_list,
										   context->m_conkeys,
										   context->m_conrelid))
		{
			new_list = gpdb::LAppend(new_list,
									 gpdb::CopyObject((Node *) context->m_gc));
		}
		return (Node *) new_list;
	}
	return gpdb::MutateExpressionTree(
		node, (MutatorWalkerFn) AddMissingGroupClauseMutator, context);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GetGroupUniqueTleReferencesWalker
//
//	@doc:
//		Goes over the groupClause expression tree and collects unique
//		references to targetlist entries.
//---------------------------------------------------------------------------
BOOL
CQueryMutators::GetGroupUniqueTleReferencesWalker(
	Node *node, SContexGetGroupUniqueTleWalker *context)
{
	if (NULL == node)
	{
		return false;
	}

	if (IsA(node, SortGroupClause))
	{
		SortGroupClause *sgc = (SortGroupClause *) node;
		context->m_grouping_tle_refs = gpdb::LAppendUniqueInt(
			context->m_grouping_tle_refs, sgc->tleSortGroupRef);
		return false;
	}
	return gpdb::WalkExpressionTree(
		node, (ExprWalkerFn) GetGroupUniqueTleReferencesWalker, context);
};

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GroupingFuncRewriteWalker
//
//	@doc:
//		Goes over the expression tree and update arguments of GROUPING
//		function.
//---------------------------------------------------------------------------
BOOL
CQueryMutators::GroupingFuncRewriteWalker(
	Node *node, SContexGroupingFuncRewriteWalker *context)
{
	if (NULL == node)
	{
		return false;
	}

	if (IsA(node, GroupingFunc))
	{
		GroupingFunc *gf = (GroupingFunc *) node;
		ListCell *arg_lc;
		List *newargs = NIL;

		gf->ngrpcols = context->m_ngrpcols;

		// For each argument in gf->args, find its new position
		ForEach(arg_lc, gf->args)
		{
			ULONG arg = intVal(lfirst(arg_lc));
			ULONG new_arg =
				gpdb::ListNthInt(context->m_grouping_tle_refs_mapping, arg);
			newargs = gpdb::LAppend(newargs, gpdb::MakeIntegerValue(new_arg));
		}

		// Free gf->args since we do not need it any more.
		gpdb::ListFreeDeep(gf->args);
		gf->args = newargs;
		return false;
	}
	return gpdb::WalkExpressionTree(
		node, (ExprWalkerFn) GroupingFuncRewriteWalker, context);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GetVarsWithoutTleWalker
//
//	@doc:
//		Goes over the expression tree, finds all vars that do not have relevant
//		targetlist entries, and adds resjunk targetlist entries for such vars
//		to a m_tlist_addition in the context, that later will be added to the
//		original target list.
//---------------------------------------------------------------------------
BOOL
CQueryMutators::GetVarsWithoutTleWalker(
	Node *node, SContextFixGroupDependentTargets *context)
{
	if (NULL == node)
	{
		return false;
	}

	if (IsA(node, Aggref))
	{
		// do not examine what is inside Aggref
		return false;
	}

	// find all vars that do not have relevant targetlist entries, and add
	// resjunk targetlist entries for such vars to m_tlist_addition
	if (IsA(node, Var))
	{
		Var *var = (Var *) node;
		if (var->varlevelsup == context->m_current_query_level)
		{
			BOOL found = false;

			var = (Var *) gpdb::CopyObject(node);
			var->varlevelsup = 0;

			ListCell *lc_tle;
			ForEach(lc_tle, context->m_query->targetList)
			{
				TargetEntry *target_entry = (TargetEntry *) lfirst(lc_tle);

				if (IsA(target_entry->expr, Var) &&
					gpdb::Equals(target_entry->expr, var))
				{
					found = true;
					gpdb::GPDBFree(var);
					break;
				}
			}
			if (!found)
			{
				ULONG ressno =
					gpdb::ListLength(context->m_query->targetList) + 1;
				TargetEntry *newTargetEntry =
					gpdb::MakeTargetEntry((Expr *) var, ressno, NULL, true);

				context->m_tlist_addition =
					gpdb::LAppend(context->m_tlist_addition, newTargetEntry);
			}
		}

		return false;
	}

	if (IsA(node, SubLink))
	{
		SubLink *sublink = (SubLink *) node;

		context->m_current_query_level++;
		GetVarsWithoutTleWalker((Node *) sublink->subselect, context);
		context->m_current_query_level--;

		return false;
	}

	// recurse into query structure
	if (IsA(node, Query))
	{
		Query *query = (Query *) node;
		GetVarsWithoutTleWalker((Node *) query->targetList, context);

		ListCell *lc;
		ForEach(lc, query->rtable)
		{
			RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);

			GPOS_ASSERT(rte != NULL);

			if (RTE_SUBQUERY == rte->rtekind)
			{
				Query *subquery = rte->subquery;
				context->m_current_query_level++;
				GetVarsWithoutTleWalker((Node *) subquery, context);
				context->m_current_query_level--;
			}
		}
	}

	return gpdb::WalkExpressionTree(
		node, (ExprWalkerFn) GetVarsWithoutTleWalker, (void *) context);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::FixGroupDependentTargets
//
//	@doc:
//		Updates the query structure in case there are target list entries
//		with functional dependency on columns in groupClause.
//---------------------------------------------------------------------------
void
CQueryMutators::FixGroupDependentTargets(Query *query)
{
	// If there is a functional dependency proved for a relation on a set of
	// grouping columns, then it is valid to have a column in the target list
	// even if it is not listed explicitly in the groupClause. To make ORCA
	// correctly process such cases, we add all such target list entries into
	// groupClause's grouping sets, where the functional dependency exists.
	// If there is such functional dependency existing, the OID of
	// Primary Key constraint resides in the constraintDeps list. As the
	// constraintDeps list contains only Primary Key OIDs, we skip checks of
	// constraint type in all code below.
	// Refer to function check_functional_grouping for more details.
	if (0 == gpdb::ListLength(query->constraintDeps))
	{
		return;
	}
	// 1. Extract such columns from targetlist expressions, and if they do
	// not have a relevant target entry, add resjunk target list entries for
	// them.
	// 2. Store current unique TargetEntry references in groupClause -
	// they will be needed at step 4.
	// 3. Update all grouping sets that contain Primary Key
	// 4. Update arguments of GROUPING functions, because they could be
	// shifted after step 3.

	// Step 1.
	// If there is an expression with a functionally dependent var, at this
	// point it may not have a relevant target list entry (as it was not
	// explicitly listed in groupClause).
	// For all such vars we add resjunk target list entries into targetList.
	SContextFixGroupDependentTargets ctx_fix_dependent_targets(query);
	GetVarsWithoutTleWalker((Node *) query->targetList,
							&ctx_fix_dependent_targets);
	query->targetList = gpdb::ListConcat(
		query->targetList, ctx_fix_dependent_targets.m_tlist_addition);

	// Step 2.
	// Store current unique TargetEntry references in groupClause.
	// After modifying groupClause, they will be required to update
	// arguments inside grouping functions.
	SContexGetGroupUniqueTleWalker ctx_old_grouping_tle_refs;
	GetGroupUniqueTleReferencesWalker((Node *) query->groupClause,
									  &ctx_old_grouping_tle_refs);

	// Step 3.
	// Update groupClause - add all functionally dependent entries explicitly.
	ListCell *lc_constraint;
	ForEach(lc_constraint, query->constraintDeps)
	{
		Oid constraint_oid = lfirst_oid(lc_constraint);
		Oid conrelid = 0;
		Oid confrelid =
			0;	// not used, but function get_constraint_relation_oids requires it..
		gpdb::GetConstraintRelationOids(constraint_oid, &conrelid, &confrelid);

		ctx_fix_dependent_targets.m_conrelid = conrelid;
		ctx_fix_dependent_targets.m_conkeys =
			gpdb::GetConstraintRelationColumns(constraint_oid);

		ListCell *lc_tle;
		ForEach(lc_tle, query->targetList)
		{
			TargetEntry *target_entry = (TargetEntry *) lfirst(lc_tle);
			Node *expr = (Node *) target_entry->expr;

			if (!IsA(expr, Var))
			{
				continue;
			}

			Var *var = (Var *) expr;

			if (var->varlevelsup != 0)
			{
				continue;
			}

			RangeTblEntry *rte =
				(RangeTblEntry *) gpdb::ListNth(query->rtable, var->varno - 1);
			GPOS_ASSERT(NULL != rte);

			// Skip relations that are not constrained by primary key, that is
			// currently being checked, and skip target list entries that are
			// already used for grouping.
			if (conrelid != rte->relid || CTranslatorUtils::IsGroupingColumn(
											  target_entry, query->groupClause))
			{
				continue;
			}

			// add new SortGroupClause to groupClause
			SortGroupClause *gc;
			Oid sortop;
			Oid eqop;
			BOOL hashable;

			gpdb::GetSortGroupOperators(exprType(expr), true, true, false,
										&sortop, &eqop, NULL, &hashable);

			gc = MakeNode(SortGroupClause);
			gc->tleSortGroupRef =
				gpdb::AssignSortGroupRef(target_entry, query->targetList);
			gc->eqop = eqop;
			gc->sortop = sortop;
			gc->nulls_first = false;
			gc->hashable = hashable;

			ctx_fix_dependent_targets.m_gc = gc;
			ctx_fix_dependent_targets.m_parent_is_grouping_clause = false;

			List *old_group_clause = query->groupClause;

			query->groupClause = (List *) AddMissingGroupClauseMutator(
				(Node *) query->groupClause, &ctx_fix_dependent_targets);

			gpdb::ListFreeDeep(old_group_clause);
			gpdb::GPDBFree(gc);
		}
		gpdb::ListFree(ctx_fix_dependent_targets.m_conkeys);
	}
	// remove constraintDeps
	gpdb::ListFree(query->constraintDeps);
	query->constraintDeps = NIL;
	// End of update groupClause.

	// Step 4.
	// Get updated unique TargetEntry references in groupClause.
	SContexGetGroupUniqueTleWalker ctx_new_grouping_tle_refs;
	GetGroupUniqueTleReferencesWalker((Node *) query->groupClause,
									  &ctx_new_grouping_tle_refs);

	// Find new positions of the tle references after the update of groupClause.
	// Store new positions in the grouping_tle_refs_mapping.
	List *grouping_tle_refs_old = ctx_old_grouping_tle_refs.m_grouping_tle_refs;
	List *grouping_tle_refs_new = ctx_new_grouping_tle_refs.m_grouping_tle_refs;
	List *grouping_tle_refs_mapping = NIL;
	ListCell *lc_tle_ref_old;
	ForEach(lc_tle_ref_old, grouping_tle_refs_old)
	{
		int tle_ref_old = lfirst_int(lc_tle_ref_old);
		ListCell *lc_tle_ref_new;
		ULONG i = 0;
		ForEachWithCount(lc_tle_ref_new, grouping_tle_refs_new, i)
		{
			if (tle_ref_old == lfirst_int(lc_tle_ref_new))
			{
				break;
			}
		}

		GPOS_ASSERT(i < gpdb::ListLength(grouping_tle_refs_new));

		grouping_tle_refs_mapping =
			gpdb::LAppendInt(grouping_tle_refs_mapping, i);
	}

	// Finally fix arguments of grouping functions.
	SContexGroupingFuncRewriteWalker ctx_grouping_func_rewrite(
		grouping_tle_refs_mapping, gpdb::ListLength(grouping_tle_refs_new));

	GroupingFuncRewriteWalker((Node *) query->targetList,
							  &ctx_grouping_func_rewrite);

	gpdb::ListFree(grouping_tle_refs_mapping);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::NeedsProjListNormalization
//
//	@doc:
//		Is the group by project list flat (contains only aggregates
//		and grouping columns)
//---------------------------------------------------------------------------
BOOL
CQueryMutators::NeedsProjListNormalization(const Query *query)
{
	if (!query->hasAggs && NULL == query->groupClause)
	{
		return false;
	}

	SContextTLWalker context(query->targetList, query->groupClause);

	ListCell *lc = NULL;
	ForEach(lc, query->targetList)
	{
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);

		if (ShouldFallback((Node *) target_entry->expr, &context))
		{
			// TODO: remove temporary fix (revert exception to assert) to avoid crash during algebrization
			GPOS_RAISE(gpdxl::ExmaDXL, gpdxl::ExmiQuery2DXLError,
					   GPOS_WSZ_LIT("No attribute"));
		}

		// Normalize when there is an expression that is neither used for grouping
		// nor is an aggregate function
		if (!IsA(target_entry->expr, Aggref) &&
			!IsA(target_entry->expr, GroupingFunc) &&
			!CTranslatorUtils::IsGroupingColumn((Node *) target_entry->expr,
												query->groupClause,
												query->targetList))
		{
			return true;
		}
	}

	return false;
}


//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::ShouldFallback
//
//	@doc:
//		Fall back when the target list refers to a attribute which algebrizer
//		at this point cannot resolve
//---------------------------------------------------------------------------
BOOL
CQueryMutators::ShouldFallback(Node *node, SContextTLWalker *context)
{
	if (NULL == node)
	{
		return false;
	}

	if (IsA(node, Const) || IsA(node, Aggref) || IsA(node, GroupingFunc) ||
		IsA(node, SubLink))
	{
		return false;
	}

	TargetEntry *entry = gpdb::FindFirstMatchingMemberInTargetList(
		node, context->m_target_entries);
	if (NULL != entry && CTranslatorUtils::IsGroupingColumn(
							 (Node *) entry->expr, context->m_group_clause,
							 context->m_target_entries))
	{
		return false;
	}

	if (IsA(node, SubLink))
	{
		return false;
	}

	if (IsA(node, Var))
	{
		Var *var = (Var *) node;
		if (0 == var->varlevelsup)
		{
			// if we reach a Var that was not a grouping column then there is an equivalent column
			// which the algebrizer at this point cannot resolve
			// example: consider two table r(a,b) and s(c,d) and the following query
			// SELECT a from r LEFT JOIN s on (r.a = s.c) group by r.a
			// In the query object, generated by the parse, the output columns refer to the output of
			// the left outer join while the grouping column refers to the base table column.
			// While r.a and a are equivalent, the algebrizer at this point cannot detect this.
			// Therefore, we fall back.
			return true;
		}

		return false;
	}

	return gpdb::WalkExpressionTree(
		node, (ExprWalkerFn) CQueryMutators::ShouldFallback, context);
}


//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::NormalizeGroupByProjList
//
//	@doc:
// 		Flatten expressions in project list to contain only aggregates and
//		grouping columns
//		ORGINAL QUERY:
//			SELECT * from r where r.a > (SELECT max(c) + min(d) FROM t where r.b = t.e)
// 		NEW QUERY:
//			SELECT * from r where r.a > (SELECT x1+x2 as x3
//										 FROM (SELECT max(c) as x2, min(d) as x2
//											   FROM t where r.b = t.e) t2)
//---------------------------------------------------------------------------
Query *
CQueryMutators::NormalizeGroupByProjList(CMemoryPool *mp,
										 CMDAccessor *md_accessor,
										 const Query *query)
{
	Query *query_copy = (Query *) gpdb::CopyObject(const_cast<Query *>(query));

	FixGroupDependentTargets(query_copy);

	if (!NeedsProjListNormalization(query_copy))
	{
		return query_copy;
	}

	Query *new_query =
		ConvertToDerivedTable(query_copy, false /*should_fix_target_list*/,
							  true /*should_fix_having_qual*/);
	gpdb::GPDBFree(query_copy);

	GPOS_ASSERT(1 == gpdb::ListLength(new_query->rtable));
	Query *derived_table_query =
		(Query *) ((RangeTblEntry *) gpdb::ListNth(new_query->rtable, 0))
			->subquery;
	SContextGrpbyPlMutator context(mp, md_accessor, derived_table_query, NULL);
	List *target_list_copy =
		(List *) gpdb::CopyObject(derived_table_query->targetList);
	ListCell *lc = NULL;

	// first normalize grouping columns
	ForEach(lc, target_list_copy)
	{
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);
		GPOS_ASSERT(NULL != target_entry);

		if (CTranslatorUtils::IsGroupingColumn(
				target_entry, derived_table_query->groupClause))
		{
			target_entry->expr = (Expr *) FixGroupingCols(
				(Node *) target_entry->expr, target_entry, &context);
		}
	}

	lc = NULL;
	// normalize remaining project elements
	ForEach(lc, target_list_copy)
	{
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);
		GPOS_ASSERT(NULL != target_entry);

		BOOL is_grouping_col = CTranslatorUtils::IsGroupingColumn(
			target_entry, derived_table_query->groupClause);
		if (!is_grouping_col)
		{
			target_entry->expr = (Expr *) RunExtractAggregatesMutator(
				(Node *) target_entry->expr, &context);
			GPOS_ASSERT(!IsA(target_entry->expr, Aggref) &&
						!IsA(target_entry->expr, GroupingFunc) &&
						"New target list entry should not contain any Aggrefs");
		}
	}

	derived_table_query->targetList = context.m_lower_table_tlist;
	new_query->targetList = target_list_copy;

	ReassignSortClause(new_query, derived_table_query);

	return new_query;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::RunIncrLevelsUpMutator
//
//	@doc:
//		Increment any the query levels up of any outer reference by one
//---------------------------------------------------------------------------
Node *
CQueryMutators::RunIncrLevelsUpMutator(Node *node,
									   SContextIncLevelsupMutator *context)
{
	if (NULL == node)
	{
		return NULL;
	}

	if (IsA(node, Var))
	{
		Var *var = (Var *) gpdb::CopyObject(node);

		// Consider the following use case:
		//	ORGINAL QUERY:
		//		SELECT * from r where r.a > (SELECT max(c) + min(d)
		//									 FROM t where r.b = t.e)
		// NEW QUERY:
		//		SELECT * from r where r.a > (SELECT x1+x2 as x3
		//									 FROM (SELECT max(c) as x2, min(d) as x2
		//										   FROM t where r.b = t.e) t2)
		//
		// In such a scenario, we need increment the levels up for the
		// correlation variable r.b in the subquery by 1.

		if (var->varlevelsup > context->m_current_query_level)
		{
			var->varlevelsup++;
			return (Node *) var;
		}
		return (Node *) var;
	}

	if (IsA(node, TargetEntry) && 0 == context->m_current_query_level &&
		!context->m_should_fix_top_level_target_list)
	{
		return (Node *) gpdb::CopyObject(node);
	}

	// recurse into query structure
	if (IsA(node, Query))
	{
		context->m_current_query_level++;
		Query *query = query_tree_mutator(
			(Query *) node,
			(MutatorWalkerFn) CQueryMutators::RunIncrLevelsUpMutator, context,
			0  // flags
		);
		context->m_current_query_level--;

		return (Node *) query;
	}

	return expression_tree_mutator(
		node, (MutatorWalkerFn) CQueryMutators::RunIncrLevelsUpMutator,
		context);
}


//---------------------------------------------------------------------------
// CQueryMutators::RunFixCTELevelsUpWalker
//
// Increment CTE range table reference by one if it refers to
// an ancestor of the original Query node (level 0 in the context)
//---------------------------------------------------------------------------
BOOL
CQueryMutators::RunFixCTELevelsUpWalker(Node *node,
										SContextIncLevelsupMutator *context)
{
	if (NULL == node)
	{
		return false;
	}

	if (IsA(node, RangeTblEntry))
	{
		RangeTblEntry *rte = (RangeTblEntry *) node;
		if (RTE_CTE == rte->rtekind &&
			rte->ctelevelsup >= context->m_current_query_level)
		{
			// fix the levels up for CTE range table entry when needed
			// the walker in GPDB does not walk range table entries of type CTE
			rte->ctelevelsup++;
		}

		// always return false, as we want to continue fixing up RTEs
		return false;
	}

	// recurse into query structure, incrementing the query level
	if (IsA(node, Query))
	{
		context->m_current_query_level++;
		BOOL result = query_tree_walker(
			(Query *) node,
			(ExprWalkerFn) CQueryMutators::RunFixCTELevelsUpWalker, context,
			QTW_EXAMINE_RTES  // flags - visit RTEs
		);
		context->m_current_query_level--;

		return result;
	}

	if (IsA(node, TargetEntry) &&
		!context->m_should_fix_top_level_target_list &&
		0 == context->m_current_query_level)
	{
		// skip the top-level target list, if requested
		return false;
	}

	return expression_tree_walker(
		node, (ExprWalkerFn) CQueryMutators::RunFixCTELevelsUpWalker, context);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::RunGroupingColMutator
//
//	@doc:
// 		Mutate the grouping columns, fix levels up when necessary
//
//---------------------------------------------------------------------------
Node *
CQueryMutators::RunGroupingColMutator(Node *node,
									  SContextGrpbyPlMutator *context)
{
	if (NULL == node)
	{
		return NULL;
	}

	if (IsA(node, Const))
	{
		return (Node *) gpdb::CopyObject(node);
	}

	if (IsA(node, Var))
	{
		Var *var_copy = (Var *) gpdb::CopyObject(node);

		if (var_copy->varlevelsup > context->m_current_query_level)
		{
			var_copy->varlevelsup++;
		}

		return (Node *) var_copy;
	}

	if (IsA(node, Aggref))
	{
		// merely fix the arguments of an aggregate
		Aggref *old_aggref = (Aggref *) node;
		Aggref *aggref = FlatCopyAggref(old_aggref);
		aggref->agglevelsup = old_aggref->agglevelsup;

		List *new_args = NIL;
		ListCell *lc = NULL;

		BOOL is_agg = context->m_is_mutating_agg_arg;
		context->m_is_mutating_agg_arg = true;

		ForEach(lc, old_aggref->args)
		{
			Node *arg = (Node *) gpdb::CopyObject((Node *) lfirst(lc));
			GPOS_ASSERT(NULL != arg);
			// traverse each argument and fix levels up when needed
			new_args = gpdb::LAppend(
				new_args,
				gpdb::MutateQueryOrExpressionTree(
					arg,
					(MutatorWalkerFn) CQueryMutators::RunGroupingColMutator,
					(void *) context,
					0  // flags -- mutate into cte-lists
					));
		}
		context->m_is_mutating_agg_arg = is_agg;
		aggref->args = new_args;

		return (Node *) aggref;
	}

	if (IsA(node, GroupingFunc))
	{
		return (Node *) gpdb::CopyObject(node);
	}

	if (IsA(node, SubLink))
	{
		SubLink *old_sublink = (SubLink *) node;

		SubLink *new_sublink = MakeNode(SubLink);
		new_sublink->subLinkType = old_sublink->subLinkType;
		new_sublink->location = old_sublink->location;
		new_sublink->operName =
			(List *) gpdb::CopyObject(old_sublink->operName);

		new_sublink->testexpr = gpdb::MutateQueryOrExpressionTree(
			old_sublink->testexpr,
			(MutatorWalkerFn) CQueryMutators::RunGroupingColMutator,
			(void *) context,
			0  // flags -- mutate into cte-lists
		);
		context->m_current_query_level++;

		GPOS_ASSERT(IsA(old_sublink->subselect, Query));

		// One need to call the Query mutator for subselect and take into
		// account that SubLink can be multi-level. Therefore, the
		// context->m_current_query_level must be modified properly
		// while diving into such nested SubLink.
		new_sublink->subselect =
			RunGroupingColMutator(old_sublink->subselect, context);

		context->m_current_query_level--;

		return (Node *) new_sublink;
	}

	if (IsA(node, CommonTableExpr))
	{
		CommonTableExpr *cte = (CommonTableExpr *) gpdb::CopyObject(node);
		context->m_current_query_level++;

		GPOS_ASSERT(IsA(cte->ctequery, Query));

		cte->ctequery = gpdb::MutateQueryOrExpressionTree(
			cte->ctequery,
			(MutatorWalkerFn) CQueryMutators::RunGroupingColMutator,
			(void *) context,
			0  // flags --- mutate into cte-lists
		);

		context->m_current_query_level--;
		return (Node *) cte;
	}

	// recurse into query structure
	if (IsA(node, Query))
	{
		Query *query = gpdb::MutateQueryTree(
			(Query *) node,
			(MutatorWalkerFn) CQueryMutators::RunGroupingColMutator, context,
			1  // flag -- do not mutate range table entries
		);

		// fix the outer reference in derived table entries
		List *rtable = query->rtable;
		ListCell *lc = NULL;
		ForEach(lc, rtable)
		{
			RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);

			if (RTE_SUBQUERY == rte->rtekind)
			{
				Query *subquery = rte->subquery;
				// since we did not walk inside derived tables
				context->m_current_query_level++;
				rte->subquery =
					(Query *) RunGroupingColMutator((Node *) subquery, context);
				context->m_current_query_level--;
				gpdb::GPDBFree(subquery);
			}
		}

		return (Node *) query;
	}

	return gpdb::MutateExpressionTree(
		node, (MutatorWalkerFn) CQueryMutators::RunGroupingColMutator, context);
}


//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::FixGroupingCols
//
//	@doc:
// 		Mutate the grouping columns, fix levels up when necessary
//---------------------------------------------------------------------------
Node *
CQueryMutators::FixGroupingCols(Node *node, TargetEntry *orginal_target_entry,
								SContextGrpbyPlMutator *context)
{
	GPOS_ASSERT(NULL != node);

	ULONG arity = gpdb::ListLength(context->m_lower_table_tlist) + 1;

	// fix any outer references in the grouping column expression
	Node *expr = (Node *) RunGroupingColMutator(node, context);

	CHAR *name = CQueryMutators::GetTargetEntryColName(orginal_target_entry,
													   context->m_query);
	TargetEntry *new_target_entry = gpdb::MakeTargetEntry(
		(Expr *) expr, (AttrNumber) arity, name, false /*resjunk */);

	new_target_entry->ressortgroupref = orginal_target_entry->ressortgroupref;
	new_target_entry->resjunk = false;

	context->m_lower_table_tlist =
		gpdb::LAppend(context->m_lower_table_tlist, new_target_entry);

	Var *new_var = gpdb::MakeVar(
		1,	// varno
		(AttrNumber) arity, gpdb::ExprType((Node *) orginal_target_entry->expr),
		gpdb::ExprTypeMod((Node *) orginal_target_entry->expr),
		0  // query levelsup
	);

	return (Node *) new_var;
}


//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GetTargetEntryForAggExpr
//
//	@doc:
// 		Return a target entry for an aggregate expression
//---------------------------------------------------------------------------
TargetEntry *
CQueryMutators::GetTargetEntryForAggExpr(CMemoryPool *mp,
										 CMDAccessor *md_accessor, Node *node,
										 ULONG attno)
{
	GPOS_ASSERT(IsA(node, Aggref) || IsA(node, GroupingFunc));

	// get the function/aggregate name
	CHAR *name = NULL;
	if (IsA(node, GroupingFunc))
	{
		name = CTranslatorUtils::CreateMultiByteCharStringFromWCString(
			GPOS_WSZ_LIT("grouping"));
	}
	else
	{
		Aggref *aggref = (Aggref *) node;

		CMDIdGPDB *agg_mdid =
			GPOS_NEW(mp) CMDIdGPDB(IMDId::EmdidGeneral, aggref->aggfnoid);
		const IMDAggregate *md_agg = md_accessor->RetrieveAgg(agg_mdid);
		agg_mdid->Release();

		const CWStringConst *str = md_agg->Mdname().GetMDName();
		name = CTranslatorUtils::CreateMultiByteCharStringFromWCString(
			str->GetBuffer());
	}
	GPOS_ASSERT(NULL != name);

	return gpdb::MakeTargetEntry((Expr *) node, (AttrNumber) attno, name,
								 false);
}

// Traverse the entire tree under an arbitrarily complex project element (node)
// to extract all aggregate functions out into the derived query's target list
//
// This mutator should be called after creating a derived query (a subquery in
// the FROM clause), on each element in the old query's target list or qual to
// update any AggRef & Var to refer to the output from the derived query.
//
// See comments below & in the callers for specific use cases.
Node *
CQueryMutators::RunExtractAggregatesMutator(Node *node,
											SContextGrpbyPlMutator *context)
{
	if (NULL == node)
	{
		return NULL;
	}

	if (IsA(node, Const))
	{
		return (Node *) gpdb::CopyObject(node);
	}

	if (IsA(node, Aggref))
	{
		Aggref *old_aggref = (Aggref *) node;

		// If the agglevelsup matches the current query level, this Aggref only
		// uses vars from the top level query. This needs to be moved to the
		// derived query, and the entire AggRef replaced with a Var referencing the
		// derived table's target list.
		if (old_aggref->agglevelsup == context->m_current_query_level)
		{
			Aggref *new_aggref = FlatCopyAggref(old_aggref);

			BOOL is_agg_old = context->m_is_mutating_agg_arg;
			ULONG agg_levels_up = context->m_agg_levels_up;

			context->m_is_mutating_agg_arg = true;
			context->m_agg_levels_up = old_aggref->agglevelsup;

			List *new_args = NIL;
			ListCell *lc = NULL;

			ForEach(lc, old_aggref->args)
			{
				Node *arg = (Node *) lfirst(lc);
				GPOS_ASSERT(NULL != arg);
				// traverse each argument and fix levels up when needed
				new_args = gpdb::LAppend(
					new_args,
					gpdb::MutateQueryOrExpressionTree(
						arg, (MutatorWalkerFn) RunExtractAggregatesMutator,
						(void *) context,
						0  // mutate into cte-lists
						));
			}
			new_aggref->args = new_args;
			context->m_is_mutating_agg_arg = is_agg_old;
			context->m_agg_levels_up = agg_levels_up;

			// create a new entry in the derived table and return its corresponding var
			return (Node *) MakeVarInDerivedTable((Node *) new_aggref, context);
		}
	}

	if (0 == context->m_current_query_level)
	{
		if (IsA(node, Var) && context->m_is_mutating_agg_arg)
		{
			// This mutator may be run on a nested query object with aggregates on
			// outer references. It pulls out any aggregates and moves it into the
			// derived query (which is subquery), in effect, increasing the levels up
			// any Var in the aggregate must now reference
			//
			// e.g SELECT (SELECT sum(o.o) + 1 FROM i GRP BY i.i) FROM o;
			// becomes SELECT (SELECT x + 1 FROM (SELECT sum(o.o) GRP BY i.i)) FROM o;
			// which means Var::varlevelup must be increased for o.o
			return (Node *) IncrLevelsUpIfOuterRef((Var *) node);
		}

		if (IsA(node, GroupingFunc))
		{
			// create a new entry in the derived table and return its corresponding var
			Node *node_copy = (Node *) gpdb::CopyObject(node);
			return (Node *) MakeVarInDerivedTable(node_copy, context);
		}

		if (!context->m_is_mutating_agg_arg)
		{
			// check if an entry already exists, if so no need for duplicate
			Node *found_node = FindNodeInGroupByTargetList(node, context);
			if (NULL != found_node)
			{
				return found_node;
			}
		}
	}

	if (IsA(node, Var))
	{
		Var *var = (Var *) gpdb::CopyObject(node);

		// Handle other top-level outer references in the project element.
		if (var->varlevelsup == context->m_current_query_level)
		{
			if (var->varlevelsup >= context->m_agg_levels_up)
			{
				// If Var references the top level query (varlevelsup = m_current_query_level)
				// inside an Aggref that also references top level query, the Aggref is moved
				// to the derived query (see comments in Aggref if-case above).
				// And, therefore, if we are mutating such Vars inside the Aggref, we must
				// change their varlevelsup field in order to preserve correct reference level.
				// i.e these Vars are pulled up as the part of the Aggref by the m_agg_levels_up.
				// e.g:
				// select (select max((select foo.a))) from foo;
				// is transformed into
				// select (select fnew.max_t)
				// from (select max((select foo.a)) max_t from foo) fnew;
				// Here the foo.a inside max referenced top level RTE foo at
				// varlevelsup = 2 inside the Aggref at agglevelsup 1. Then the
				// Aggref is brought up to the top-query-level of fnew and foo.a
				// inside Aggref is bumped up by original Aggref's level.
				// We may visualize that logic with the following diagram:
				// Query <------┐  <--------------------┐
				//              |                       |
				//              | m_agg_levels_up = 1   |
				//              |                       |
				//     Aggref --┘                       | varlevelsup = 2
				//                                      |
				//                                      |
				//                                      |
				//         Var -------------------------┘
				var->varlevelsup -= context->m_agg_levels_up;
				return (Node *) var;
			}

			// Skip vars inside Aggrefs, since they have already been fixed when they
			// were moved into the derived query in ConvertToDerivedTable(), and thus,
			// the relative varno, varattno & varlevelsup should still be valid.
			// e.g:
			// SELECT foo.b+1, avg(( SELECT bar.f FROM bar
			//                       WHERE bar.d = foo.b)) AS t
			// FROM foo GROUP BY foo.b;
			// is transformed into
			// SELECT fnew.b+1, fnew.avg_t
			// FROM (SELECT foo.b,`avg(( SELECT bar.f FROM bar
			//                           WHERE bar.d = foo.b)) AS t
			//       FROM foo) fnew;
			//
			// Note the foo.b outerref in subquery inside the avg() aggregation.
			// Because it is inside the aggregation, it was pushed down along with
			// the aggregate function, and thus does not need to be fixed.
			if (context->m_is_mutating_agg_arg)
			{
				return (Node *) var;
			}

			// For other top-level references, correct their varno & varattno, since
			// they now must refer to the target list of the derived query - whose
			// target list may be different from the original query.

			// Set varlevelsup to 0 temporarily while searching in the target list
			var->varlevelsup = 0;
			TargetEntry *found_tle = gpdb::FindFirstMatchingMemberInTargetList(
				(Node *) var, context->m_lower_table_tlist);

			if (NULL == found_tle)
			{
				// Consider two table r(a,b) and s(c,d) and the following query
				// SELECT 1 from r LEFT JOIN s on (r.a = s.c) group by r.a having count(*) > a
				// The having clause refers to the output of the left outer join while the
				// grouping column refers to the base table column.
				// While r.a and a are equivalent, the algebrizer at this point cannot detect this.
				// Therefore, found_target_entry will be NULL and we fall back.

				// TODO: Oct 14 2013, remove temporary fix (revert exception to assert) to avoid crash during algebrization
				GPOS_RAISE(gpdxl::ExmaDXL, gpdxl::ExmiQuery2DXLError,
						   GPOS_WSZ_LIT("No attribute"));
				return NULL;
			}

			var->varno =
				1;	// derived query is the only table in FROM expression
			var->varattno = found_tle->resno;
			var->varlevelsup =
				context->m_current_query_level;	 // reset varlevels up
			found_tle->resjunk = false;

			return (Node *) var;
		}
		return (Node *) var;
	}

	if (IsA(node, CommonTableExpr))
	{
		CommonTableExpr *cte = (CommonTableExpr *) gpdb::CopyObject(node);
		context->m_current_query_level++;

		GPOS_ASSERT(IsA(cte->ctequery, Query));

		cte->ctequery = gpdb::MutateQueryOrExpressionTree(
			cte->ctequery, (MutatorWalkerFn) RunExtractAggregatesMutator,
			(void *) context,
			0  // mutate into cte-lists
		);

		context->m_current_query_level--;
		return (Node *) cte;
	}

	if (IsA(node, SubLink))
	{
		SubLink *old_sublink = (SubLink *) node;

		SubLink *new_sublink = MakeNode(SubLink);
		new_sublink->subLinkType = old_sublink->subLinkType;
		new_sublink->location = old_sublink->location;
		new_sublink->operName =
			(List *) gpdb::CopyObject(old_sublink->operName);

		new_sublink->testexpr = gpdb::MutateQueryOrExpressionTree(
			old_sublink->testexpr,
			(MutatorWalkerFn) RunExtractAggregatesMutator, (void *) context,
			0  // mutate into cte-lists
		);
		context->m_current_query_level++;

		GPOS_ASSERT(IsA(old_sublink->subselect, Query));

		// One need to call the Query mutator for subselect and take into
		// account that SubLink can be multi-level. Therefore, the
		// context->m_current_query_level must be modified properly
		// while diving into such nested SubLink.
		new_sublink->subselect =
			RunExtractAggregatesMutator(old_sublink->subselect, context);

		context->m_current_query_level--;

		return (Node *) new_sublink;
	}

	if (IsA(node, Query))
	{
		// Mutate Query tree and ignore rtable subqueries in order to modify
		// m_current_query_level properly when mutating them below.
		Query *query = gpdb::MutateQueryTree(
			(Query *) node, (MutatorWalkerFn) RunExtractAggregatesMutator,
			context, QTW_IGNORE_RT_SUBQUERIES);

		ListCell *lc;
		ForEach(lc, query->rtable)
		{
			RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);

			if (RTE_SUBQUERY == rte->rtekind)
			{
				Query *subquery = rte->subquery;
				context->m_current_query_level++;
				rte->subquery = (Query *) RunExtractAggregatesMutator(
					(Node *) subquery, context);
				context->m_current_query_level--;
				gpdb::GPDBFree(subquery);
			}
		}

		return (Node *) query;
	}

	return gpdb::MutateExpressionTree(
		node, (MutatorWalkerFn) RunExtractAggregatesMutator, context);
}


// Create a new entry in the derived table and return its corresponding var
Var *
CQueryMutators::MakeVarInDerivedTable(Node *node,
									  SContextGrpbyPlMutator *context)
{
	GPOS_ASSERT(NULL != node);
	GPOS_ASSERT(NULL != context);
	GPOS_ASSERT(IsA(node, Aggref) || IsA(node, GroupingFunc) || IsA(node, Var));

	// Append a new target entry for the node to the derived target list ...
	const ULONG attno = gpdb::ListLength(context->m_lower_table_tlist) + 1;
	TargetEntry *tle = NULL;
	if (IsA(node, Aggref) || IsA(node, GroupingFunc))
		tle = GetTargetEntryForAggExpr(context->m_mp, context->m_mda, node,
									   attno);
	else if (IsA(node, Var))
		tle = gpdb::MakeTargetEntry((Expr *) node, (AttrNumber) attno, NULL,
									false);

	context->m_lower_table_tlist =
		gpdb::LAppend(context->m_lower_table_tlist, tle);

	// ... and return a Var referring to it in its stead
	// NB: Since the new tle is appended at the top query level, Var::varlevelsup
	// should equal the current nested level. This will take care of any outer references
	// to the original tlist.
	Var *new_var =
		gpdb::MakeVar(1 /* varno */, attno, gpdb::ExprType((Node *) node),
					  gpdb::ExprTypeMod((Node *) node),
					  context->m_current_query_level /* varlevelsup */);

	return new_var;
}


// Check if a matching entry already exists in the list of target
// entries, if yes return its corresponding var, otherwise return NULL
Node *
CQueryMutators::FindNodeInGroupByTargetList(Node *node,
											SContextGrpbyPlMutator *context)
{
	GPOS_ASSERT(NULL != node);
	GPOS_ASSERT(NULL != context);

	TargetEntry *found_tle = gpdb::FindFirstMatchingMemberInTargetList(
		node, context->m_lower_table_tlist);

	if (NULL != found_tle)
	{
		gpdb::GPDBFree(node);
		// NB: Var::varlevelsup is set to the current query level since the created
		// Var must reference the group by targetlist at the top level.
		Var *new_var =
			gpdb::MakeVar(1 /* varno */, found_tle->resno,
						  gpdb::ExprType((Node *) found_tle->expr),
						  gpdb::ExprTypeMod((Node *) found_tle->expr),
						  context->m_current_query_level /* varlevelsup */);

		found_tle->resjunk = false;
		return (Node *) new_var;
	}

	return NULL;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::FlatCopyAggref
//
//	@doc:
//		Make a copy of the aggref (minus the arguments)
//---------------------------------------------------------------------------
Aggref *
CQueryMutators::FlatCopyAggref(Aggref *old_aggref)
{
	Aggref *new_aggref = MakeNode(Aggref);

	*new_aggref = *old_aggref;

	new_aggref->agglevelsup = 0;
	// This is not strictly necessary: we seem to ALWAYS assgin to args from
	// the callers
	// Explicitly setting this both to be safe and to be clear that we are
	// intentionally NOT copying the args
	new_aggref->args = NIL;

	return new_aggref;
}

// Increment the levels up of outer references
Var *
CQueryMutators::IncrLevelsUpIfOuterRef(Var *var)
{
	GPOS_ASSERT(NULL != var);

	Var *var_copy = (Var *) gpdb::CopyObject(var);
	if (0 != var_copy->varlevelsup)
	{
		var_copy->varlevelsup++;
	}

	return var_copy;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::NormalizeHaving
//
//	@doc:
//		Pull up having qual into a select and fix correlated references
//		to the top-level query
//---------------------------------------------------------------------------
Query *
CQueryMutators::NormalizeHaving(CMemoryPool *mp, CMDAccessor *md_accessor,
								const Query *query)
{
	Query *query_copy = (Query *) gpdb::CopyObject(const_cast<Query *>(query));

	if (NULL == query->havingQual)
	{
		return query_copy;
	}

	Query *new_query =
		ConvertToDerivedTable(query_copy, true /*should_fix_target_list*/,
							  false /*should_fix_having_qual*/);
	gpdb::GPDBFree(query_copy);

	RangeTblEntry *rte =
		((RangeTblEntry *) gpdb::ListNth(new_query->rtable, 0));
	Query *derived_table_query = (Query *) rte->subquery;

	// Add all necessary target list entries of subquery
	// into the target list of the RTE as well as the new top most query
	ListCell *lc = NULL;
	ULONG num_target_entries = 1;
	ForEach(lc, derived_table_query->targetList)
	{
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);
		GPOS_ASSERT(NULL != target_entry);

		// Add to the target lists:
		// 	(1) All grouping / sorting columns even if they do not appear in the subquery output (resjunked)
		//	(2) All non-resjunked target list entries
		if (CTranslatorUtils::IsGroupingColumn(
				target_entry, derived_table_query->groupClause) ||
			CTranslatorUtils::IsSortingColumn(
				target_entry, derived_table_query->sortClause) ||
			!target_entry->resjunk)
		{
			TargetEntry *new_target_entry =
				MakeTopLevelTargetEntry(target_entry, num_target_entries);
			new_query->targetList =
				gpdb::LAppend(new_query->targetList, new_target_entry);
			// Ensure that such target entries is not suppressed in the target list of the RTE
			// and has a name
			target_entry->resname =
				GetTargetEntryColName(target_entry, derived_table_query);
			target_entry->resjunk = false;
			new_target_entry->ressortgroupref = target_entry->ressortgroupref;

			num_target_entries++;
		}
	}

	SContextGrpbyPlMutator context(mp, md_accessor, derived_table_query,
								   derived_table_query->targetList);

	// fix outer references in the qual
	new_query->jointree->quals =
		RunExtractAggregatesMutator(derived_table_query->havingQual, &context);
	derived_table_query->havingQual = NULL;

	ReassignSortClause(new_query, rte->subquery);

	if (!rte->subquery->hasAggs && NIL == rte->subquery->groupClause)
	{
		// if the derived table has no grouping columns or aggregates then the
		// subquery is equivalent to select XXXX FROM CONST-TABLE
		// (where XXXX is the original subquery's target list)

		Query *new_subquery = MakeNode(Query);

		new_subquery->commandType = CMD_SELECT;
		new_subquery->targetList = NIL;

		new_subquery->hasAggs = false;
		new_subquery->hasWindowFuncs = false;
		new_subquery->hasSubLinks = false;

		ListCell *lc = NULL;
		ForEach(lc, rte->subquery->targetList)
		{
			TargetEntry *target_entry = (TargetEntry *) lfirst(lc);
			GPOS_ASSERT(NULL != target_entry);

			GPOS_ASSERT(!target_entry->resjunk);

			new_subquery->targetList =
				gpdb::LAppend(new_subquery->targetList,
							  (TargetEntry *) gpdb::CopyObject(
								  const_cast<TargetEntry *>(target_entry)));
		}

		gpdb::GPDBFree(rte->subquery);

		rte->subquery = new_subquery;
		rte->subquery->jointree = MakeNode(FromExpr);
		rte->subquery->groupClause = NIL;
		rte->subquery->sortClause = NIL;
		rte->subquery->windowClause = NIL;
	}

	return new_query;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::NormalizeQuery
//
//	@doc:
//		Normalize queries with having and group by clauses
//---------------------------------------------------------------------------
Query *
CQueryMutators::NormalizeQuery(CMemoryPool *mp, CMDAccessor *md_accessor,
							   const Query *query, ULONG query_level)
{
	// flatten join alias vars defined at the current level of the query
	Query *pqueryResolveJoinVarReferences =
		gpdb::FlattenJoinAliasVar(const_cast<Query *>(query), query_level);

	// eliminate distinct clause
	Query *pqueryEliminateDistinct =
		CQueryMutators::EliminateDistinctClause(pqueryResolveJoinVarReferences);
	GPOS_ASSERT(NULL == pqueryEliminateDistinct->distinctClause);
	gpdb::GPDBFree(pqueryResolveJoinVarReferences);

	// normalize window operator's project list
	Query *pqueryWindowPlNormalized = CQueryMutators::NormalizeWindowProjList(
		mp, md_accessor, pqueryEliminateDistinct);
	gpdb::GPDBFree(pqueryEliminateDistinct);

	// pull-up having quals into a select
	Query *pqueryHavingNormalized = CQueryMutators::NormalizeHaving(
		mp, md_accessor, pqueryWindowPlNormalized);
	GPOS_ASSERT(NULL == pqueryHavingNormalized->havingQual);
	gpdb::GPDBFree(pqueryWindowPlNormalized);

	// normalize the group by project list
	Query *new_query = CQueryMutators::NormalizeGroupByProjList(
		mp, md_accessor, pqueryHavingNormalized);
	gpdb::GPDBFree(pqueryHavingNormalized);

	return new_query;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GetTargetEntry
//
//	@doc:
//		Given an Target list entry in the derived table, create a new
//		TargetEntry to be added to the top level query. This function allocates
//		memory
//---------------------------------------------------------------------------
TargetEntry *
CQueryMutators::MakeTopLevelTargetEntry(TargetEntry *old_target_entry,
										ULONG attno)
{
	Var *new_var = gpdb::MakeVar(
		1, (AttrNumber) attno, gpdb::ExprType((Node *) old_target_entry->expr),
		gpdb::ExprTypeMod((Node *) old_target_entry->expr),
		0  // query levelsup
	);

	TargetEntry *new_target_entry = gpdb::MakeTargetEntry(
		(Expr *) new_var, (AttrNumber) attno, old_target_entry->resname,
		old_target_entry->resjunk);

	return new_target_entry;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::GetTargetEntryColName
//
//	@doc:
//		Return the column name of the target list entry
//---------------------------------------------------------------------------
CHAR *
CQueryMutators::GetTargetEntryColName(TargetEntry *target_entry, Query *query)
{
	if (NULL != target_entry->resname)
	{
		return target_entry->resname;
	}

	// Since a resjunked target list entry will not have a column name create a dummy column name
	CWStringConst dummy_colname(GPOS_WSZ_LIT("?column?"));

	return CTranslatorUtils::CreateMultiByteCharStringFromWCString(
		dummy_colname.GetBuffer());
}

//---------------------------------------------------------------------------
// CQueryMutators::ConvertToDerivedTable
//
// Convert "original_query" into two nested Query structs
// and return the new upper query.
//
//                              upper_query
//    original_query    ===>        |
//                              lower_query
//
// - The result lower Query has:
//    * The original rtable, join tree, groupClause, WindowClause, etc.,
//      with modified varlevelsup and ctelevelsup fields, as needed
//    * The original targetList, either modified or unmodified,
//      depending on should_fix_target_list
//    * The original havingQual, either modified or unmodified,
//      depending on should_fix_having_qual
//
// - The result upper Query has:
//    * a single RTE, pointing to the lower query
//    * the CTE list of the original query
//      (CTE levels in original have been fixed up)
//    * an empty target list
//
//---------------------------------------------------------------------------
Query *
CQueryMutators::ConvertToDerivedTable(const Query *original_query,
									  BOOL should_fix_target_list,
									  BOOL should_fix_having_qual)
{
	// Step 1: Make a copy of the original Query, this will become the lower query

	Query *query_copy =
		(Query *) gpdb::CopyObject(const_cast<Query *>(original_query));

	// Step 2: Remove things from the query copy that will go in the new, upper Query object
	//         or won't be modified

	Node *having_qual = NULL;
	if (!should_fix_having_qual)
	{
		having_qual = query_copy->havingQual;
		query_copy->havingQual = NULL;
	}

	List *original_cte_list = query_copy->cteList;
	query_copy->cteList = NIL;

	// intoPolicy, if not null, must be set on the top query, not on the derived table
	struct GpPolicy *into_policy = query_copy->intoPolicy;
	query_copy->intoPolicy = NULL;

	// Step 3: fix outer references and CTE levels

	// increment varlevelsup in the lower query where they point to a Query
	// that is an ancestor of the original query
	Query *lower_query;
	{
		SContextIncLevelsupMutator context1(0, should_fix_target_list);

		lower_query = gpdb::MutateQueryTree(
			query_copy, (MutatorWalkerFn) RunIncrLevelsUpMutator, &context1,
			0  // flags
		);
	}

	// fix the CTE levels up -- while the old query is converted into a derived table, its cte list
	// is re-assigned to the new top-level query. The references to the ctes listed in the old query
	// as well as those listed before the current query level are accordingly adjusted in the new
	// derived table.
	{
		SContextIncLevelsupMutator context2(0 /*starting level */,
											should_fix_target_list);

		(void) gpdb::WalkQueryOrExpressionTree(
			(Node *) lower_query, (ExprWalkerFn) RunFixCTELevelsUpWalker,
			&context2, QTW_EXAMINE_RTES);
	}

	if (NULL != having_qual)
	{
		lower_query->havingQual = having_qual;
	}

	// Step 4: Create a new, single range table entry for the upper query

	RangeTblEntry *rte = MakeNode(RangeTblEntry);
	rte->rtekind = RTE_SUBQUERY;

	rte->subquery = lower_query;
	rte->inFromCl = true;
	rte->subquery->cteList = NIL;

	// create a new range table reference for the new RTE
	RangeTblRef *rtref = MakeNode(RangeTblRef);
	rtref->rtindex = 1;

	// Step 5: Create a new upper query with the new RTE in its from clause

	Query *upper_query = MakeNode(Query);

	upper_query->cteList = original_cte_list;
	upper_query->rtable = gpdb::LAppend(upper_query->rtable, rte);
	upper_query->intoPolicy = into_policy;
	upper_query->parentStmtType = lower_query->parentStmtType;
	lower_query->parentStmtType = PARENTSTMTTYPE_NONE;

	FromExpr *fromexpr = MakeNode(FromExpr);
	fromexpr->quals = NULL;
	fromexpr->fromlist = gpdb::LAppend(fromexpr->fromlist, rtref);

	upper_query->jointree = fromexpr;
	upper_query->commandType = CMD_SELECT;

	GPOS_ASSERT(1 == gpdb::ListLength(upper_query->rtable));
	GPOS_ASSERT(false == upper_query->hasWindowFuncs);

	return upper_query;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::EliminateDistinctClause
//
//	@doc:
//		Eliminate distinct columns by translating it into a grouping columns
//---------------------------------------------------------------------------
Query *
CQueryMutators::EliminateDistinctClause(const Query *query)
{
	if (0 == gpdb::ListLength(query->distinctClause))
	{
		return (Query *) gpdb::CopyObject(const_cast<Query *>(query));
	}

	// create a derived table out of the previous query
	Query *new_query =
		ConvertToDerivedTable(query, true /*should_fix_target_list*/,
							  true /*should_fix_having_qual*/);

	GPOS_ASSERT(1 == gpdb::ListLength(new_query->rtable));
	Query *derived_table_query =
		(Query *) ((RangeTblEntry *) gpdb::ListNth(new_query->rtable, 0))
			->subquery;

	ReassignSortClause(new_query, derived_table_query);

	new_query->targetList = NIL;
	List *target_entries = derived_table_query->targetList;
	ListCell *lc = NULL;

	// build the project list of the new top-level query
	ForEach(lc, target_entries)
	{
		ULONG resno = gpdb::ListLength(new_query->targetList) + 1;
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);
		GPOS_ASSERT(NULL != target_entry);

		if (!target_entry->resjunk)
		{
			// create a new target entry that points to the corresponding entry in the derived table
			Var *new_var =
				gpdb::MakeVar(1, target_entry->resno,
							  gpdb::ExprType((Node *) target_entry->expr),
							  gpdb::ExprTypeMod((Node *) target_entry->expr),
							  0	 // query levels up
				);
			TargetEntry *new_target_entry =
				gpdb::MakeTargetEntry((Expr *) new_var, (AttrNumber) resno,
									  target_entry->resname, false);

			new_target_entry->ressortgroupref = target_entry->ressortgroupref;
			new_query->targetList =
				gpdb::LAppend(new_query->targetList, new_target_entry);
		}

		if (0 < target_entry->ressortgroupref &&
			!CTranslatorUtils::IsGroupingColumn(
				target_entry, derived_table_query->groupClause) &&
			!CTranslatorUtils::IsReferencedInWindowSpec(
				target_entry, derived_table_query->windowClause))
		{
			// initialize the ressortgroupref of target entries not used in the grouping clause
			target_entry->ressortgroupref = 0;
		}
	}

	if (gpdb::ListLength(new_query->targetList) !=
		gpdb::ListLength(query->distinctClause))
	{
		GPOS_RAISE(
			gpdxl::ExmaDXL, gpdxl::ExmiQuery2DXLUnsupportedFeature,
			GPOS_WSZ_LIT(
				"DISTINCT operation on a subset of target list columns"));
	}

	ListCell *pl = NULL;
	ForEach(pl, query->distinctClause)
	{
		SortGroupClause *sort_group_clause = (SortGroupClause *) lfirst(pl);
		GPOS_ASSERT(NULL != sort_group_clause);

		SortGroupClause *new_sort_group_clause = MakeNode(SortGroupClause);
		new_sort_group_clause->tleSortGroupRef =
			sort_group_clause->tleSortGroupRef;
		new_sort_group_clause->eqop = sort_group_clause->eqop;
		new_sort_group_clause->sortop = sort_group_clause->sortop;
		new_sort_group_clause->nulls_first = sort_group_clause->nulls_first;
		new_query->groupClause =
			gpdb::LAppend(new_query->groupClause, new_sort_group_clause);
	}
	new_query->distinctClause = NIL;
	derived_table_query->distinctClause = NIL;

	return new_query;
}

//---------------------------------------------------------------------------
// CQueryMutators::NeedsProjListWindowNormalization
//
// Check whether the window operator's project list only contains
// window functions, vars, or expressions used in the window specification.
// Examples of queries that will be normalized:
//   select rank() over(...) -1
//   select rank() over(order by a), a+b
//   select (SQ), rank over(...)
// Some of these, e.g. the second one, may not strictly need normalization.
//---------------------------------------------------------------------------
BOOL
CQueryMutators::NeedsProjListWindowNormalization(const Query *query)
{
	if (!query->hasWindowFuncs)
	{
		return false;
	}

	ListCell *lc = NULL;
	ForEach(lc, query->targetList)
	{
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);

		if (!CTranslatorUtils::IsReferencedInWindowSpec(target_entry,
														query->windowClause) &&
			!IsA(target_entry->expr, WindowFunc) &&
			!IsA(target_entry->expr, Var))
		{
			// computed columns in the target list that is not
			// used in the order by or partition by of the window specification(s)
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------
//  CQueryMutators::NormalizeWindowProjList
//
//  Flatten expressions in project list to contain only window functions,
//  columns (vars) and columns (vars) used in the window specifications.
//  This is a restriction in Orca and DXL, that we don't support a mix of
//  window functions and general expressions in a target list.
//
//  ORGINAL QUERY:
//    SELECT row_number() over() + rank() over(partition by a+b order by a-b) from foo
//
//  NEW QUERY:
//    SELECT rn+rk from (SELECT row_number() over() as rn, rank() over(partition by a+b order by a-b) as rk FROM foo) foo_new
//---------------------------------------------------------------------------
Query *
CQueryMutators::NormalizeWindowProjList(CMemoryPool *mp,
										CMDAccessor *md_accessor,
										const Query *original_query)
{
	Query *query_copy =
		(Query *) gpdb::CopyObject(const_cast<Query *>(original_query));

	if (!NeedsProjListWindowNormalization(original_query))
	{
		return query_copy;
	}

	// we assume here that we have already performed the transformGroupedWindows()
	// transformation, which separates GROUP BY from window functions
	GPOS_ASSERT(NULL == original_query->distinctClause);
	GPOS_ASSERT(NULL == original_query->groupClause);

	// we do not fix target list of the derived table since we will be mutating it below
	// to ensure that it does not have window functions
	Query *upper_query =
		ConvertToDerivedTable(query_copy, false /*should_fix_target_list*/,
							  true /*should_fix_having_qual*/);
	gpdb::GPDBFree(query_copy);

	GPOS_ASSERT(1 == gpdb::ListLength(upper_query->rtable));
	Query *lower_query =
		(Query *) ((RangeTblEntry *) gpdb::ListNth(upper_query->rtable, 0))
			->subquery;

	SContextGrpbyPlMutator projlist_context(mp, md_accessor, lower_query, NULL);
	ListCell *lc = NULL;
	List *target_entries = lower_query->targetList;
	ForEach(lc, target_entries)
	{
		// If this target entry is referenced in a window spec, is a var or is a window function,
		// add it to the lower target list. Adjust the outer refs to ancestors of the orginal
		// query by adding one to the varlevelsup. Add a var to the upper target list to refer
		// to it.
		//
		// Any other target entries, add them to the upper target list, and ensure that any vars
		// they reference in the current scope are produced by the lower query and are adjusted
		// to refer to the new, single RTE of the upper query.
		TargetEntry *target_entry = (TargetEntry *) lfirst(lc);
		const ULONG ulResNoNew = gpdb::ListLength(upper_query->targetList) + 1;

		if (CTranslatorUtils::IsReferencedInWindowSpec(
				target_entry, original_query->windowClause))
		{
			// This entry is used in a window spec. Since this clause refers to its argument by
			// ressortgroupref, the target entry must be preserved in the lower target list,
			// so insert the entire Expr of the TargetEntry into the lower target list, using the
			// same ressortgroupref and also preserving the resjunk attribute.
			SContextIncLevelsupMutator level_context(
				0, true /* should_fix_top_level_target_list */);
			TargetEntry *lower_target_entry =
				(TargetEntry *) gpdb::MutateExpressionTree(
					(Node *) target_entry,
					(MutatorWalkerFn) RunIncrLevelsUpMutator, &level_context);

			lower_target_entry->resno =
				gpdb::ListLength(projlist_context.m_lower_table_tlist) + 1;
			projlist_context.m_lower_table_tlist = gpdb::LAppend(
				projlist_context.m_lower_table_tlist, lower_target_entry);

			BOOL is_sorting_col = CTranslatorUtils::IsSortingColumn(
				target_entry, original_query->sortClause);

			if (!target_entry->resjunk || is_sorting_col)
			{
				// the target list entry is present in the query output or it is used in the ORDER BY,
				// so also add it to the target list of the new upper Query
				Var *new_var = gpdb::MakeVar(
					1, lower_target_entry->resno,
					gpdb::ExprType((Node *) target_entry->expr),
					gpdb::ExprTypeMod((Node *) target_entry->expr),
					0  // query levels up
				);
				TargetEntry *upper_target_entry = gpdb::MakeTargetEntry(
					(Expr *) new_var, ulResNoNew, target_entry->resname,
					target_entry->resjunk);

				if (is_sorting_col)
				{
					// This target list entry is referenced in the ORDER BY as well, evaluated in the upper
					// query. Set the ressortgroupref, keeping the same number as in the original query.
					upper_target_entry->ressortgroupref =
						lower_target_entry->ressortgroupref;
				}
				// Set target list entry of the derived table to be non-resjunked, since we need it in the upper
				lower_target_entry->resjunk = false;

				upper_query->targetList =
					gpdb::LAppend(upper_query->targetList, upper_target_entry);
			}
		}
		else
		{
			// push any window functions in the target entry into the lower target list
			// and also add any needed vars to the lower target list
			target_entry->resno = ulResNoNew;
			TargetEntry *upper_target_entry =
				(TargetEntry *) gpdb::MutateExpressionTree(
					(Node *) target_entry,
					(MutatorWalkerFn) RunWindowProjListMutator,
					&projlist_context);
			upper_query->targetList =
				gpdb::LAppend(upper_query->targetList, upper_target_entry);
		}
	}

	// once we finish the above loop, the context has accumulated all the needed vars,
	// window spec expressions and window functions for the lower targer list
	lower_query->targetList = projlist_context.m_lower_table_tlist;

	GPOS_ASSERT(gpdb::ListLength(upper_query->targetList) <=
				gpdb::ListLength(original_query->targetList));
	ReassignSortClause(upper_query, lower_query);

	return upper_query;
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::RunWindowProjListMutator
//
//	@doc:
// 		Traverse the project list of extract all window functions in an
//		arbitrarily complex project element
//---------------------------------------------------------------------------
Node *
CQueryMutators::RunWindowProjListMutator(Node *node,
										 SContextGrpbyPlMutator *context)
{
	if (NULL == node)
	{
		return NULL;
	}

	const ULONG resno = gpdb::ListLength(context->m_lower_table_tlist) + 1;

	if (IsA(node, WindowFunc) && 0 == context->m_current_query_level)
	{
		// This is a window function that needs to be executed in the lower Query.

		// Insert window function as a new TargetEntry into the lower target list
		// (requires incrementing varlevelsup on its arguments).
		// Create a var that refers to the newly created lower TargetEntry and return
		// that, to be used instead of the window function in the upper TargetEntry.

		// make a copy of the tree and increment varlevelsup, using a different mutator
		SContextIncLevelsupMutator levelsUpContext(
			context->m_current_query_level,
			true /* should_fix_top_level_target_list */);
		WindowFunc *window_func = (WindowFunc *) expression_tree_mutator(
			node, (MutatorWalkerFn) RunIncrLevelsUpMutator, &levelsUpContext);
		GPOS_ASSERT(IsA(window_func, WindowFunc));

		// get the function name and create a new target entry for window_func
		CMDIdGPDB *mdid_func = GPOS_NEW(context->m_mp)
			CMDIdGPDB(IMDId::EmdidGeneral, window_func->winfnoid);
		const CWStringConst *str =
			CMDAccessorUtils::PstrWindowFuncName(context->m_mda, mdid_func);
		mdid_func->Release();

		TargetEntry *target_entry = gpdb::MakeTargetEntry(
			(Expr *) window_func, (AttrNumber) resno,
			CTranslatorUtils::CreateMultiByteCharStringFromWCString(
				str->GetBuffer()),
			false /* resjunk */
		);
		context->m_lower_table_tlist =
			gpdb::LAppend(context->m_lower_table_tlist, target_entry);

		// return a variable referring to the lower table's corresponding target entry,
		// to be used somewhere in the upper query's target list
		Var *new_var = gpdb::MakeVar(
			1,	// derived query which is now the only table in FROM expression
			(AttrNumber) resno, gpdb::ExprType(node), gpdb::ExprTypeMod(node),
			0  // query levelsup
		);

		return (Node *) new_var;
	}

	if (IsA(node, Var) &&
		((Var *) node)->varlevelsup == context->m_current_query_level)
	{
		// This is a Var referencing the original query scope. It now needs to reference
		// the new upper query scope.
		// Since the rtable of the upper Query is different from that of the original
		// Query, calculate the new varno (always 1) and varattno to use.
		Var *var = (Var *) gpdb::CopyObject(node);

		// Set varlevelsup to 0 temporarily while searching in the target list
		var->varlevelsup = 0;
		TargetEntry *found_tle = gpdb::FindFirstMatchingMemberInTargetList(
			(Node *) var, context->m_lower_table_tlist);

		if (NULL == found_tle)
		{
			// this var is not yet provided by the lower target list, so
			// create a new TargetEntry for it
			Node *var_copy = (Node *) gpdb::CopyObject(var);
			return (Node *) MakeVarInDerivedTable(var_copy, context);
		}

		var->varno = 1;	 // derived query is the only table in FROM expression
		var->varattno = found_tle->resno;
		var->varlevelsup =
			context->m_current_query_level;	 // reset varlevels up
		found_tle->resjunk = false;

		return (Node *) var;
	}

	if (IsA(node, Query))
	{
		// recurse into Query nodes
		context->m_current_query_level++;
		Query *result = query_tree_mutator(
			(Query *) node, (MutatorWalkerFn) RunWindowProjListMutator, context,
			0);
		context->m_current_query_level--;

		return (Node *) result;
	}

	return expression_tree_mutator(
		node, (MutatorWalkerFn) CQueryMutators::RunWindowProjListMutator,
		context);
}

//---------------------------------------------------------------------------
//	@function:
//		CQueryMutators::ReassignSortClause
//
//	@doc:
//		Reassign the sorting clause from the derived table to the new top-level query
//---------------------------------------------------------------------------
void
CQueryMutators::ReassignSortClause(Query *top_level_query,
								   Query *derived_table_query)
{
	top_level_query->sortClause = derived_table_query->sortClause;
	top_level_query->limitOffset = derived_table_query->limitOffset;
	top_level_query->limitCount = derived_table_query->limitCount;
	derived_table_query->sortClause = NULL;
	derived_table_query->limitOffset = NULL;
	derived_table_query->limitCount = NULL;
}

// EOF
