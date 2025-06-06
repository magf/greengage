//---------------------------------------------------------------------------
//	Greengage Database
//	Copyright (C) 2008 Greenplum, Inc.
//
//	@filename:
//		CWStringDynamic.cpp
//
//	@doc:
//		Implementation of the wide character string class
//		with dynamic buffer allocation.
//---------------------------------------------------------------------------

#include "gpos/string/CWStringDynamic.h"

#include "gpos/common/CAutoRg.h"
#include "gpos/common/clibwrapper.h"
#include "gpos/string/CStringStatic.h"
using namespace gpos;


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::CWStringDynamic
//
//	@doc:
//		Constructs an empty string
//
//---------------------------------------------------------------------------
CWStringDynamic::CWStringDynamic(CMemoryPool *mp)
	: CWString(0  // length
			   ),
	  m_mp(mp),
	  m_capacity(0)
{
	Reset();
}

//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::CWStringDynamic
//
//	@doc:
//		Constructs a new string and initializes it with the given buffer
//
//---------------------------------------------------------------------------
CWStringDynamic::CWStringDynamic(CMemoryPool *mp, const WCHAR *w_str_buffer)
	: CWString(GPOS_WSZ_LENGTH(w_str_buffer)), m_mp(mp), m_capacity(0)
{
	GPOS_ASSERT(NULL != w_str_buffer);

	Reset();
	AppendBuffer(w_str_buffer);
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::~CWStringDynamic
//
//	@doc:
//		Dtor
//
//---------------------------------------------------------------------------
CWStringDynamic::~CWStringDynamic()
{
	Reset();
}


//---------------------------------------------------------------------------
//	@function:
//		CWString::Reset
//
//	@doc:
//		Resets string
//
//---------------------------------------------------------------------------
void
CWStringDynamic::Reset()
{
	if (NULL != m_w_str_buffer && &m_empty_wcstr != m_w_str_buffer)
	{
		GPOS_DELETE_ARRAY(m_w_str_buffer);
	}

	m_w_str_buffer = const_cast<WCHAR *>(&m_empty_wcstr);
	m_length = 0;
	m_capacity = 0;
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::AppendBuffer
//
//	@doc:
//		Appends the contents of a buffer to the current string
//
//---------------------------------------------------------------------------
void
CWStringDynamic::AppendBuffer(const WCHAR *w_str)
{
	GPOS_ASSERT(NULL != w_str);
	ULONG length = GPOS_WSZ_LENGTH(w_str);
	if (0 == length)
	{
		return;
	}

	// expand buffer if needed
	ULONG new_length = m_length + length;
	if (new_length + 1 > m_capacity)
	{
		IncreaseCapacity(new_length);
	}

	clib::WcStrNCpy(m_w_str_buffer + m_length, w_str, length + 1);
	m_length = new_length;
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::AppendWideCharArray
//
//	@doc:
//		Appends a a null terminated wide character array
//
//---------------------------------------------------------------------------
void
CWStringDynamic::AppendWideCharArray(const WCHAR *w_str)
{
	AppendBuffer(w_str);
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::AppendCharArray
//
//	@doc:
//		Appends a a null terminated character array
//
//---------------------------------------------------------------------------
void
CWStringDynamic::AppendCharArray(const CHAR *sz)
{
	GPOS_ASSERT(NULL != sz);

	// expand buffer if needed
	const ULONG length = GPOS_SZ_LENGTH(sz);
	ULONG new_length = m_length + length;
	if (new_length + 1 > m_capacity)
	{
		IncreaseCapacity(new_length);
	}
	WCHAR *w_str_buffer = GPOS_NEW_ARRAY(m_mp, WCHAR, length + 1);

	// convert input string to wide character buffer
#ifdef GPOS_DEBUG
	ULONG wide_length =
#endif	// GPOS_DEBUG
		clib::Mbstowcs(w_str_buffer, sz, length);
	GPOS_ASSERT(wide_length == length);

	// append input string to current end of buffer
	(void) clib::Wmemcpy(m_w_str_buffer + m_length, w_str_buffer, length + 1);
	GPOS_DELETE_ARRAY(w_str_buffer);

	m_w_str_buffer[new_length] = WCHAR_EOS;
	m_length = new_length;

	GPOS_ASSERT(IsValid());
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::AppendFormat
//
//	@doc:
//		Appends a formatted string
//
//---------------------------------------------------------------------------
void
CWStringDynamic::AppendFormat(const WCHAR *format, ...)
{
	GPOS_ASSERT(NULL != format);
	using clib::Vswprintf;

	VA_LIST va_args;

	// determine length of format string after expansion
	INT res = -1;

	// attempt to fit the formatted string in a static array
	WCHAR w_str_buf_static[GPOS_WSTR_DYNAMIC_STATIC_BUFFER];

	// get arguments
	VA_START(va_args, format);

	// try expanding the formatted string in the buffer
	res = Vswprintf(w_str_buf_static, GPOS_ARRAY_SIZE(w_str_buf_static), format,
					va_args);

	// reset arguments
	VA_END(va_args);
	GPOS_ASSERT(-1 <= res);

	// estimated number of characters in expanded format string
	ULONG size =
		std::max(GPOS_WSZ_LENGTH(format), GPOS_ARRAY_SIZE(w_str_buf_static));

	// if the static buffer is too small, find the formatted string
	// length by trying to store it in a buffer of increasing size
	while (-1 == res)
	{
		// try with a bigger buffer this time
		size *= 2;
		CAutoRg<WCHAR> a_w_str_buff;
		a_w_str_buff = GPOS_NEW_ARRAY(m_mp, WCHAR, size + 1);

		// get arguments
		VA_START(va_args, format);

		// try expanding the formatted string in the buffer
		res = Vswprintf(a_w_str_buff.Rgt(), size, format, va_args);

		// reset arguments
		VA_END(va_args);

		GPOS_ASSERT(-1 <= res);
	}
	// verify required buffer was not bigger than allowed
	GPOS_ASSERT(res >= 0);

	// expand buffer if needed
	ULONG new_length = m_length + ULONG(res);
	if (new_length + 1 > m_capacity)
	{
		IncreaseCapacity(new_length);
	}

	// get arguments
	VA_START(va_args, format);

	// print va_args to string
	Vswprintf(m_w_str_buffer + m_length, res + 1, format, va_args);

	// reset arguments
	VA_END(va_args);

	m_length = new_length;
	GPOS_ASSERT(IsValid());
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::AppendEscape
//
//	@doc:
//		Appends a string and replaces character with string
//
//---------------------------------------------------------------------------
void
CWStringDynamic::AppendEscape(const CWStringBase *str, WCHAR wc,
							  const WCHAR *w_str_replace)
{
	GPOS_ASSERT(NULL != str);

	if (str->IsEmpty())
	{
		return;
	}

	// count how many times the character to be escaped appears in the string
	ULONG occurrences = str->CountOccurrencesOf(wc);
	if (0 == occurrences)
	{
		Append(str);
		return;
	}

	ULONG length = str->Length();
	const WCHAR *w_str = str->GetBuffer();

	ULONG length_replace = GPOS_WSZ_LENGTH(w_str_replace);
	ULONG new_length = m_length + length + (length_replace - 1) * occurrences;
	if (new_length + 1 > m_capacity)
	{
		IncreaseCapacity(new_length);
	}

	// append new contents while replacing character with escaping string
	for (ULONG i = 0, j = m_length; i < length; i++)
	{
		if (wc == w_str[i] && !str->HasEscapedCharAt(i))
		{
			clib::WcStrNCpy(m_w_str_buffer + j, w_str_replace, length_replace);
			j += length_replace;
		}
		else
		{
			m_w_str_buffer[j++] = w_str[i];
		}
	}

	// terminate string
	m_w_str_buffer[new_length] = WCHAR_EOS;
	m_length = new_length;

	GPOS_ASSERT(IsValid());
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::IncreaseCapacity
//
//	@doc:
//		Increase string capacity
//
//---------------------------------------------------------------------------
void
CWStringDynamic::IncreaseCapacity(ULONG requested)
{
	GPOS_ASSERT(requested + 1 > m_capacity);

	ULONG capacity = Capacity(requested + 1);
	GPOS_ASSERT(capacity > requested + 1);
	GPOS_ASSERT(capacity >= (m_capacity << 1));

	CAutoRg<WCHAR> a_w_str_new_buff;
	a_w_str_new_buff = GPOS_NEW_ARRAY(m_mp, WCHAR, capacity);
	if (0 < m_length)
	{
		// current string is not empty: copy it to the resulting string
		a_w_str_new_buff =
			clib::WcStrNCpy(a_w_str_new_buff.Rgt(), m_w_str_buffer, m_length);
	}

	// release old buffer
	if (m_w_str_buffer != &m_empty_wcstr)
	{
		GPOS_DELETE_ARRAY(m_w_str_buffer);
	}
	m_w_str_buffer = a_w_str_new_buff.RgtReset();
	m_capacity = capacity;
}


//---------------------------------------------------------------------------
//	@function:
//		CWStringDynamic::Capacity
//
//	@doc:
//		Find capacity that fits requested string size
//
//---------------------------------------------------------------------------
ULONG
CWStringDynamic::Capacity(ULONG requested)
{
	ULONG capacity = GPOS_WSTR_DYNAMIC_CAPACITY_INIT;
	while (capacity <= requested + 1)
	{
		capacity = capacity << 1;
	}

	return capacity;
}


// EOF
