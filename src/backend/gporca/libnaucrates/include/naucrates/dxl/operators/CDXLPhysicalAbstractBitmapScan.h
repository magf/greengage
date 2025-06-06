//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2014 Pivotal, Inc.
//
//	@filename:
//		CDXLPhysicalAbstractBitmapScan.h
//
//	@doc:
//		Parent class for representing DXL bitmap table scan operators,
//		both not partitioned and dynamic.
//---------------------------------------------------------------------------

#ifndef GPDXL_CDXLPhysicalAbstractBitmapScan_H
#define GPDXL_CDXLPhysicalAbstractBitmapScan_H

#include "gpos/base.h"

#include "naucrates/dxl/operators/CDXLPhysical.h"

namespace gpdxl
{
using namespace gpos;

enum Edxlbs
{
	EdxlbsIndexProjList = 0,
	EdxlbsIndexFilter,
	EdxlbsIndexRecheckCond,
	EdxlbsIndexBitmap,
	EdxlbsSentinel
};

// fwd declarations
class CDXLTableDescr;
class CXMLSerializer;

//---------------------------------------------------------------------------
//	@class:
//		CDXLPhysicalAbstractBitmapScan
//
//	@doc:
//		Parent class for representing DXL bitmap table scan operators, both not
//		partitioned and dynamic.
//
//---------------------------------------------------------------------------
class CDXLPhysicalAbstractBitmapScan : public CDXLPhysical
{
private:
	// private copy ctor
	CDXLPhysicalAbstractBitmapScan(const CDXLPhysicalAbstractBitmapScan &);

protected:
	// table descriptor for the scanned table
	CDXLTableDescr *m_dxl_table_descr;

public:
	// ctor
	CDXLPhysicalAbstractBitmapScan(CMemoryPool *mp, CDXLTableDescr *table_descr)
		: CDXLPhysical(mp), m_dxl_table_descr(table_descr)
	{
		GPOS_ASSERT(NULL != table_descr);
	}

	// dtor
	virtual ~CDXLPhysicalAbstractBitmapScan();

	// table descriptor
	const CDXLTableDescr *
	GetDXLTableDescr()
	{
		return m_dxl_table_descr;
	}

#ifdef GPOS_DEBUG
	// checks whether the operator has valid structure, i.e. number and
	// types of child nodes
	virtual void AssertValid(const CDXLNode *node,
							 BOOL validate_children) const;
#endif	// GPOS_DEBUG
};		// class CDXLPhysicalAbstractBitmapScan
}  // namespace gpdxl

#endif	// !GPDXL_CDXLPhysicalAbstractBitmapScan_H

// EOF
