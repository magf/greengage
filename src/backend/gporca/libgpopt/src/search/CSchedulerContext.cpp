//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2008-2011 Greenplum, Inc.
//
//	@filename:
//		CSchedulerContext.cpp
//
//	@doc:
//		Implementation of optimizer job scheduler
//---------------------------------------------------------------------------

#include "gpopt/search/CSchedulerContext.h"

#include "gpos/base.h"
#include "gpos/memory/CMemoryPoolManager.h"

#include "gpopt/engine/CEngine.h"
#include "gpopt/search/CScheduler.h"


using namespace gpos;
using namespace gpopt;


//---------------------------------------------------------------------------
//	@function:
//		CSchedulerContext::CSchedulerContext
//
//	@doc:
//		Ctor
//
//---------------------------------------------------------------------------
CSchedulerContext::CSchedulerContext()
	: m_pmpGlobal(NULL), m_pmpLocal(NULL), m_psched(NULL), m_fInit(false)
{
}


//---------------------------------------------------------------------------
//	@function:
//		CSchedulerContext::~CSchedulerContext
//
//	@doc:
//		Dtor
//
//---------------------------------------------------------------------------
CSchedulerContext::~CSchedulerContext()
{
	GPOS_ASSERT_IMP(FInit(), NULL != GetGlobalMemoryPool());
	GPOS_ASSERT_IMP(FInit(), NULL != PmpLocal());
	GPOS_ASSERT_IMP(FInit(), NULL != Psched());

	// release local memory pool
	if (FInit())
	{
		CMemoryPoolManager::GetMemoryPoolMgr()->Destroy(PmpLocal());
	}
}


//---------------------------------------------------------------------------
//	@function:
//		CSchedulerContext::Init
//
//	@doc:
//		Initialize scheduling context
//
//---------------------------------------------------------------------------
void
CSchedulerContext::Init(CMemoryPool *pmpGlobal, CJobFactory *pjf,
						CScheduler *psched, CEngine *peng)
{
	GPOS_ASSERT(NULL != pmpGlobal);
	GPOS_ASSERT(NULL != pjf);
	GPOS_ASSERT(NULL != psched);
	GPOS_ASSERT(NULL != peng);

	GPOS_ASSERT(!FInit() && "Scheduling context is already initialized");

	m_pmpLocal = CMemoryPoolManager::GetMemoryPoolMgr()->CreateMemoryPool();

	m_pmpGlobal = pmpGlobal;
	m_pjf = pjf;
	m_psched = psched;
	m_peng = peng;
	m_fInit = true;
}


// EOF
