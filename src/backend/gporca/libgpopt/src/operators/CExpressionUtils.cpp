//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2014 Pivotal, Inc.
//
//	@filename:
//		CExpressionUtils.cpp
//
//	@doc:
//		Utility routines for transforming expressions
//
//	@owner:
//		,
//
//	@test:
//
//---------------------------------------------------------------------------

#include "gpopt/operators/CExpressionUtils.h"

#include "gpopt/base/CColRefSetIter.h"
#include "gpopt/base/CColRefTable.h"
#include "gpopt/base/CConstraintInterval.h"
#include "gpopt/base/CUtils.h"
#include "gpopt/exception.h"
#include "gpopt/mdcache/CMDAccessor.h"
#include "gpopt/operators/CLogicalJoin.h"
#include "gpopt/operators/CPredicateUtils.h"
#include "gpopt/operators/CScalarSubqueryExists.h"
#include "gpopt/operators/CScalarSubqueryNotExists.h"
#include "naucrates/md/IMDScalarOp.h"
#include "naucrates/md/IMDType.h"
#include "naucrates/statistics/CStatistics.h"

using namespace gpopt;

//---------------------------------------------------------------------------
//	@function:
//		CExpressionUtils::UnnestChild
//
//	@doc:
//		Unnest a given expression's child and append unnested nodes to
//		the given expression array
//
//---------------------------------------------------------------------------
void
CExpressionUtils::UnnestChild(
	CMemoryPool *mp,
	CExpression *pexpr,			 // parent node
	ULONG child_index,			 // child index
	BOOL fAnd,					 // is expression an AND node?
	BOOL fOr,					 // is expression an OR node?
	BOOL fHasNegatedChild,		 // does expression have NOT child nodes?
	CExpressionArray *pdrgpexpr	 // array to append results to
)
{
	GPOS_ASSERT(NULL != mp);
	GPOS_ASSERT(NULL != pexpr);
	GPOS_ASSERT(child_index < pexpr->Arity());
	GPOS_ASSERT(NULL != pdrgpexpr);

	CExpression *pexprChild = (*pexpr)[child_index];

	if ((fAnd && CPredicateUtils::FAnd(pexprChild)) ||
		(fOr && CPredicateUtils::FOr(pexprChild)))
	{
		// two cascaded AND nodes or two cascaded OR nodes, recursively
		// pull-up children
		AppendChildren(mp, pexprChild, pdrgpexpr);

		return;
	}

	if (fHasNegatedChild && CPredicateUtils::FNot(pexprChild) &&
		CPredicateUtils::FNot((*pexprChild)[0]))
	{
		// two cascaded Not nodes cancel each other
		CExpression *pexprNot = (*pexprChild)[0];
		pexprChild = (*pexprNot)[0];
	}
	CExpression *pexprUnnestedChild = PexprUnnest(mp, pexprChild);
	pdrgpexpr->Append(pexprUnnestedChild);
}

//---------------------------------------------------------------------------
//	@function:
//		CExpressionUtils::AppendChildren
//
//	@doc:
//		Append the unnested children of given expression to given array
//
//---------------------------------------------------------------------------
void
CExpressionUtils::AppendChildren(CMemoryPool *mp, CExpression *pexpr,
								 CExpressionArray *pdrgpexpr)
{
	GPOS_ASSERT(NULL != mp);
	GPOS_ASSERT(NULL != pexpr);
	GPOS_ASSERT(NULL != pdrgpexpr);

	CExpressionArray *pdrgpexprChildren = PdrgpexprUnnestChildren(mp, pexpr);
	CUtils::AddRefAppend<CExpression, CleanupRelease>(pdrgpexpr,
													  pdrgpexprChildren);
	pdrgpexprChildren->Release();
}

