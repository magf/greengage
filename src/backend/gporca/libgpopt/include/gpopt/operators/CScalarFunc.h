//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2011 EMC Corp.
//
//	@filename:
//		CScalarFunc.h
//
//	@doc:
//		Class for scalar function calls
//---------------------------------------------------------------------------
#ifndef GPOPT_CScalarFunc_H
#define GPOPT_CScalarFunc_H

#include "gpos/base.h"

#include "gpopt/base/CDrvdProp.h"
#include "gpopt/base/COptCtxt.h"
#include "gpopt/operators/CScalar.h"
#include "naucrates/md/IMDId.h"

namespace gpopt
{
using namespace gpos;
using namespace gpmd;

//---------------------------------------------------------------------------
//	@class:
//		CScalarFunc
//
//	@doc:
//		scalar function operator
//
//---------------------------------------------------------------------------
class CScalarFunc : public CScalar
{
protected:
	// func id
	IMDId *m_func_mdid;

	// return type
	IMDId *m_return_type_mdid;

	const INT m_return_type_modifier;

	// function name
	const CWStringConst *m_pstrFunc;

	// function stability
	IMDFunction::EFuncStbl m_efs;

	// can the function return multiple rows?
	BOOL m_returns_set;

	// does operator return NULL on NULL input?
	BOOL m_returns_null_on_null_input;

	// is operator return type BOOL?
	BOOL m_fBoolReturnType;

	//  It is true if in the function, variadic arguments have been
	//	combined into an array last argument
	BOOL m_funcvariadic;

private:
	// private copy ctor
	CScalarFunc(const CScalarFunc &);


public:
	explicit CScalarFunc(CMemoryPool *mp);

	// ctor
	CScalarFunc(CMemoryPool *mp, IMDId *mdid_func, IMDId *mdid_return_type,
				INT return_type_modifier, const CWStringConst *pstrFunc,
				BOOL funcvariadic);

	// dtor
	virtual ~CScalarFunc();

	// ident accessors
	virtual EOperatorId
	Eopid() const
	{
		return EopScalarFunc;
	}

	// return a string for operator name
	virtual const CHAR *
	SzId() const
	{
		return "CScalarFunc";
	}

	// operator specific hash function
	ULONG HashValue() const;

	// match function
	BOOL Matches(COperator *pop) const;

	// sensitivity to order of inputs
	BOOL
	FInputOrderSensitive() const
	{
		return true;
	}

	// return a copy of the operator with remapped columns
	virtual COperator *
	PopCopyWithRemappedColumns(CMemoryPool *,		//mp,
							   UlongToColRefMap *,	//colref_mapping,
							   BOOL					//must_exist
	)
	{
		return PopCopyDefault();
	}

	// derive function properties
	virtual CFunctionProp *
	DeriveFunctionProperties(CMemoryPool *mp, CExpressionHandle &exprhdl) const
	{
		return PfpDeriveFromChildren(mp, exprhdl, m_efs,
									 false /*fHasVolatileFunctionScan*/,
									 false /*fScan*/);
	}

	// derive non-scalar function existence
	virtual BOOL FHasNonScalarFunction(CExpressionHandle &exprhdl);

	// conversion function
	static CScalarFunc *
	PopConvert(COperator *pop)
	{
		GPOS_ASSERT(NULL != pop);
		GPOS_ASSERT(EopScalarFunc == pop->Eopid());

		return reinterpret_cast<CScalarFunc *>(pop);
	}


	// function name
	const CWStringConst *PstrFunc() const;

	// func id
	IMDId *FuncMdId() const;

	virtual INT TypeModifier() const;

	// the type of the scalar expression
	virtual IMDId *MdidType() const;

	// function stability
	IMDFunction::EFuncStbl EfsGetFunctionStability() const;

	// boolean expression evaluation
	virtual EBoolEvalResult Eber(ULongPtrArray *pdrgpulChildren) const;

	// print
	virtual IOstream &OsPrint(IOstream &os) const;

	// Is variadic flag set
	BOOL IsFuncVariadic() const;


};	// class CScalarFunc

}  // namespace gpopt


#endif	// !GPOPT_CScalarFunc_H

// EOF
