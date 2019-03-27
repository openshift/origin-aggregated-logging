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
#ifndef LIBLOGNORM_V1_PARSER_H_INCLUDED
#define	LIBLOGNORM_V1_PARSER_H_INCLUDED
#include "v1_ptree.h"


/**
 * Parser interface
 * @param[in] str the to-be-parsed string
 * @param[in] strLen length of the to-be-parsed string
 * @param[in] offs an offset into the string
 * @param[in] node fieldlist with additional data; for simple
 *            parsers, this sets variable "ed", which just is
 *            string data.
 * @param[out] parsed bytes
 * @param[out] json object containing parsed data (can be unused)
 * @return 0 on success, something else otherwise
 */

/**
 * Parser for RFC5424 date.
 */
int ln_parseRFC5424Date(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for RFC3164 date.
 */
int ln_parseRFC3164Date(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for numbers.
 */
int ln_parseNumber(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for real-number in floating-pt representation
 */
int ln_parseFloat(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for hex numbers.
 */
int ln_parseHexNumber(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);


/**
 * Parser for kernel timestamps.
 */
int ln_parseKernelTimestamp(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for whitespace
 */
int ln_parseWhitespace(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);


/**
 * Parser for Words (SP-terminated strings).
 */
int ln_parseWord(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);


/**
 * Parse everything up to a specific string.
 */
int ln_parseStringTo(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for Alphabetic words (no numbers, punct, ctrl, space).
 */
int ln_parseAlpha(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);


/**
 * Parse everything up to a specific character.
 */
int ln_parseCharTo(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse everything up to a specific character (relaxed constraints, suitable for CSV)
 */
int ln_parseCharSeparated(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);


/**
 * Get everything till the rest of string.
 */
int ln_parseRest(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse an optionally quoted string.
 */
int ln_parseOpQuotedString(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node,
size_t *parsed, struct json_object **value);

/**
 * Parse a quoted string.
 */
int ln_parseQuotedString(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse an ISO date.
 */
int ln_parseISODate(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);


/**
 * Parse a timestamp in 12hr format.
 */
int ln_parseTime12hr(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse a timestamp in 24hr format.
 */
int ln_parseTime24hr(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse a duration.
 */
int ln_parseDuration(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for IPv4 addresses.
 */
int ln_parseIPv4(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for IPv6 addresses.
 */
int ln_parseIPv6(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse JSON.
 */
int ln_parseJSON(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse cee syslog.
 */
int ln_parseCEESyslog(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parse iptables log, the new way
 */
int ln_parsev2IPTables(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser Cisco interface specifiers
 */
int ln_parseCiscoInterfaceSpec(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node,
size_t *parsed, struct json_object **value);

/**
 * Parser 48 bit MAC layer addresses.
 */
int ln_parseMAC48(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for CEF version 0.
 */
int ln_parseCEF(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for Checkpoint LEA.
 */
int ln_parseCheckpointLEA(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Parser for name/value pairs.
 */
int ln_parseNameValue(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

/**
 * Get all tokens separated by tokenizer-string as array.
 */
int ln_parseTokenized(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

void* tokenized_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void tokenized_parser_data_destructor(void** dataPtr);

#ifdef FEATURE_REGEXP
/**
 * Get field matching regex
 */
int ln_parseRegex(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

void* regex_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void regex_parser_data_destructor(void** dataPtr);
#endif

/**
 * Match using the 'current' or 'separate rulebase' all over again from current match position
 */
int ln_parseRecursive(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

void* recursive_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void* descent_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void recursive_parser_data_destructor(void** dataPtr);

/**
 * Get interpreted field
 */
int ln_parseInterpret(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node,
size_t *parsed, struct json_object **value);

void* interpret_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void interpret_parser_data_destructor(void** dataPtr);

/**
 * Parse a suffixed field
 */
int ln_parseSuffixed(const char *str, size_t strlen, size_t *offs, const ln_fieldList_t *node, size_t *parsed,
struct json_object **value);

void* suffixed_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void* named_suffixed_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx);
void suffixed_parser_data_destructor(void** dataPtr);

#endif /* #ifndef LIBLOGNORM_V1_PARSER_H_INCLUDED */