//---------------------------------------------------------------------------
//	@function:
//		CExpressionUtils::PdrgpexprUnnestChildren
//
//	@doc:
//		Return an array of expression's children after unnesting nested
//		AND/OR/NOT subtrees
//
//---------------------------------------------------------------------------
CExpressionArray *
CExpressionUtils::PdrgpexprUnnestChildren(CMemoryPool *mp, CExpression *pexpr)
{
	// protect against stack overflow during recursion
	GPOS_CHECK_STACK_SIZE;
	GPOS_ASSERT(NULL != mp);
	GPOS_ASSERT(NULL != pexpr);

	// compute flags for cases where we may have nested predicates
	BOOL fAnd = CPredicateUtils::FAnd(pexpr);
	BOOL fOr = CPredicateUtils::FOr(pexpr);
	BOOL fHasNegatedChild = CPredicateUtils::FHasNegatedChild(pexpr);

	CExpressionArray *pdrgpexpr = GPOS_NEW(mp) CExpressionArray(mp);
	const ULONG arity = pexpr->Arity();
	for (ULONG ul = 0; ul < arity; ul++)
	{
		UnnestChild(mp, pexpr, ul, fAnd, fOr, fHasNegatedChild, pdrgpexpr);
	}

	return pdrgpexpr;
}

//---------------------------------------------------------------------------
//	@function:
//		CExpressionUtils::PexprUnnest
//
//	@doc:
//		Unnest AND/OR/NOT predicates
//
//---------------------------------------------------------------------------
CExpression *
CExpressionUtils::PexprUnnest(CMemoryPool *mp, CExpression *pexpr)
{
	// protect against stack overflow during recursion
	GPOS_CHECK_STACK_SIZE;
	GPOS_ASSERT(NULL != mp);
	GPOS_ASSERT(NULL != pexpr);

	if (CPredicateUtils::FNot(pexpr))
	{
		CExpression *pexprChild = (*pexpr)[0];
		CExpression *pexprPushedNot = PexprPushNotOneLevel(mp, pexprChild);

		COperator *pop = pexprPushedNot->Pop();
		CExpressionArray *pdrgpexpr =
			PdrgpexprUnnestChildren(mp, pexprPushedNot);
		pop->AddRef();

		// clean up
		pexprPushedNot->Release();

		return GPOS_NEW(mp) CExpression(mp, pop, pdrgpexpr);
	}

	COperator *pop = pexpr->Pop();
	CExpressionArray *pdrgpexpr = PdrgpexprUnnestChildren(mp, pexpr);
	pop->AddRef();

	return GPOS_NEW(mp) CExpression(mp, pop, pdrgpexpr);
}


//---------------------------------------------------------------------------
//	@function:
//		CExpressionUtils::PexprPushNotOneLevel
//
//	@doc:
// 		Push not expression one level down the given expression. For example:
// 		1. AND of expressions into an OR a negation of these expression
// 		2. OR of expressions into an AND a negation of these expression
// 		3. EXISTS into NOT EXISTS and vice versa
//      4. Else, return NOT of given expression
//---------------------------------------------------------------------------
CExpression *
CExpressionUtils::PexprPushNotOneLevel(CMemoryPool *mp, CExpression *pexpr)
{
	GPOS_ASSERT(NULL != pexpr);

	BOOL fAnd = CPredicateUtils::FAnd(pexpr);
	BOOL fOr = CPredicateUtils::FOr(pexpr);

	if (fAnd || fOr)
	{
		COperator *popNew = NULL;

		if (fOr)
		{
			popNew = GPOS_NEW(mp) CScalarBoolOp(mp, CScalarBoolOp::EboolopAnd);
		}
		else
		{
			popNew = GPOS_NEW(mp) CScalarBoolOp(mp, CScalarBoolOp::EboolopOr);
		}

		CExpressionArray *pdrgpexpr = GPOS_NEW(mp) CExpressionArray(mp);
		const ULONG arity = pexpr->Arity();
		for (ULONG ul = 0; ul < arity; ul++)
		{
			CExpression *pexprChild = (*pexpr)[ul];
			pexprChild->AddRef();
			pdrgpexpr->Append(CUtils::PexprNegate(mp, pexprChild));
		}

		return GPOS_NEW(mp) CExpression(mp, popNew, pdrgpexpr);
	}

	const COperator *pop = pexpr->Pop();
	if (COperator::EopScalarSubqueryExists == pop->Eopid())
	{
		pexpr->PdrgPexpr()->AddRef();
		return GPOS_NEW(mp) CExpression(
			mp, GPOS_NEW(mp) CScalarSubqueryNotExists(mp), pexpr->PdrgPexpr());
	}

	if (COperator::EopScalarSubqueryNotExists == pop->Eopid())
	{
		pexpr->PdrgPexpr()->AddRef();
		return GPOS_NEW(mp) CExpression(
			mp, GPOS_NEW(mp) CScalarSubqueryExists(mp), pexpr->PdrgPexpr());
	}

	// TODO: , Feb 4 2015, we currently only handling EXISTS/NOT EXISTS/AND/OR
	pexpr->AddRef();
	return GPOS_NEW(mp) CExpression(
		mp, GPOS_NEW(mp) CScalarBoolOp(mp, CScalarBoolOp::EboolopNot), pexpr);
}


