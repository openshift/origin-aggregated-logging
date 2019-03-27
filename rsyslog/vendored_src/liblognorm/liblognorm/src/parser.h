/*
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2015 by Rainer Gerhards and Adiscon GmbH.
 *
 * Modified by Pavel Levshin (pavel@levshin.spb.ru) in 2013
 *
 * This file is part of liblognorm.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * A copy of the LGPL v2.1 can be found in the file "COPYING" in this distribution.
 */
#ifndef LIBLOGNORM_PARSER_H_INCLUDED
#define	LIBLOGNORM_PARSER_H_INCLUDED
#include "pdag.h"

/**
 * Parser interface
 * @param[in] str the to-be-parsed string
 * @param[in] strLen length of the to-be-parsed string
 * @param[in] offs an offset into the string
 * @param[out] parsed bytes
 * @param[out] ptr to json object containing parsed data (can be unused)
 *             if NULL on input, object is NOT persisted
 * @return 0 on success, something else otherwise
 */
// TODO #warning check how to handle "value" - does it need to be set to NULL?

#define PARSERDEF_NO_DATA(parser) \
	int ln_v2_parse##parser(npb_t *npb, size_t *offs, void *const, size_t *parsed, struct json_object **value)

#define PARSERDEF(parser) \
	int ln_construct##parser(ln_ctx ctx, json_object *const json, void **pdata); \
	int ln_v2_parse##parser(npb_t *npb, size_t *offs, void *const, size_t *parsed, struct json_object **value); \
	void ln_destruct##parser(ln_ctx ctx, void *const pdata)

PARSERDEF(RFC5424Date);
PARSERDEF(RFC3164Date);
PARSERDEF(Number);
PARSERDEF(Float);
PARSERDEF(HexNumber);
PARSERDEF_NO_DATA(KernelTimestamp);
PARSERDEF_NO_DATA(Whitespace);
PARSERDEF_NO_DATA(Word);
PARSERDEF(StringTo);
PARSERDEF_NO_DATA(Alpha);
PARSERDEF(Literal);
PARSERDEF(CharTo);
PARSERDEF(CharSeparated);
PARSERDEF(Repeat);
PARSERDEF(String);
PARSERDEF_NO_DATA(Rest);
PARSERDEF_NO_DATA(OpQuotedString);
PARSERDEF_NO_DATA(QuotedString);
PARSERDEF_NO_DATA(ISODate);
PARSERDEF_NO_DATA(Time12hr);
PARSERDEF_NO_DATA(Time24hr);
PARSERDEF_NO_DATA(Duration);
PARSERDEF_NO_DATA(IPv4);
PARSERDEF_NO_DATA(IPv6);
PARSERDEF_NO_DATA(JSON);
PARSERDEF_NO_DATA(CEESyslog);
PARSERDEF_NO_DATA(v2IPTables);
PARSERDEF_NO_DATA(CiscoInterfaceSpec);
PARSERDEF_NO_DATA(MAC48);
PARSERDEF_NO_DATA(CEF);
PARSERDEF_NO_DATA(CheckpointLEA);
PARSERDEF_NO_DATA(NameValue);

#undef PARSERDEF_NO_DATA

/* utility functions */
int ln_combineData_Literal(void *const org, void *const add);

/* definitions for friends */
struct data_Repeat {
	ln_pdag *parser;
	ln_pdag *while_cond;
	int permitMismatchInParser;
};

#endif /* #ifndef LIBLOGNORM_PARSER_H_INCLUDED */
