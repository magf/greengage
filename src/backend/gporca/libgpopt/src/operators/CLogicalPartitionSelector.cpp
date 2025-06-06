//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2014 Pivotal Inc.
//
//	@filename:
//		CLogicalPartitionSelector.cpp
//
//	@doc:
//		Implementation of Logical partition selector
//---------------------------------------------------------------------------

#include "gpopt/operators/CLogicalPartitionSelector.h"

#include "gpos/base.h"

#include "gpopt/base/CDistributionSpecAny.h"
#include "gpopt/base/COptCtxt.h"
#include "gpopt/base/CUtils.h"
#include "gpopt/operators/CExpressionHandle.h"

using namespace gpopt;

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::CLogicalPartitionSelector
//
//	@doc:
//		Ctor - for pattern
//
//---------------------------------------------------------------------------
CLogicalPartitionSelector::CLogicalPartitionSelector(CMemoryPool *mp)
	: CLogical(mp), m_mdid(NULL), m_pdrgpexprFilters(NULL)
{
	m_fPattern = true;
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::CLogicalPartitionSelector
//
//	@doc:
//		Ctor
//
//---------------------------------------------------------------------------
CLogicalPartitionSelector::CLogicalPartitionSelector(
	CMemoryPool *mp, IMDId *mdid, CExpressionArray *pdrgpexprFilters)
	: CLogical(mp), m_mdid(mdid), m_pdrgpexprFilters(pdrgpexprFilters)
{
	GPOS_ASSERT(mdid->IsValid());
	GPOS_ASSERT(NULL != pdrgpexprFilters);
	GPOS_ASSERT(0 < pdrgpexprFilters->Size());
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::~CLogicalPartitionSelector
//
//	@doc:
//		Dtor
//
//---------------------------------------------------------------------------
CLogicalPartitionSelector::~CLogicalPartitionSelector()
{
	CRefCount::SafeRelease(m_mdid);
	CRefCount::SafeRelease(m_pdrgpexprFilters);
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::Matches
//
//	@doc:
//		Match operators
//
//---------------------------------------------------------------------------
BOOL
CLogicalPartitionSelector::Matches(COperator *pop) const
{
	if (Eopid() != pop->Eopid())
	{
		return false;
	}

	CLogicalPartitionSelector *popPartSelector =
		CLogicalPartitionSelector::PopConvert(pop);

	return popPartSelector->MDId()->Equals(m_mdid) &&
		   popPartSelector->m_pdrgpexprFilters->Equals(m_pdrgpexprFilters);
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::HashValue
//
//	@doc:
//		Hash operator
//
//---------------------------------------------------------------------------
ULONG
CLogicalPartitionSelector::HashValue() const
{
	return gpos::CombineHashes(Eopid(), m_mdid->HashValue());
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::PopCopyWithRemappedColumns
//
//	@doc:
//		Return a copy of the operator with remapped columns
//
//---------------------------------------------------------------------------
COperator *
CLogicalPartitionSelector::PopCopyWithRemappedColumns(
	CMemoryPool *mp, UlongToColRefMap *colref_mapping, BOOL /* must_exist */)
{
	CExpressionArray *pdrgpexpr =
		CUtils::PdrgpexprRemap(mp, m_pdrgpexprFilters, colref_mapping);

	m_mdid->AddRef();

	return GPOS_NEW(mp) CLogicalPartitionSelector(mp, m_mdid, pdrgpexpr);
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::DeriveOutputColumns
//
//	@doc:
//		Derive output columns
//
//---------------------------------------------------------------------------
CColRefSet *
CLogicalPartitionSelector::DeriveOutputColumns(CMemoryPool *mp,
											   CExpressionHandle &exprhdl)
{
	CColRefSet *pcrsOutput = GPOS_NEW(mp) CColRefSet(mp);

	pcrsOutput->Union(exprhdl.DeriveOutputColumns(0));

	return pcrsOutput;
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::DeriveMaxCard
//
//	@doc:
//		Derive max card
//
//---------------------------------------------------------------------------
CMaxCard
CLogicalPartitionSelector::DeriveMaxCard(CMemoryPool *,	 // mp
										 CExpressionHandle &exprhdl) const
{
	// pass on max card of first child
	return exprhdl.DeriveMaxCard(0);
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::PxfsCandidates
//
//	@doc:
//		Get candidate xforms
//
//---------------------------------------------------------------------------
CXformSet *
CLogicalPartitionSelector::PxfsCandidates(CMemoryPool *mp) const
{
	CXformSet *xform_set = GPOS_NEW(mp) CXformSet(mp);
	(void) xform_set->ExchangeSet(CXform::ExfImplementPartitionSelector);
	return xform_set;
}

//---------------------------------------------------------------------------
//	@function:
//		CLogicalPartitionSelector::OsPrint
//
//	@doc:
//		Debug print
//
//---------------------------------------------------------------------------
IOstream &
CLogicalPartitionSelector::OsPrint(IOstream &os) const
{
	os << SzId() << ", Part Table: ";
	m_mdid->OsPrint(os);

	return os;
}

// EOF