//---------------------------------------------------------------------------
//	@function:
//		CExpressionUtils::PexprDedupChildren
//
//	@doc:
//		Remove duplicate AND/OR children
//
//---------------------------------------------------------------------------
CExpression *
CExpressionUtils::PexprDedupChildren(CMemoryPool *mp, CExpression *pexpr)
{
	// protect against stack overflow during recursion
	GPOS_CHECK_STACK_SIZE;
	GPOS_ASSERT(NULL != mp);
	GPOS_ASSERT(NULL != pexpr);

	// recursively process children
	const ULONG arity = pexpr->Arity();
	CExpressionArray *pdrgpexprChildren = GPOS_NEW(mp) CExpressionArray(mp);
	for (ULONG ul = 0; ul < arity; ul++)
	{
		CExpression *pexprChild = PexprDedupChildren(mp, (*pexpr)[ul]);
		pdrgpexprChildren->Append(pexprChild);
	}

	if (CPredicateUtils::FAnd(pexpr) || CPredicateUtils::FOr(pexpr))
	{
		CExpressionArray *pdrgpexprNewChildren =
			CUtils::PdrgpexprDedup(mp, pdrgpexprChildren);

		pdrgpexprChildren->Release();
		pdrgpexprChildren = pdrgpexprNewChildren;

		// Check if we end with one child, return that child
		if (1 == pdrgpexprChildren->Size())
		{
			CExpression *pexprChild = (*pdrgpexprChildren)[0];
			pexprChild->AddRef();
			pdrgpexprChildren->Release();

			return pexprChild;
		}
	}


	COperator *pop = pexpr->Pop();
	pop->AddRef();
	return GPOS_NEW(mp) CExpression(mp, pop, pdrgpexprChildren);
}

// if the expression is a LogicalSelect and contains correlated EXISTS/ANY subqueries,
// extract those subqueries and return the derived constraint property from subqueries.
// this is useful when we try to infer and propagate predicates from subquery to outer
// relation. returns null if the expression doesn't satisfy aforementioned requirements.
CPropConstraint *
CExpressionUtils::GetPropConstraintFromSubquery(CMemoryPool *mp,
												CExpression *pexpr)
{
	GPOS_ASSERT(NULL != pexpr);
	if (pexpr->Pop()->Eopid() != COperator::EopLogicalSelect)
	{
		return NULL;
	}

	CExpression *filter = (*pexpr)[1];
	CExpressionArray *subqueries = GPOS_NEW(mp) CExpressionArray(mp);

	if (CUtils::FCorrelatedExistsAnySubquery(filter))
	{
		filter->AddRef();
		subqueries->Append(filter);
	}
	else if (CPredicateUtils::FAnd(filter))
	{
		const ULONG arity = filter->Arity();
		for (ULONG ul = 0; ul < arity; ul++)
		{
			CExpression *childFilter = (*filter)[ul];
			if (CUtils::FCorrelatedExistsAnySubquery(childFilter))
			{
				childFilter->AddRef();
				subqueries->Append(childFilter);
			}
		}
	}
	else
	{
		subqueries->Release();
		return NULL;
	}

	if (subqueries->Size() == 0)
	{
		subqueries->Release();
		return NULL;
	}

	CExpression *exprSubquery =
		CPredicateUtils::PexprConjunction(mp, subqueries);
	CColRefSetArray *colRefSetArray = NULL;
	CConstraint *pcnstr =
		CConstraint::PcnstrFromScalarExpr(mp, exprSubquery, &colRefSetArray);
	exprSubquery->Release();

	if (NULL == pcnstr)
	{
		CRefCount::SafeRelease(colRefSetArray);
		return NULL;
	}
	return GPOS_NEW(mp) CPropConstraint(mp, colRefSetArray, pcnstr);
}
// EOF
