//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2011 EMC Corp.
//
//	@filename:
//		CPhysicalJoin.cpp
//
//	@doc:
//		Implementation of physical join operator
//---------------------------------------------------------------------------

#include "gpos/base.h"

#include "gpopt/base/CCastUtils.h"
#include "gpopt/base/CDistributionSpecAny.h"
#include "gpopt/base/CDistributionSpecReplicated.h"
#include "gpopt/base/CUtils.h"
#include "gpopt/exception.h"
#include "gpopt/operators/CExpressionHandle.h"
#include "gpopt/operators/CPhysicalInnerIndexNLJoin.h"
#include "gpopt/operators/CPhysicalLeftOuterIndexNLJoin.h"
#include "gpopt/operators/CPredicateUtils.h"
#include "gpopt/operators/CScalarCmp.h"
#include "gpopt/operators/CScalarIsDistinctFrom.h"
#include "naucrates/md/IMDScalarOp.h"

using namespace gpopt;


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::CPhysicalJoin
//
//	@doc:
//		Ctor
//
//---------------------------------------------------------------------------
CPhysicalJoin::CPhysicalJoin(CMemoryPool *mp, CXform::EXformId origin_xform)
	: CPhysical(mp), m_origin_xform(origin_xform)
{
	m_phmpp = GPOS_NEW(mp) PartPropReqToPartPropSpecMap(mp);
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::~CPhysicalJoin
//
//	@doc:
//		Dtor
//
//---------------------------------------------------------------------------
CPhysicalJoin::~CPhysicalJoin()
{
	m_phmpp->Release();
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::Matches
//
//	@doc:
//		Match operators
//
//---------------------------------------------------------------------------
BOOL
CPhysicalJoin::Matches(COperator *pop) const
{
	return Eopid() == pop->Eopid();
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PosPropagateToOuter
//
//	@doc:
//		Helper for propagating required sort order to outer child
//
//---------------------------------------------------------------------------
COrderSpec *
CPhysicalJoin::PosPropagateToOuter(CMemoryPool *mp, CExpressionHandle &exprhdl,
								   COrderSpec *posRequired)
{
	// propagate the order requirement to the outer child only if all the columns
	// specified by the order requirement come from the outer child
	CColRefSet *pcrs = posRequired->PcrsUsed(mp);
	BOOL fOuterSortCols = exprhdl.DeriveOutputColumns(0)->ContainsAll(pcrs);
	pcrs->Release();
	if (fOuterSortCols)
	{
		return PosPassThru(mp, exprhdl, posRequired, 0 /*child_index*/);
	}

	return GPOS_NEW(mp) COrderSpec(mp);
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PcrsRequired
//
//	@doc:
//		Compute required output columns of n-th child
//
//---------------------------------------------------------------------------
CColRefSet *
CPhysicalJoin::PcrsRequired(CMemoryPool *mp, CExpressionHandle &exprhdl,
							CColRefSet *pcrsRequired, ULONG child_index,
							CDrvdPropArray *,  // pdrgpdpCtxt
							ULONG			   // ulOptReq
)
{
	GPOS_ASSERT(
		child_index < 2 &&
		"Required properties can only be computed on the relational child");

	return PcrsChildReqd(mp, exprhdl, pcrsRequired, child_index,
						 2 /*ulScalarIndex*/);
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PppsRequired
//
//	@doc:
//		Compute required partition propagation of the n-th child
//
//---------------------------------------------------------------------------
CPartitionPropagationSpec *
CPhysicalJoin::PppsRequired(CMemoryPool *mp, CExpressionHandle &exprhdl,
							CPartitionPropagationSpec *pppsRequired,
							ULONG child_index,
							CDrvdPropArray *,  //pdrgpdpCtxt,
							ULONG			   //ulOptReq
)
{
	GPOS_ASSERT(NULL != pppsRequired);

	return CPhysical::PppsRequiredPushThruNAry(mp, exprhdl, pppsRequired,
											   child_index);
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PcteRequired
//
//	@doc:
//		Compute required CTE map of the n-th child
//
//---------------------------------------------------------------------------
CCTEReq *
CPhysicalJoin::PcteRequired(CMemoryPool *mp, CExpressionHandle &exprhdl,
							CCTEReq *pcter, ULONG child_index,
							CDrvdPropArray *pdrgpdpCtxt,
							ULONG  //ulOptReq
) const
{
	GPOS_ASSERT(2 > child_index);

	return PcterNAry(mp, exprhdl, pcter, child_index, pdrgpdpCtxt);
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::FProvidesReqdCols
//
//	@doc:
//		Helper for checking if required columns are included in output columns
//
//---------------------------------------------------------------------------
BOOL
CPhysicalJoin::FProvidesReqdCols(CExpressionHandle &exprhdl,
								 CColRefSet *pcrsRequired,
								 ULONG	// ulOptReq
) const
{
	GPOS_ASSERT(NULL != pcrsRequired);
	GPOS_ASSERT(3 == exprhdl.Arity());

	// union columns from relational children
	CColRefSet *pcrs = GPOS_NEW(m_mp) CColRefSet(m_mp);
	ULONG arity = exprhdl.Arity();
	for (ULONG i = 0; i < arity - 1; i++)
	{
		CColRefSet *pcrsChild = exprhdl.DeriveOutputColumns(i);
		pcrs->Union(pcrsChild);
	}

	BOOL fProvidesCols = pcrs->ContainsAll(pcrsRequired);
	pcrs->Release();

	return fProvidesCols;
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::FSortColsInOuterChild
//
//	@doc:
//		Helper for checking if required sort columns come from outer child
//
//----------------------------------------------------------------------------
BOOL
CPhysicalJoin::FSortColsInOuterChild(CMemoryPool *mp,
									 CExpressionHandle &exprhdl,
									 COrderSpec *pos)
{
	GPOS_ASSERT(NULL != pos);

	CColRefSet *pcrsSort = pos->PcrsUsed(mp);
	CColRefSet *pcrsOuterChild = exprhdl.DeriveOutputColumns(0 /*child_index*/);
	BOOL fSortColsInOuter = pcrsOuterChild->ContainsAll(pcrsSort);
	pcrsSort->Release();

	return fSortColsInOuter;
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::FOuterProvidesReqdCols
//
//	@doc:
//		Helper for checking if the outer input of a binary join operator
//		includes the required columns
//
//---------------------------------------------------------------------------
BOOL
CPhysicalJoin::FOuterProvidesReqdCols(CExpressionHandle &exprhdl,
									  CColRefSet *pcrsRequired)
{
	GPOS_ASSERT(NULL != pcrsRequired);
	GPOS_ASSERT(3 == exprhdl.Arity() && "expected binary join");

	CColRefSet *pcrsOutput = exprhdl.DeriveOutputColumns(0 /*child_index*/);

	return pcrsOutput->ContainsAll(pcrsRequired);
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PdsRequired
//
//	@doc:
//		Compute required distribution of the n-th child;
//		this function creates a request for ANY distribution on the outer
//		child, then matches the delivered distribution on the inner child,
//		this results in sending either a broadcast or singleton distribution
//		requests to the inner child
//
//---------------------------------------------------------------------------
CDistributionSpec *
CPhysicalJoin::PdsRequired(CMemoryPool * /*mp*/,
						   CExpressionHandle & /*exprhdl*/,
						   CDistributionSpec *,	 //pdsRequired,
						   ULONG /*child_index*/,
						   CDrvdPropArray * /*pdrgpdpCtxt*/,
						   ULONG  // ulOptReq
) const
{
	GPOS_RAISE(
		CException::ExmaInvalid, CException::ExmiInvalid,
		GPOS_WSZ_LIT("PdsRequired should not be called for CPhysicalJoin"));
	return NULL;
}

CEnfdDistribution *
CPhysicalJoin::Ped(CMemoryPool *mp, CExpressionHandle &exprhdl,
				   CReqdPropPlan *prppInput, ULONG child_index,
				   CDrvdPropArray *pdrgpdpCtxt, ULONG ulDistrReq)
{
	GPOS_ASSERT(2 > child_index);

	CEnfdDistribution::EDistributionMatching dmatch =
		Edm(prppInput, child_index, pdrgpdpCtxt, ulDistrReq);
	CDistributionSpec *const pdsRequired = prppInput->Ped()->PdsRequired();

	// if expression has to execute on a single host then we need a gather
	if (exprhdl.NeedsSingletonExecution())
	{
		return GPOS_NEW(mp) CEnfdDistribution(
			PdsRequireSingleton(mp, exprhdl, pdsRequired, child_index), dmatch);
	}

	if (exprhdl.HasOuterRefs())
	{
		if (CDistributionSpec::EdtSingleton == pdsRequired->Edt() ||
			CDistributionSpec::EdtStrictReplicated == pdsRequired->Edt())
		{
			return GPOS_NEW(mp) CEnfdDistribution(
				PdsPassThru(mp, exprhdl, pdsRequired, child_index), dmatch);
		}
		return GPOS_NEW(mp) CEnfdDistribution(
			GPOS_NEW(mp)
				CDistributionSpecReplicated(CDistributionSpec::EdtReplicated),
			dmatch);
	}

	if (1 == child_index)
	{
		// compute a matching distribution based on derived distribution of outer child
		CDistributionSpec *pdsOuter =
			CDrvdPropPlan::Pdpplan((*pdrgpdpCtxt)[0])->Pds();

		if (CDistributionSpec::EdtUniversal == pdsOuter->Edt())
		{
			// first child is universal, request second child to execute on a single host to avoid duplicates
			return GPOS_NEW(mp) CEnfdDistribution(
				GPOS_NEW(mp) CDistributionSpecSingleton(), dmatch);
		}

		if (CDistributionSpec::EdtSingleton == pdsOuter->Edt() ||
			CDistributionSpec::EdtStrictSingleton == pdsOuter->Edt())
		{
			// require inner child to have matching singleton distribution
			return GPOS_NEW(mp) CEnfdDistribution(
				CPhysical::PdssMatching(
					mp, CDistributionSpecSingleton::PdssConvert(pdsOuter)),
				dmatch);
		}

		if ((GPOS_FTRACE(EopttraceEnableRedistributeNLLOJInnerChild) &&
			 this->Eopid() == COperator::EopPhysicalLeftOuterNLJoin))
		{
			CEnfdDistribution *pEnfdHashedDistribution =
				CPhysicalJoin::PedInnerHashedFromOuterHashed(
					mp, exprhdl, dmatch, (*pdrgpdpCtxt)[0]);
			if (pEnfdHashedDistribution)
				return pEnfdHashedDistribution;
		}


		// otherwise, require inner child to be replicated
		return GPOS_NEW(mp) CEnfdDistribution(
			GPOS_NEW(mp)
				CDistributionSpecReplicated(CDistributionSpec::EdtReplicated),
			CEnfdDistribution::EdmSatisfy);
	}

	// no distribution requirement on the outer side
	return GPOS_NEW(mp) CEnfdDistribution(
		GPOS_NEW(mp) CDistributionSpecAny(this->Eopid()), dmatch);
}

CEnfdDistribution *
CPhysicalJoin::PedInnerHashedFromOuterHashed(
	CMemoryPool *mp, CExpressionHandle &exprhdl,
	CEnfdDistribution::EDistributionMatching dmatch, CDrvdProp *outerDrvdProp)
{
	// compute a matching distribution based on derived distribution of outer child
	CDistributionSpec *pdsOuter = CDrvdPropPlan::Pdpplan(outerDrvdProp)->Pds();
	if (CDistributionSpec::EdtHashed == pdsOuter->Edt())
	{
		// require inner child to have matching hashed distribution
		CExpression *pexprScPredicate =
			exprhdl.PexprScalarExactChild(2, true /*error_on_null_return*/);

		CExpressionArray *pdrgpexpr =
			CPredicateUtils::PdrgpexprConjuncts(mp, pexprScPredicate);

		CExpressionArray *pdrgpexprMatching = GPOS_NEW(mp) CExpressionArray(mp);
		CDistributionSpecHashed *pdshashed =
			CDistributionSpecHashed::PdsConvert(pdsOuter);
		CExpressionArray *pdrgpexprHashed = pdshashed->Pdrgpexpr();
		const ULONG ulSize = pdrgpexprHashed->Size();

		BOOL fSuccess = true;
		for (ULONG ul = 0; fSuccess && ul < ulSize; ul++)
		{
			CExpression *pexpr = (*pdrgpexprHashed)[ul];
			// get matching expression from predicate for the corresponding outer child
			// to create CDistributionSpecHashed for inner child
			CExpression *pexprMatching =
				CUtils::PexprMatchEqualityOrINDF(pexpr, pdrgpexpr);
			// columns on which the inner side must be distributed should not contain any column from the outer side
			// for ex: t1.a = t2.a + t1.a, in this case we can't request t2.a + t1.a from the inner side
			// where t1 is outer side and t2 is inner table
			CColRefSet *pcrsOutputOuter = exprhdl.DeriveOutputColumns(0);
			fSuccess = NULL != pexprMatching &&
					   !pexprMatching->DeriveUsedColumns()->FIntersects(
						   pcrsOutputOuter);
			if (fSuccess)
			{
				IMDId *pmdidTypeInner =
					CScalar::PopConvert(pexprMatching->Pop())->MdidType();

				IMDId *pmdidTypeOuter =
					CScalar::PopConvert(pexpr->Pop())->MdidType();

				CMDAccessor *mdAccessor = COptCtxt::PoctxtFromTLS()->Pmda();

				IMDId *mdidOpfamilyInner =
					mdAccessor->RetrieveType(pmdidTypeInner)
						->GetDistrOpfamilyMdid();

				IMDId *mdidOpfamilyOuter =
					mdAccessor->RetrieveType(pmdidTypeOuter)
						->GetDistrOpfamilyMdid();

				if (mdidOpfamilyOuter->Equals(mdidOpfamilyInner) &&
					mdAccessor->RetrieveType(pmdidTypeInner)->IsHashable())
				{
					pexprMatching->AddRef();
					pdrgpexprMatching->Append(pexprMatching);
				}
				else
				{
					fSuccess = false;
				}
			}
		}
		pdrgpexpr->Release();

		if (fSuccess)
		{
			GPOS_ASSERT(pdrgpexprMatching->Size() == pdrgpexprHashed->Size());

			// create a matching hashed distribution request
			BOOL fNullsColocated = pdshashed->FNullsColocated();
			CDistributionSpecHashed *pdshashedEquiv = GPOS_NEW(mp)
				CDistributionSpecHashed(pdrgpexprMatching, fNullsColocated);
			pdshashedEquiv->ComputeEquivHashExprs(mp, exprhdl);
			return GPOS_NEW(mp) CEnfdDistribution(pdshashedEquiv, dmatch);
		}
		pdrgpexprMatching->Release();
	}

	return NULL;
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PdsDerive
//
//	@doc:
//		Derive distribution
//
//---------------------------------------------------------------------------
CDistributionSpec *
CPhysicalJoin::PdsDerive(CMemoryPool *mp, CExpressionHandle &exprhdl) const
{
	CDistributionSpec *pdsOuter = exprhdl.Pdpplan(0 /*child_index*/)->Pds();
	CDistributionSpec *pdsInner = exprhdl.Pdpplan(1 /*child_index*/)->Pds();

	// We must use the non-nullable side for the distribution spec for outer joins.
	// For right join, the hash side is the non-nullable side, so we swap the inner/outer
	// distribution specs for the logic below
	if (exprhdl.Pop()->Eopid() == EopPhysicalRightOuterHashJoin)
	{
		pdsOuter = exprhdl.Pdpplan(1 /*child_index*/)->Pds();
		pdsInner = exprhdl.Pdpplan(0 /*child_index*/)->Pds();
	}

	CDistributionSpec *pds;

	if ((CDistributionSpec::EdtStrictReplicated == pdsOuter->Edt() ||
		 CDistributionSpec::EdtTaintedReplicated == pdsOuter->Edt() ||
		 CDistributionSpec::EdtUniversal == pdsOuter->Edt()) &&
		CDistributionSpec::EdtUniversal != pdsInner->Edt())
	{
		// if outer is replicated/universal and inner is not universal
		// then return inner distribution
		pds = pdsInner;
	}
	else
	{
		// otherwise, return outer distribution
		pds = pdsOuter;
	}

	if (CDistributionSpec::EdtHashed == pds->Edt())
	{
		CDistributionSpecHashed *pdsHashed =
			CDistributionSpecHashed::PdsConvert(pds);

		// Clean up any incomplete distribution specs since they can no longer be completed above
		// Note that, since this is done at the lowest join, no relevant equivalent specs are lost.
		if (!pdsHashed->HasCompleteEquivSpec(mp))
		{
			CExpressionArray *pdrgpexpr = pdsHashed->Pdrgpexpr();
			IMdIdArray *opfamilies = pdsHashed->Opfamilies();

			if (NULL != opfamilies)
			{
				opfamilies->AddRef();
			}
			pdrgpexpr->AddRef();
			return GPOS_NEW(mp) CDistributionSpecHashed(
				pdrgpexpr, pdsHashed->FNullsColocated(), opfamilies);
		}
	}

	pds->AddRef();
	return pds;
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PrsDerive
//
//	@doc:
//		Derive rewindability
//
//---------------------------------------------------------------------------
CRewindabilitySpec *
CPhysicalJoin::PrsDerive(CMemoryPool *mp, CExpressionHandle &exprhdl) const
{
	CRewindabilitySpec *prsOuter = exprhdl.Pdpplan(0 /*child_index*/)->Prs();
	GPOS_ASSERT(NULL != prsOuter);

	CRewindabilitySpec *prsInner = exprhdl.Pdpplan(1 /*child_index*/)->Prs();
	GPOS_ASSERT(NULL != prsInner);

	CRewindabilitySpec::EMotionHazardType motion_hazard =
		(prsOuter->HasMotionHazard() || prsInner->HasMotionHazard())
			? CRewindabilitySpec::EmhtMotion
			: CRewindabilitySpec::EmhtNoMotion;

	// TODO: shardikar; Implement a separate PrsDerive() for HashJoins since it
	// is different from NLJ; the inner of a HJ child is rewindable (due to a
	// Hash op on the inner side)

	// If both children are rewindable, the join is also rewinable
	if (prsOuter->IsRewindable() && prsInner->IsRewindable())
	{
		return GPOS_NEW(mp) CRewindabilitySpec(
			CRewindabilitySpec::ErtRewindable, motion_hazard);
	}

	// If either child is ErtNone (neither rewindable, rescannable nor mark-restore), then the join is also ErtNone
	else if (prsOuter->Ert() == CRewindabilitySpec::ErtNone ||
			 prsInner->Ert() == CRewindabilitySpec::ErtNone)
	{
		return GPOS_NEW(mp)
			CRewindabilitySpec(CRewindabilitySpec::ErtNone, motion_hazard);
	}

	// If the children are in any other combination, e.g (rescannable, rewindable, markrestore) etc,
	// derive rescannable for the join
	else
	{
		return GPOS_NEW(mp) CRewindabilitySpec(
			CRewindabilitySpec::ErtRescannable, motion_hazard);
	}
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::EpetRewindability
//
//	@doc:
//		Return the enforcing type for rewindability property based on this operator
//
//---------------------------------------------------------------------------
CEnfdProp::EPropEnforcingType
CPhysicalJoin::EpetRewindability(CExpressionHandle &exprhdl,
								 const CEnfdRewindability *per) const
{
	// get rewindability delivered by the join node
	CRewindabilitySpec *prs = CDrvdPropPlan::Pdpplan(exprhdl.Pdp())->Prs();

	if (per->FCompatible(prs))
	{
		// required rewindability will be established by the join operator
		return CEnfdProp::EpetUnnecessary;
	}

	// required rewindability will be enforced on join's output
	return CEnfdProp::EpetRequired;
}

// Do each of the given predicate children use columns from a different
// join child? For this method to return true, either:
//   - pexprPredInner uses columns from pexprInner and pexprPredOuter uses
//     columns from pexprOuter; or
//   - pexprPredInner uses columns from pexprOuter and pexprPredOuter uses
//     columns from pexprInner
BOOL
CPhysicalJoin::FPredKeysSeparated(CExpression *pexprInner,
								  CExpression *pexprOuter,
								  CExpression *pexprPredInner,
								  CExpression *pexprPredOuter)
{
	GPOS_ASSERT(NULL != pexprOuter);
	GPOS_ASSERT(NULL != pexprInner);
	GPOS_ASSERT(NULL != pexprPredOuter);
	GPOS_ASSERT(NULL != pexprPredInner);

	CColRefSet *pcrsUsedPredOuter = pexprPredOuter->DeriveUsedColumns();
	CColRefSet *pcrsUsedPredInner = pexprPredInner->DeriveUsedColumns();

	CColRefSet *outer_refs = pexprOuter->DeriveOutputColumns();
	CColRefSet *pcrsInner = pexprInner->DeriveOutputColumns();

	// make sure that each predicate child uses columns from a different join child
	// in order to reject predicates of the form 'X Join Y on f(X.a, Y.b) = 5'
	BOOL fPredOuterUsesJoinOuterChild =
		(0 < pcrsUsedPredOuter->Size()) &&
		outer_refs->ContainsAll(pcrsUsedPredOuter);
	BOOL fPredOuterUsesJoinInnerChild =
		(0 < pcrsUsedPredOuter->Size()) &&
		pcrsInner->ContainsAll(pcrsUsedPredOuter);
	BOOL fPredInnerUsesJoinOuterChild =
		(0 < pcrsUsedPredInner->Size()) &&
		outer_refs->ContainsAll(pcrsUsedPredInner);
	BOOL fPredInnerUsesJoinInnerChild =
		(0 < pcrsUsedPredInner->Size()) &&
		pcrsInner->ContainsAll(pcrsUsedPredInner);

	return (fPredOuterUsesJoinOuterChild && fPredInnerUsesJoinInnerChild) ||
		   (fPredOuterUsesJoinInnerChild && fPredInnerUsesJoinOuterChild);
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::FHashJoinCompatible
//
//	@doc:
//		Is given predicate hash-join compatible?
//		the function returns True if predicate is of the form (Equality) or
//		(Is Not Distinct From), both operands are hashjoinable, AND the predicate
//		uses columns from both join children
//
//---------------------------------------------------------------------------
BOOL
CPhysicalJoin::FHashJoinCompatible(
	CExpression *pexprPred,	  // predicate in question
	CExpression *pexprOuter,  // outer child of the join
	CExpression *pexprInner	  // inner child of the join
)
{
	GPOS_ASSERT(NULL != pexprPred);
	GPOS_ASSERT(NULL != pexprOuter);
	GPOS_ASSERT(NULL != pexprInner);
	GPOS_ASSERT(pexprOuter != pexprInner);

	CExpression *pexprPredOuter = NULL;
	CExpression *pexprPredInner = NULL;
	IMDId *mdid_scop = NULL;
	if (CPredicateUtils::IsEqualityOp(pexprPred))
	{
		pexprPredOuter = (*pexprPred)[0];
		pexprPredInner = (*pexprPred)[1];
		mdid_scop = CScalarCmp::PopConvert(pexprPred->Pop())->MdIdOp();
	}
	else if (CPredicateUtils::FINDF(pexprPred))
	{
		CExpression *pexpr = (*pexprPred)[0];
		pexprPredOuter = (*pexpr)[0];
		pexprPredInner = (*pexpr)[1];
		mdid_scop = CScalarIsDistinctFrom::PopConvert(pexpr->Pop())->MdIdOp();
	}
	else
	{
		return false;
	}

	IMDId *pmdidTypeOuter =
		CScalar::PopConvert(pexprPredOuter->Pop())->MdidType();
	IMDId *pmdidTypeInner =
		CScalar::PopConvert(pexprPredInner->Pop())->MdidType();

	CMDAccessor *md_accessor = COptCtxt::PoctxtFromTLS()->Pmda();

	const IMDScalarOp *scop = md_accessor->RetrieveScOp(mdid_scop);
	if (GPOS_FTRACE(EopttraceConsiderOpfamiliesForDistribution) &&
		NULL == scop->HashOpfamilyMdid())
	{
		return false;
	}

	// This check is mainly added for RANGE TYPES; RANGE's are treated as
	// containers and whether a range type can support hashing is decided
	// based on hashing support of its subtype
	if (COperator::EopScalarCast == pexprPredOuter->Pop()->Eopid())
	{
		pmdidTypeOuter =
			CScalar::PopConvert((*pexprPredOuter)[0]->Pop())->MdidType();
	}
	if (COperator::EopScalarCast == pexprPredInner->Pop()->Eopid())
	{
		pmdidTypeInner =
			CScalar::PopConvert((*pexprPredInner)[0]->Pop())->MdidType();
	}

	if (md_accessor->RetrieveType(pmdidTypeOuter)->IsHashable() &&
		md_accessor->RetrieveType(pmdidTypeInner)->IsHashable())
	{
		return FPredKeysSeparated(pexprInner, pexprOuter, pexprPredInner,
								  pexprPredOuter);
	}

	return false;
}

BOOL
CPhysicalJoin::FMergeJoinCompatible(
	CExpression *pexprPred,	  // predicate in question
	CExpression *pexprOuter,  // outer child of the join
	CExpression *pexprInner	  // inner child of the join
)
{
	GPOS_ASSERT(NULL != pexprPred);
	GPOS_ASSERT(NULL != pexprOuter);
	GPOS_ASSERT(NULL != pexprInner);
	GPOS_ASSERT(pexprOuter != pexprInner);

	CExpression *pexprPredOuter = NULL;
	CExpression *pexprPredInner = NULL;
	IMDId *mdid_scop = NULL;

	// Only merge join between ScalarIdents of the same types is currently supported
	if (CPredicateUtils::FEqIdentsOfSameType(pexprPred))
	{
		pexprPredOuter = (*pexprPred)[0];
		pexprPredInner = (*pexprPred)[1];
		mdid_scop = CScalarCmp::PopConvert(pexprPred->Pop())->MdIdOp();
		GPOS_ASSERT(CUtils::FScalarIdent(pexprPredOuter));
		GPOS_ASSERT(CUtils::FScalarIdent(pexprPredInner));
	}
	else
	{
		return false;
	}

	IMDId *pmdidTypeOuter =
		CScalar::PopConvert(pexprPredOuter->Pop())->MdidType();
	IMDId *pmdidTypeInner =
		CScalar::PopConvert(pexprPredInner->Pop())->MdidType();

	CMDAccessor *mda = COptCtxt::PoctxtFromTLS()->Pmda();

	if (GPOS_FTRACE(EopttraceConsiderOpfamiliesForDistribution))
	{
		const IMDScalarOp *op = mda->RetrieveScOp(mdid_scop);
		const IMDType *left_type = mda->RetrieveType(pmdidTypeOuter);
		const IMDType *right_type = mda->RetrieveType(pmdidTypeInner);

		// MJ sends Sort requests whose btree opclass must match that of the join
		// clause. ORCA currently doesn't have support to retrive the information
		// to send such requests.
		// So, check that hash family used for distribution matches the default for
		// its operands' types. This must match the operator using in
		// CPhysicalFullMergeJoin::PosRequired().
		if (!CUtils::Equals(op->HashOpfamilyMdid(),
							left_type->GetDistrOpfamilyMdid()) ||
			!CUtils::Equals(op->HashOpfamilyMdid(),
							right_type->GetDistrOpfamilyMdid()))
		{
			return false;
		}
	}

	// MJ sends a distribution request for merge clauses on both sides, they
	// must, therefore, be hashable and merge joinable.

	if (mda->RetrieveType(pmdidTypeOuter)->IsHashable() &&
		mda->RetrieveType(pmdidTypeInner)->IsHashable() &&
		mda->RetrieveType(pmdidTypeOuter)->IsMergeJoinable() &&
		mda->RetrieveType(pmdidTypeInner)->IsMergeJoinable())
	{
		return FPredKeysSeparated(pexprInner, pexprOuter, pexprPredInner,
								  pexprPredOuter);
	}

	return false;
}

// Check for equality and INDFs in the predicates, and also aligns the expressions inner and outer keys with the predicates
// For example foo (a int, b int) and bar (c int, d int), will need to be aligned properly if the predicate is d = a)
void
CPhysicalJoin::AlignJoinKeyOuterInner(CExpression *pexprPred,
									  CExpression *pexprOuter,
#ifdef GPOS_DEBUG
									  CExpression *pexprInner,
#else
									  CExpression *,
#endif	// GPOS_DEBUG
									  CExpression **ppexprKeyOuter,
									  CExpression **ppexprKeyInner,
									  IMDId **mdid_scop)
{
	// we should not be here if there are outer references
	GPOS_ASSERT(NULL != ppexprKeyOuter);
	GPOS_ASSERT(NULL != ppexprKeyInner);

	CExpression *pexprPredOuter = NULL;
	CExpression *pexprPredInner = NULL;

	// extract left & right children from pexprPred for all supported ops
	if (CPredicateUtils::IsEqualityOp(pexprPred))
	{
		pexprPredOuter = (*pexprPred)[0];
		pexprPredInner = (*pexprPred)[1];
		*mdid_scop = CScalarCmp::PopConvert(pexprPred->Pop())->MdIdOp();
	}
	else if (CPredicateUtils::FINDF(pexprPred))
	{
		CExpression *pexpr = (*pexprPred)[0];
		pexprPredOuter = (*pexpr)[0];
		pexprPredInner = (*pexpr)[1];
		*mdid_scop = CScalarIsDistinctFrom::PopConvert(pexpr->Pop())->MdIdOp();
	}
	else
	{
		GPOS_RAISE(
			gpopt::ExmaGPOPT, gpopt::ExmiUnsupportedOp,
			GPOS_WSZ_LIT("Invalid join expression in AlignJoinKeyOuterInner"));
	}

	GPOS_ASSERT(NULL != pexprPredOuter);
	GPOS_ASSERT(NULL != pexprPredInner);

	CColRefSet *pcrsOuter = pexprOuter->DeriveOutputColumns();
	CColRefSet *pcrsPredOuter = pexprPredOuter->DeriveUsedColumns();

#ifdef GPOS_DEBUG
	CColRefSet *pcrsInner = pexprInner->DeriveOutputColumns();
	CColRefSet *pcrsPredInner = pexprPredInner->DeriveUsedColumns();
#endif	// GPOS_DEBUG

	CExpression *pexprOuterKeyWithoutBCC =
		CCastUtils::PexprWithoutBinaryCoercibleCasts(pexprPredOuter);
	CExpression *pexprInnerKeyWithoutBCC =
		CCastUtils::PexprWithoutBinaryCoercibleCasts(pexprPredInner);

	if (pcrsOuter->ContainsAll(pcrsPredOuter))
	{
		*ppexprKeyOuter = pexprOuterKeyWithoutBCC;
		GPOS_ASSERT(pcrsInner->ContainsAll(pcrsPredInner));

		*ppexprKeyInner = pexprInnerKeyWithoutBCC;
	}
	else
	{
		GPOS_ASSERT(pcrsOuter->ContainsAll(pcrsPredInner));
		*ppexprKeyOuter = pexprInnerKeyWithoutBCC;

		GPOS_ASSERT(pcrsInner->ContainsAll(pcrsPredOuter));
		*ppexprKeyInner = pexprOuterKeyWithoutBCC;
	}
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::AddFilterOnPartKey
//
//	@doc:
//		 Helper to add filter on part key
//
//---------------------------------------------------------------------------
void
CPhysicalJoin::AddFilterOnPartKey(
	CMemoryPool *mp, BOOL fNLJoin, CExpression *pexprScalar,
	CPartIndexMap *ppimSource, CPartFilterMap *ppfmSource, ULONG child_index,
	ULONG part_idx_id, BOOL fOuterPartConsumer, CPartIndexMap *ppimResult,
	CPartFilterMap *ppfmResult, CColRefSet *pcrsAllowedRefs)
{
	GPOS_ASSERT(NULL != pcrsAllowedRefs);

	ULONG ulChildIndexToTestFirst = 0;
	ULONG ulChildIndexToTestSecond = 1;
	BOOL fOuterPartConsumerTest = fOuterPartConsumer;

	if (fNLJoin)
	{
		ulChildIndexToTestFirst = 1;
		ulChildIndexToTestSecond = 0;
		fOuterPartConsumerTest = !fOuterPartConsumer;
	}

	// look for a filter on the part key
	CExpression *pexprCmp = PexprJoinPredOnPartKeys(
		mp, pexprScalar, ppimSource, part_idx_id, pcrsAllowedRefs);

	// TODO:  - Aug 14, 2013; create a conjunction of the two predicates when the partition resolver framework supports this
	if (NULL == pexprCmp && ppfmSource->FContainsScanId(part_idx_id))
	{
		// look if a predicates was propagated from an above level
		pexprCmp = ppfmSource->Pexpr(part_idx_id);
		pexprCmp->AddRef();
	}

	if (NULL != pexprCmp)
	{
		if (fOuterPartConsumerTest)
		{
			if (ulChildIndexToTestFirst == child_index)
			{
				// we know that we will be requesting the selector from the second child
				// so we need to increment the number of expected propagators here and pass through
				ppimResult->AddRequiredPartPropagation(
					ppimSource, part_idx_id,
					CPartIndexMap::EppraIncrementPropagators);
				pexprCmp->Release();
			}
			else
			{
				// an interesting condition found - request partition selection on the inner child
				ppimResult->AddRequiredPartPropagation(
					ppimSource, part_idx_id,
					CPartIndexMap::EppraZeroPropagators);
				ppfmResult->AddPartFilter(mp, part_idx_id, pexprCmp,
										  NULL /*stats*/);
			}
		}
		else
		{
			pexprCmp->Release();
			GPOS_ASSERT(ulChildIndexToTestFirst == child_index);
		}
	}
	else if (FProcessingChildWithPartConsumer(
				 fOuterPartConsumerTest, ulChildIndexToTestFirst,
				 ulChildIndexToTestSecond, child_index))
	{
		// no interesting condition found - push through partition propagation request
		ppimResult->AddRequiredPartPropagation(
			ppimSource, part_idx_id, CPartIndexMap::EppraPreservePropagators);
	}
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::FProcessingChildWithPartConsumer
//
//	@doc:
//		Check whether the child being processed is the child that has the part consumer
//
//---------------------------------------------------------------------------
BOOL
CPhysicalJoin::FProcessingChildWithPartConsumer(BOOL fOuterPartConsumerTest,
												ULONG ulChildIndexToTestFirst,
												ULONG ulChildIndexToTestSecond,
												ULONG child_index)
{
	return (fOuterPartConsumerTest && ulChildIndexToTestFirst == child_index) ||
		   (!fOuterPartConsumerTest && ulChildIndexToTestSecond == child_index);
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PexprJoinPredOnPartKeys
//
//	@doc:
//		Helper to find join predicates on part keys. Returns NULL if not found
//
//---------------------------------------------------------------------------
CExpression *
CPhysicalJoin::PexprJoinPredOnPartKeys(CMemoryPool *mp,
									   CExpression *pexprScalar,
									   CPartIndexMap *ppimSource,
									   ULONG part_idx_id,
									   CColRefSet *pcrsAllowedRefs)
{
	GPOS_ASSERT(NULL != pcrsAllowedRefs);

	CExpression *pexprPred = NULL;
	CPartKeysArray *pdrgppartkeys = ppimSource->Pdrgppartkeys(part_idx_id);
	const ULONG ulKeysets = pdrgppartkeys->Size();
	for (ULONG ulKey = 0; NULL == pexprPred && ulKey < ulKeysets; ulKey++)
	{
		// get partition key
		CColRef2dArray *pdrgpdrgpcrPartKeys =
			(*pdrgppartkeys)[ulKey]->Pdrgpdrgpcr();

		// try to generate a request with dynamic partition selection
		pexprPred = CPredicateUtils::PexprExtractPredicatesOnPartKeys(
			mp, pexprScalar, pdrgpdrgpcrPartKeys, pcrsAllowedRefs,
			true  // fUseConstraints
		);
	}

	return pexprPred;
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::FFirstChildToOptimize
//
//	@doc:
//		Helper to check if given child index correspond to first
//		child to be optimized
//
//---------------------------------------------------------------------------
BOOL
CPhysicalJoin::FFirstChildToOptimize(ULONG child_index) const
{
	GPOS_ASSERT(2 > child_index);

	EChildExecOrder eceo = Eceo();

	return (EceoLeftToRight == eceo && 0 == child_index) ||
		   (EceoRightToLeft == eceo && 1 == child_index);
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::UlDistrRequestsForCorrelatedJoin
//
//	@doc:
//		Return number of distribution requests for correlated join
//
//---------------------------------------------------------------------------
ULONG
CPhysicalJoin::UlDistrRequestsForCorrelatedJoin()
{
	// Correlated Join creates two distribution requests to enforce distribution of its children:
	// Req(0): If incoming distribution is (Strict) Singleton, pass it through to all children
	//			to comply with correlated execution requirements
	// Req(1): Request outer child for ANY distribution, and then match it on the inner child

	return 2;
}

//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::PrsRequiredCorrelatedJoin
//
//	@doc:
//		Helper to compute required rewindability of correlated join's children
//
//---------------------------------------------------------------------------
CRewindabilitySpec *
CPhysicalJoin::PrsRequiredCorrelatedJoin(CMemoryPool *mp,
										 CExpressionHandle &exprhdl,
										 CRewindabilitySpec *prsRequired,
										 ULONG child_index,
										 CDrvdPropArray *pdrgpdpCtxt,
										 ULONG	// ulOptReq
) const
{
	GPOS_ASSERT(3 == exprhdl.Arity());
	GPOS_ASSERT(2 > child_index);
	GPOS_ASSERT(CUtils::FCorrelatedNLJoin(exprhdl.Pop()));

	if (1 == child_index)
	{
		CRewindabilitySpec *prsOuter =
			CDrvdPropPlan::Pdpplan((*pdrgpdpCtxt)[0 /*outer child*/])->Prs();

		CRewindabilitySpec::EMotionHazardType motion_hazard =
			GPOS_FTRACE(EopttraceMotionHazardHandling) &&
					(prsOuter->HasMotionHazard() ||
					 prsRequired->HasMotionHazard())
				? CRewindabilitySpec::EmhtMotion
				: CRewindabilitySpec::EmhtNoMotion;


		return GPOS_NEW(mp) CRewindabilitySpec(
			CRewindabilitySpec::ErtRescannable, motion_hazard);
	}

	GPOS_ASSERT(0 == child_index);

	return PrsPassThru(mp, exprhdl, prsRequired, 0 /*child_index*/);
}

CEnfdDistribution *
CPhysicalJoin::PedCorrelatedJoin(CMemoryPool *mp, CExpressionHandle &exprhdl,
								 CReqdPropPlan *prppInput, ULONG child_index,
								 CDrvdPropArray *pdrgpdpCtxt, ULONG ulOptReq)
{
	GPOS_ASSERT(3 == exprhdl.Arity());
	GPOS_ASSERT(2 > child_index);
	GPOS_ASSERT(CUtils::FCorrelatedNLJoin(exprhdl.Pop()));

	CDistributionSpec *const pdsRequired = prppInput->Ped()->PdsRequired();

	if (0 == ulOptReq && pdsRequired->FSingletonOrStrictSingleton())
	{
		// propagate Singleton request to children to comply with
		// correlated execution requirements
		return GPOS_NEW(mp) CEnfdDistribution(
			PdsPassThru(mp, exprhdl, pdsRequired, child_index),
			CEnfdDistribution::EdmSatisfy);
	}

	if (exprhdl.PfpChild(1)->FHasVolatileFunctionScan() &&
		exprhdl.HasOuterRefs(1))
	{
		// if the inner child has a volatile TVF and has outer refs then request
		// gather from both children
		return GPOS_NEW(mp)
			CEnfdDistribution(GPOS_NEW(mp) CDistributionSpecSingleton(),
							  CEnfdDistribution::EdmSatisfy);
	}

	if (1 == child_index)
	{
		CDistributionSpec *pdsOuter =
			CDrvdPropPlan::Pdpplan((*pdrgpdpCtxt)[0])->Pds();
		if (CDistributionSpec::EdtUniversal == pdsOuter->Edt())
		{
			// if outer child delivers a universal distribution, request inner child
			// to match Singleton distribution to detect more than one row generated
			// at runtime, for example: 'select (select 1 union select 2)'
			return GPOS_NEW(mp)
				CEnfdDistribution(GPOS_NEW(mp) CDistributionSpecSingleton(),
								  CEnfdDistribution::EdmSatisfy);
		}
	}

	return CPhysicalJoin::Ped(mp, exprhdl, prppInput, child_index, pdrgpdpCtxt,
							  ulOptReq);
}


//---------------------------------------------------------------------------
//	@function:
//		CPhysicalJoin::Edm
//
//	@doc:
//		 Distribution matching type
//
//---------------------------------------------------------------------------
CEnfdDistribution::EDistributionMatching
CPhysicalJoin::Edm(CReqdPropPlan *,	 // prppInput
				   ULONG child_index, CDrvdPropArray *pdrgpdpCtxt,
				   ULONG  // ulOptReq
)
{
	if (FFirstChildToOptimize(child_index))
	{
		// use satisfaction for the first child to be optimized
		return CEnfdDistribution::EdmSatisfy;
	}

	// extract distribution type of previously optimized child
	GPOS_ASSERT(NULL != pdrgpdpCtxt);
	CDistributionSpec::EDistributionType edtPrevChild =
		CDrvdPropPlan::Pdpplan((*pdrgpdpCtxt)[0])->Pds()->Edt();

	if (CDistributionSpec::EdtStrictReplicated == edtPrevChild ||
		CDistributionSpec::EdtUniversal == edtPrevChild)
	{
		// if previous child is replicated or universal, we use
		// distribution satisfaction for current child
		return CEnfdDistribution::EdmSatisfy;
	}

	// use exact matching for all other children
	return CEnfdDistribution::EdmExact;
}


// Hash function
ULONG
CPhysicalJoin::CPartPropReq::HashValue(const CPartPropReq *pppr)
{
	GPOS_ASSERT(NULL != pppr);

	ULONG ulHash = pppr->Ppps()->HashValue();
	ulHash = CombineHashes(ulHash, pppr->UlChildIndex());
	ulHash = CombineHashes(ulHash, pppr->UlOuterChild());
	ulHash = CombineHashes(ulHash, pppr->UlInnerChild());

	return CombineHashes(ulHash, pppr->UlScalarChild());
}

// Equality function
BOOL
CPhysicalJoin::CPartPropReq::Equals(const CPartPropReq *ppprFst,
									const CPartPropReq *ppprSnd)
{
	GPOS_ASSERT(NULL != ppprFst);
	GPOS_ASSERT(NULL != ppprSnd);

	return ppprFst->UlChildIndex() == ppprSnd->UlChildIndex() &&
		   ppprFst->UlOuterChild() == ppprSnd->UlOuterChild() &&
		   ppprFst->UlInnerChild() == ppprSnd->UlInnerChild() &&
		   ppprFst->UlScalarChild() == ppprSnd->UlScalarChild() &&
		   ppprFst->Ppps()->Matches(ppprSnd->Ppps());
}


// Create partition propagation request
CPhysicalJoin::CPartPropReq *
CPhysicalJoin::PpprCreate(CMemoryPool *mp, CExpressionHandle &exprhdl,
						  CPartitionPropagationSpec *pppsRequired,
						  ULONG child_index)
{
	GPOS_ASSERT(exprhdl.Pop() == this);
	GPOS_ASSERT(NULL != pppsRequired);
	if (NULL == exprhdl.Pgexpr())
	{
		return NULL;
	}

	ULONG ulOuterChild = (*exprhdl.Pgexpr())[0]->Id();
	ULONG ulInnerChild = (*exprhdl.Pgexpr())[1]->Id();
	ULONG ulScalarChild = (*exprhdl.Pgexpr())[2]->Id();

	pppsRequired->AddRef();
	return GPOS_NEW(mp) CPartPropReq(pppsRequired, child_index, ulOuterChild,
									 ulInnerChild, ulScalarChild);
}


// Compute required partition propagation of the n-th child
CPartitionPropagationSpec *
CPhysicalJoin::PppsRequiredCompute(CMemoryPool *mp, CExpressionHandle &exprhdl,
								   CPartitionPropagationSpec *pppsRequired,
								   ULONG child_index, BOOL fNLJoin)
{
	CPartIndexMap *ppim = pppsRequired->Ppim();
	CPartFilterMap *ppfm = pppsRequired->Ppfm();

	ULongPtrArray *pdrgpul = ppim->PdrgpulScanIds(mp);

	CPartIndexMap *ppimResult = GPOS_NEW(mp) CPartIndexMap(mp);
	CPartFilterMap *ppfmResult = GPOS_NEW(mp) CPartFilterMap(mp);

	// get outer partition consumers
	CPartInfo *ppartinfo = exprhdl.DerivePartitionInfo(0);

	CColRefSet *pcrsOutputOuter = exprhdl.DeriveOutputColumns(0);
	CColRefSet *pcrsOutputInner = exprhdl.DeriveOutputColumns(1);

	// the original join predicate for index NLJs, those just have a "true"
	// join predicate which isn't very useful for DPE
	CExpression *origJoinPredForIndexNLJ = NULL;

	switch (Eopid())
	{
		case COperator::EopPhysicalInnerIndexNLJoin:
			origJoinPredForIndexNLJ =
				CPhysicalInnerIndexNLJoin::PopConvert(this)->OrigJoinPred();
			break;

		case COperator::EopPhysicalLeftOuterIndexNLJoin:
			origJoinPredForIndexNLJ =
				CPhysicalLeftOuterIndexNLJoin::PopConvert(this)->OrigJoinPred();
			break;

		default:
			// no original join pred to worry about
			break;
	}

	const ULONG ulPartIndexIds = pdrgpul->Size();

	for (ULONG ul = 0; ul < ulPartIndexIds; ul++)
	{
		ULONG part_idx_id = *((*pdrgpul)[ul]);

		if (ppfm->FContainsScanId(part_idx_id))
		{
			GPOS_ASSERT(NULL != ppfm->Pexpr(part_idx_id));
			// a selection-based propagation request pushed from above: do not propagate any
			// further as the join will reduce cardinality and thus may select more partitions
			// for scanning
			continue;
		}

		BOOL fOuterPartConsumer = ppartinfo->FContainsScanId(part_idx_id);

		// in order to find interesting join predicates that can be used for DPE,
		// one side of the predicate must be the partition key, while the other side must only contain
		// references from the join child that does not have the partition consumer
		CColRefSet *pcrsAllowedRefs = pcrsOutputOuter;
		if (fOuterPartConsumer)
		{
			pcrsAllowedRefs = pcrsOutputInner;
		}

		if (fNLJoin)
		{
			if (0 == child_index && fOuterPartConsumer)
			{
				// always push through required partition propagation for consumers on the
				// outer side of the nested loop join
				CPartKeysArray *pdrgppartkeys =
					ppartinfo->PdrgppartkeysByScanId(part_idx_id);
				if (NULL == pdrgppartkeys)
				{
					continue;
				}
				pdrgppartkeys->AddRef();

				ppimResult->AddRequiredPartPropagation(
					ppim, part_idx_id, CPartIndexMap::EppraPreservePropagators,
					pdrgppartkeys);
			}
			else
			{
				// check if there is an interesting condition involving the partition key
				CExpression *pexprScalar =
					exprhdl.PexprScalarExactChild(2 /*child_index*/);

				if (NULL != origJoinPredForIndexNLJ &&
					CUtils::FScalarConstTrue(pexprScalar))
				{
					// use the original join predicate, not the "true" expression of the
					// index nested loop join, for dynamic partition elimination
					pexprScalar = origJoinPredForIndexNLJ;
				}

				AddFilterOnPartKey(mp, true /*fNLJoin*/, pexprScalar, ppim,
								   ppfm, child_index, part_idx_id,
								   fOuterPartConsumer, ppimResult, ppfmResult,
								   pcrsAllowedRefs);
			}
		}
		else
		{
			if (1 == child_index && !fOuterPartConsumer)
			{
				// always push through required partition propagation for consumers on the
				// inner side of the hash join
				CPartKeysArray *pdrgppartkeys =
					exprhdl.DerivePartitionInfo(1)->PdrgppartkeysByScanId(
						part_idx_id);
				if (NULL == pdrgppartkeys)
				{
					continue;
				}
				pdrgppartkeys->AddRef();

				ppimResult->AddRequiredPartPropagation(
					ppim, part_idx_id, CPartIndexMap::EppraPreservePropagators,
					pdrgppartkeys);
			}
			else
			{
				// look for a filter on the part key
				CExpression *pexprScalar =
					exprhdl.PexprScalarExactChild(2 /*child_index*/);
				AddFilterOnPartKey(mp, false /*fNLJoin*/, pexprScalar, ppim,
								   ppfm, child_index, part_idx_id,
								   fOuterPartConsumer, ppimResult, ppfmResult,
								   pcrsAllowedRefs);
			}
		}
	}

	pdrgpul->Release();

	return GPOS_NEW(mp) CPartitionPropagationSpec(ppimResult, ppfmResult);
}

// Compute required partition propagation of the n-th child
CPartitionPropagationSpec *
CPhysicalJoin::PppsRequiredJoinChild(CMemoryPool *mp,
									 CExpressionHandle &exprhdl,
									 CPartitionPropagationSpec *pppsRequired,
									 ULONG child_index,
									 CDrvdPropArray *,	//pdrgpdpCtxt,
									 BOOL fNLJoin)
{
	GPOS_ASSERT(NULL != pppsRequired);

	CPartPropReq *pppr = PpprCreate(mp, exprhdl, pppsRequired, child_index);
	if (NULL == pppr)
	{
		return PppsRequiredCompute(mp, exprhdl, pppsRequired, child_index,
								   fNLJoin);
	}

	// try to find a previously generated CPartitionPropagationSpec in the cache, m_phmpp
	CPartitionPropagationSpec *ppps = m_phmpp->Find(pppr);
	if (NULL == ppps)
	{
		ppps = PppsRequiredCompute(mp, exprhdl, pppsRequired, child_index,
								   fNLJoin);
#ifdef GPOS_DEBUG
		BOOL fSuccess =
#endif	// GPOS_DEBUG
			m_phmpp->Insert(pppr, ppps);
		GPOS_ASSERT(fSuccess);
	}
	else
	{
		pppr->Release();
	}

	ppps->AddRef();
	return ppps;
}

// EOF
