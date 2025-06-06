//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2013 EMC Corp.
//
//	@filename:
//		CIOUtils.h
//
//	@doc:
//		Optimizer I/O utility functions
//---------------------------------------------------------------------------
#ifndef GPOPT_CIOUtils_H
#define GPOPT_CIOUtils_H

#include "gpos/base.h"

namespace gpopt
{
using namespace gpos;

//---------------------------------------------------------------------------
//	@class:
//		CIOUtils
//
//	@doc:
//		Optimizer I/O utility functions
//
//---------------------------------------------------------------------------
class CIOUtils
{
public:
	// dump given string to output file
	static void Dump(CHAR *file_name, CHAR *sz);

};	// class CIOUtils
}  // namespace gpopt


#endif	// !GPOPT_CIOUtils_H

// EOF
