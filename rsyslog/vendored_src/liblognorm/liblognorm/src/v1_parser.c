/*
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2018 by Rainer Gerhards and Adiscon GmbH.
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
#include "config.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>
#include <sys/types.h>
#include <string.h>
#include <strings.h>

#include "v1_liblognorm.h"
#include "internal.h"
#include "lognorm.h"
#include "v1_parser.h"
#include "v1_samp.h"

#ifdef FEATURE_REGEXP
#include <pcre.h>
#include <errno.h>
#endif


/* some helpers */
static inline int
hParseInt(const unsigned char **buf, size_t *lenBuf)
{
	const unsigned char *p = *buf;
	size_t len = *lenBuf;
	int i = 0;

	while(len > 0 && isdigit(*p)) {
		i = i * 10 + *p - '0';
		++p;
		--len;
	}

	*buf = p;
	*lenBuf = len;
	return i;
}

/* parsers for the primitive types
 *
 * All parsers receive
 *
 * @param[in] str the to-be-parsed string
 * @param[in] strLen length of the to-be-parsed string
 * @param[in] offs an offset into the string
 * @param[in] node fieldlist with additional data; for simple
 *            parsers, this sets variable "ed", which just is
 *            string data.
 * @param[out] parsed bytes
 * @param[out] value ptr to json object containing parsed data
 *             (can be unused, but if used *value MUST be NULL on entry)
 *
 * They will try to parse out "their" object from the string. If they
 * succeed, they:
 *
 * return 0 on success and LN_WRONGPARSER if this parser could
 *           not successfully parse (but all went well otherwise) and something
 *           else in case of an error.
 */
#define PARSER(ParserName) \
int ln_parse##ParserName(const char *const str, const size_t strLen, \
	size_t *const offs,       \
	__attribute__((unused)) const ln_fieldList_t *node,  \
	size_t *parsed,                                      \
	__attribute__((unused)) struct json_object **value) \
{ \
	int r = LN_WRONGPARSER; \
	__attribute__((unused)) es_str_t *ed = node->data;  \
	*parsed = 0;

#define FAILParser \
	goto parserdone; /* suppress warnings */ \
parserdone: \
	r = 0; \
	goto done; /* suppress warnings */ \
done:

#define ENDFailParser \
	return r; \
}


/**
 * Utilities to allow constructors of complex parser's to
 *  easily process field-declaration arguments.
 */
#define FIELD_ARG_SEPERATOR ":"
#define MAX_FIELD_ARGS 10

struct pcons_args_s {
	int argc;
	char *argv[MAX_FIELD_ARGS];
};

typedef struct pcons_args_s pcons_args_t;

static void free_pcons_args(pcons_args_t** dat_p) {
	pcons_args_t *dat = *dat_p;
	*dat_p = NULL;
	if (! dat) {
	  return;
	}
	while((--(dat->argc)) >= 0) {
		if (dat->argv[dat->argc] != NULL) free(dat->argv[dat->argc]);
	}
	free(dat);
}

static pcons_args_t* pcons_args(es_str_t *args, int expected_argc) {
	pcons_args_t *dat = NULL;
	char* orig_str = NULL;
	if ((dat = malloc(sizeof(pcons_args_t))) == NULL) goto fail;
	dat->argc = 0;
	if (args != NULL) {
		orig_str = es_str2cstr(args, NULL);
		char *str = orig_str;
		while (dat->argc < MAX_FIELD_ARGS) {
			int i = dat->argc++;
			char *next = (dat->argc == expected_argc) ? NULL : strstr(str, FIELD_ARG_SEPERATOR);
			if (next == NULL) {
				if ((dat->argv[i] = strdup(str)) == NULL) goto fail;
				break;
			} else {
				if ((dat->argv[i] = strndup(str, next - str)) == NULL) goto fail;
				next++;
			}
			str = next;
		}
	}
	goto done;
fail:
	if (dat != NULL) free_pcons_args(&dat);
done:
	if (orig_str != NULL) free(orig_str);
	return dat;
}

static const char* pcons_arg(pcons_args_t *dat, int i, const char* dflt_val) {
	if (i >= dat->argc) return dflt_val;
	return dat->argv[i];
}

static char* pcons_arg_copy(pcons_args_t *dat, int i, const char* dflt_val) {
	const char *str = pcons_arg(dat, i, dflt_val);
	return (str == NULL) ? NULL : strdup(str);
}

static void pcons_unescape_arg(pcons_args_t *dat, int i) {
	char *arg = (char*) pcons_arg(dat, i, NULL);
	es_str_t *str = NULL;
	if (arg != NULL) {
		str = es_newStrFromCStr(arg, strlen(arg));
		if (str != NULL) {
			es_unescapeStr(str);
			free(arg);
			dat->argv[i] = es_str2cstr(str, NULL);
			es_deleteStr(str);
		}
	}
}

/**
 * Parse a TIMESTAMP as specified in RFC5424 (subset of RFC3339).
 */
PARSER(RFC5424Date)
	const unsigned char *pszTS;
	/* variables to temporarily hold time information while we parse */
	__attribute__((unused)) int year;
	int month;
	int day;
	int hour; /* 24 hour clock */
	int minute;
	int second;
	__attribute__((unused)) int secfrac;	/* fractional seconds (must be 32 bit!) */
	__attribute__((unused)) int secfracPrecision;
	int OffsetHour;		/* UTC offset in hours */
	int OffsetMinute;	/* UTC offset in minutes */
	size_t len;
	size_t orglen;
	/* end variables to temporarily hold time information while we parse */

	pszTS = (unsigned char*) str + *offs;
	len = orglen = strLen - *offs;

	year = hParseInt(&pszTS, &len);

	/* We take the liberty to accept slightly malformed timestamps e.g. in
	 * the format of 2003-9-1T1:0:0.  */
	if(len == 0 || *pszTS++ != '-') goto done;
	--len;
	month = hParseInt(&pszTS, &len);
	if(month < 1 || month > 12) goto done;

	if(len == 0 || *pszTS++ != '-')
		goto done;
	--len;
	day = hParseInt(&pszTS, &len);
	if(day < 1 || day > 31) goto done;

	if(len == 0 || *pszTS++ != 'T') goto done;
	--len;

	hour = hParseInt(&pszTS, &len);
	if(hour < 0 || hour > 23) goto done;

	if(len == 0 || *pszTS++ != ':')
		goto done;
	--len;
	minute = hParseInt(&pszTS, &len);
	if(minute < 0 || minute > 59) goto done;

	if(len == 0 || *pszTS++ != ':') goto done;
	--len;
	second = hParseInt(&pszTS, &len);
	if(second < 0 || second > 60) goto done;

	/* Now let's see if we have secfrac */
	if(len > 0 && *pszTS == '.') {
		--len;
		const unsigned char *pszStart = ++pszTS;
		secfrac = hParseInt(&pszTS, &len);
		secfracPrecision = (int) (pszTS - pszStart);
	} else {
		secfracPrecision = 0;
		secfrac = 0;
	}

	/* check the timezone */
	if(len == 0) goto done;

	if(*pszTS == 'Z') {
		--len;
		pszTS++; /* eat Z */
	} else if((*pszTS == '+') || (*pszTS == '-')) {
		--len;
		pszTS++;

		OffsetHour = hParseInt(&pszTS, &len);
		if(OffsetHour < 0 || OffsetHour > 23)
			goto done;

		if(len == 0 || *pszTS++ != ':')
			goto done;
		--len;
		OffsetMinute = hParseInt(&pszTS, &len);
		if(OffsetMinute < 0 || OffsetMinute > 59)
			goto done;
	} else {
		/* there MUST be TZ information */
		goto done;
	}

	if(len > 0) {
		if(*pszTS != ' ') /* if it is not a space, it can not be a "good" time */
			goto done;
	}

	/* we had success, so update parse pointer */
	*parsed = orglen - len;

	r = 0; /* success */
done:
	return r;
}


/**
 * Parse a RFC3164 Date.
 */
PARSER(RFC3164Date)
	const unsigned char *p;
	size_t len, orglen;
	/* variables to temporarily hold time information while we parse */
	__attribute__((unused)) int month;
	int day;
#if 0 /* TODO: why does this still exist? */
	int year = 0; /* 0 means no year provided */
#endif
	int hour; /* 24 hour clock */
	int minute;
	int second;

	p = (unsigned char*) str + *offs;
	orglen = len = strLen - *offs;
	/* If we look at the month (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec),
	 * we may see the following character sequences occur:
	 *
	 * J(an/u(n/l)), Feb, Ma(r/y), A(pr/ug), Sep, Oct, Nov, Dec
	 *
	 * We will use this for parsing, as it probably is the
	 * fastest way to parse it.
	 */
	if(len < 3)
		goto done;

	switch(*p++)
	{
	case 'j':
	case 'J':
		if(*p == 'a' || *p == 'A') {
			++p;
			if(*p == 'n' || *p == 'N') {
				++p;
				month = 1;
			} else
				goto done;
		} else if(*p == 'u' || *p == 'U') {
			++p;
			if(*p == 'n' || *p == 'N') {
				++p;
				month = 6;
			} else if(*p == 'l' || *p == 'L') {
				++p;
				month = 7;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'f':
	case 'F':
		if(*p == 'e' || *p == 'E') {
			++p;
			if(*p == 'b' || *p == 'B') {
				++p;
				month = 2;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'm':
	case 'M':
		if(*p == 'a' || *p == 'A') {
			++p;
			if(*p == 'r' || *p == 'R') {
				++p;
				month = 3;
			} else if(*p == 'y' || *p == 'Y') {
				++p;
				month = 5;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'a':
	case 'A':
		if(*p == 'p' || *p == 'P') {
			++p;
			if(*p == 'r' || *p == 'R') {
				++p;
				month = 4;
			} else
				goto done;
		} else if(*p == 'u' || *p == 'U') {
			++p;
			if(*p == 'g' || *p == 'G') {
				++p;
				month = 8;
			} else
				goto done;
		} else
			goto done;
		break;
	case 's':
	case 'S':
		if(*p == 'e' || *p == 'E') {
			++p;
			if(*p == 'p' || *p == 'P') {
				++p;
				month = 9;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'o':
	case 'O':
		if(*p == 'c' || *p == 'C') {
			++p;
			if(*p == 't' || *p == 'T') {
				++p;
				month = 10;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'n':
	case 'N':
		if(*p == 'o' || *p == 'O') {

			++p;
			if(*p == 'v' || *p == 'V') {
				++p;
				month = 11;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'd':
	case 'D':
		if(*p == 'e' || *p == 'E') {
			++p;
			if(*p == 'c' || *p == 'C') {
				++p;
				month = 12;
			} else
				goto done;
		} else
			goto done;
		break;
	default:
		goto done;
	}

	len -= 3;
	
	/* done month */

	if(len == 0 || *p++ != ' ')
		goto done;
	--len;

	/* we accept a slightly malformed timestamp with one-digit days. */
	if(*p == ' ') {
		--len;
		++p;
	}

	day = hParseInt(&p, &len);
	if(day < 1 || day > 31)
		goto done;

	if(len == 0 || *p++ != ' ')
		goto done;
	--len;

	/* time part */
	hour = hParseInt(&p, &len);
	if(hour > 1970 && hour < 2100) {
		/* if so, we assume this actually is a year. This is a format found
		 * e.g. in Cisco devices.
		 *
		year = hour;
		*/

		/* re-query the hour, this time it must be valid */
		if(len == 0 || *p++ != ' ')
			goto done;
		--len;
		hour = hParseInt(&p, &len);
	}

	if(hour < 0 || hour > 23)
		goto done;

	if(len == 0 || *p++ != ':')
		goto done;
	--len;
	minute = hParseInt(&p, &len);
	if(minute < 0 || minute > 59)
		goto done;

	if(len == 0 || *p++ != ':')
		goto done;
	--len;
	second = hParseInt(&p, &len);
	if(second < 0 || second > 60)
		goto done;

	/* we provide support for an extra ":" after the date. While this is an
	 * invalid format, it occurs frequently enough (e.g. with Cisco devices)
	 * to permit it as a valid case. -- rgerhards, 2008-09-12
	 */
	if(len > 0 && *p == ':') {
		++p; /* just skip past it */
		--len;
	}

	/* we had success, so update parse pointer */
	*parsed = orglen - len;

	r = 0; /* success */
done:
	return r;
}


/**
 * Parse a Number.
 * Note that a number is an abstracted concept. We always represent it
 * as 64 bits (but may later change our mind if performance dictates so).
 */
PARSER(Number)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;

	for (i = *offs; i < strLen && isdigit(c[i]); i++);
	if (i == *offs)
		goto done;
	
	/* success, persist */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a Real-number in floating-pt form.
 */
PARSER(Float)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;

	int seen_point = 0;

	i = *offs;

	if (c[i] == '-') i++;

	for (; i < strLen; i++) {
		if (c[i] == '.') {
			if (seen_point != 0) break;
			seen_point = 1;
		} else if (! isdigit(c[i])) {
			break;
		}
	}
	if (i == *offs)
		goto done;

	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */
done:
	return r;
}


/**
 * Parse a hex Number.
 * A hex number begins with 0x and contains only hex digits until the terminating
 * whitespace. Note that if a non-hex character is deteced inside the number string,
 * this is NOT considered to be a number.
 */
PARSER(HexNumber)
	const char *c;
	size_t i = *offs;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;

	if(c[i] != '0' || c[i+1] != 'x')
		goto done;

	for (i += 2 ; i < strLen && isxdigit(c[i]); i++);
	if (i == *offs || !isspace(c[i]))
		goto done;
	
	/* success, persist */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	return r;
}


/**
 * Parse a kernel timestamp.
 * This is a fixed format, see
 * https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/kernel/printk/printk.c?id=refs/tags/v4.0#n1011
 * This is the code that generates it:
 * sprintf(buf, "[%5lu.%06lu] ",  (unsigned long)ts, rem_nsec / 1000);
 * We accept up to 12 digits for ts, everything above that for sure is
 * no timestamp.
 */
#define LEN_KERNEL_TIMESTAMP 14
PARSER(KernelTimestamp)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;

	i = *offs;
	if(c[i] != '[' || i+LEN_KERNEL_TIMESTAMP > strLen
	   || !isdigit(c[i+1])
	   || !isdigit(c[i+2])
	   || !isdigit(c[i+3])
	   || !isdigit(c[i+4])
	   || !isdigit(c[i+5])
	   )
		goto done;
	i += 6;
	for(int j = 0 ; j < 7 && i < strLen && isdigit(c[i]) ; )
		++i, ++j;	/* just scan */

	if(i >= strLen || c[i] != '.')
		goto done;

	++i; /* skip over '.' */

	if( i+7 > strLen
	   || !isdigit(c[i+0])
	   || !isdigit(c[i+1])
	   || !isdigit(c[i+2])
	   || !isdigit(c[i+3])
	   || !isdigit(c[i+4])
	   || !isdigit(c[i+5])
	   || c[i+6] != ']'
	   )
		goto done;
	i += 7;

	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */
done:
	return r;
}

/**
 * Parse whitespace.
 * This parses all whitespace until the first non-whitespace character
 * is found. This is primarily a tool to skip to the next "word" if
 * the exact number of whitspace characters (and type of whitespace)
 * is not known. The current parsing position MUST be on a whitspace,
 * else the parser does not match.
 * This parser is also a forward-compatibility tool for the upcoming
 * slsa (simple log structure analyser) tool.
 */
PARSER(Whitespace)
	const char *c;
	size_t i = *offs;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;

	if(!isspace(c[i]))
		goto done;

	for (i++ ; i < strLen && isspace(c[i]); i++);
	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */
done:
	return r;
}


/**
 * Parse a word.
 * A word is a SP-delimited entity. The parser always works, except if
 * the offset is position on a space upon entry.
 */
PARSER(Word)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	/* search end of word */
	while(i < strLen && c[i] != ' ')
		i++;

	if(i == *offs)
		goto done;

	/* success, persist */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	return r;
}


/**
 * Parse everything up to a specific string.
 * swisskid, 2015-01-21
 */
PARSER(StringTo)
	const char *c;
	char *toFind = NULL;
	size_t i, j, k, m;
	int chkstr;
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	assert(ed != NULL);
	k = es_strlen(ed) - 1;
	toFind = es_str2cstr(ed, NULL);
	c = str;
	i = *offs;
	chkstr = 0;

	/* Total hunt for letter */
	while(chkstr == 0 && i < strLen ) {
	    i++;
	    if(c[i] == toFind[0]) {
		/* Found the first letter, now find the rest of the string */
		j = 0;
		m = i;
		while(m < strLen && j < k ) {
		    m++;
		    j++;
		    if(c[m] != toFind[j])
			break;
		    if (j == k)
			chkstr = 1;
		}
	    }
	}
	if(i == *offs || i == strLen || c[i] != toFind[0])
		goto done;

	/* success, persist */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	if(toFind != NULL) free(toFind);
	return r;
}

/**
 * Parse a alphabetic word.
 * A alpha word is composed of characters for which isalpha returns true.
 * The parser dones if there is no alpha character at all.
 */
PARSER(Alpha)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	/* search end of word */
	while(i < strLen && isalpha(c[i]))
		i++;

	if(i == *offs) {
		goto done;
	}

	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */
done:
	return r;
}


/**
 * Parse everything up to a specific character.
 * The character must be the only char inside extra data passed to the parser.
 * It is a program error if strlen(ed) != 1. It is considered a format error if
 * a) the to-be-parsed buffer is already positioned on the terminator character
 * b) there is no terminator until the end of the buffer
 * In those cases, the parsers declares itself as not being successful, in all
 * other cases a string is extracted.
 */
PARSER(CharTo)
	const char *c;
	unsigned char cTerm;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	assert(es_strlen(ed) == 1);
	cTerm = *(es_getBufAddr(ed));
	c = str;
	i = *offs;

	/* search end of word */
	while(i < strLen && c[i] != cTerm)
		i++;

	if(i == *offs || i == strLen || c[i] != cTerm)
		goto done;

	/* success, persist */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	return r;
}


/**
 * Parse everything up to a specific character, or up to the end of string.
 * The character must be the only char inside extra data passed to the parser.
 * It is a program error if strlen(ed) != 1.
 * This parser always returns success.
 * By nature of the parser, it is required that end of string or the separator
 * follows this field in rule.
 */
PARSER(CharSeparated)
	const char *c;
	unsigned char cTerm;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	assert(es_strlen(ed) == 1);
	cTerm = *(es_getBufAddr(ed));
	c = str;
	i = *offs;

	/* search end of word */
	while(i < strLen && c[i] != cTerm)
		i++;

	/* success, persist */
	*parsed = i - *offs;

	r = 0; /* success */
	return r;
}

/**
 * Parse yet-to-be-matched portion of string by re-applying
 * top-level rules again.
 */
#define DEFAULT_REMAINING_FIELD_NAME "tail"

struct recursive_parser_data_s {
	ln_ctx ctx;
	char* remaining_field;
	int free_ctx;
};

PARSER(Recursive)
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);

	struct recursive_parser_data_s* pData = (struct recursive_parser_data_s*) node->parser_data;

	if (pData != NULL) {
		int remaining_len = strLen - *offs;
		const char *remaining_str = str + *offs;
		json_object *unparsed = NULL;
		CHKN(*value = json_object_new_object());

		ln_normalize(pData->ctx, remaining_str, remaining_len, value);

		if (json_object_object_get_ex(*value, UNPARSED_DATA_KEY, &unparsed)) {
			json_object_put(*value);
			*value = NULL;
			*parsed = 0;
		} else if (pData->remaining_field != NULL
			&& json_object_object_get_ex(*value, pData->remaining_field, &unparsed)) {
			*parsed = strLen - *offs - json_object_get_string_len(unparsed);
			json_object_object_del(*value, pData->remaining_field);
		} else {
			*parsed = strLen - *offs;
		}
	}
	r = 0; /* success */
done:
	return r;
}

typedef ln_ctx (ctx_constructor)(ln_ctx, pcons_args_t*, const char*);

static void*
_recursive_parser_data_constructor(ln_fieldList_t *node,
	ln_ctx ctx,
	int no_of_args,
	int remaining_field_arg_idx,
	int free_ctx, ctx_constructor *fn)
{
	int r = LN_BADCONFIG;
	char* name = NULL;
	struct recursive_parser_data_s *pData = NULL;
	pcons_args_t *args = NULL;
	CHKN(name = es_str2cstr(node->name, NULL));
	CHKN(pData = calloc(1, sizeof(struct recursive_parser_data_s)));
	pData->free_ctx = free_ctx;
	pData->remaining_field = NULL;
	CHKN(args = pcons_args(node->raw_data, no_of_args));
	CHKN(pData->ctx = fn(ctx, args, name));
	CHKN(pData->remaining_field = pcons_arg_copy(args, remaining_field_arg_idx, DEFAULT_REMAINING_FIELD_NAME));
	r = 0;
done:
	if (r != 0) {
		if (name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for recursive/descent field name");
		else if (pData == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for parser-data for field: %s", name);
		else if (args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for argument-parsing for field: %s", name);
		else if (pData->ctx == NULL)
			ln_dbgprintf(ctx, "recursive/descent normalizer context creation "
		"doneed for field: %s", name);
		else if (pData->remaining_field == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for remaining-field name for "
				"recursive/descent field: %s", name);

		recursive_parser_data_destructor((void**) &pData);
	}
	free(name);
	free_pcons_args(&args);
	return pData;
}

static ln_ctx identity_recursive_parse_ctx_constructor(ln_ctx parent_ctx,
	__attribute__((unused)) pcons_args_t* args,
	__attribute__((unused)) const char* field_name) {
	return parent_ctx;
}

void* recursive_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	return _recursive_parser_data_constructor(node, ctx, 1, 0, 0, identity_recursive_parse_ctx_constructor);
}

static ln_ctx child_recursive_parse_ctx_constructor(ln_ctx parent_ctx, pcons_args_t* args, const char* field_name) {
	int r = LN_BADCONFIG;
	const char* rb = NULL;
	ln_ctx ctx = NULL;
	pcons_unescape_arg(args, 0);
	CHKN(rb = pcons_arg(args, 0, NULL));
	CHKN(ctx = ln_v1_inherittedCtx(parent_ctx));
	CHKR(ln_v1_loadSamples(ctx, rb));
done:
	if (r != 0) {
		if (rb == NULL)
			ln_dbgprintf(parent_ctx, "file-name for descent rulebase not provided for field: %s",
				field_name);
		else if (ctx == NULL)
			ln_dbgprintf(parent_ctx, "couldn't allocate memory to create descent-field normalizer "
				"context for field: %s", field_name);
		else
			ln_dbgprintf(parent_ctx, "couldn't load samples into descent context for field: %s",
				field_name);
		if (ctx != NULL) ln_exitCtx(ctx);
		ctx = NULL;
	}
	return ctx;
}

void* descent_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	return _recursive_parser_data_constructor(node, ctx, 2, 1, 1, child_recursive_parse_ctx_constructor);
}

void recursive_parser_data_destructor(void** dataPtr) {
	if (*dataPtr != NULL) {
		struct recursive_parser_data_s *pData = (struct recursive_parser_data_s*) *dataPtr;
		if (pData->free_ctx && pData->ctx != NULL) {
			ln_exitCtx(pData->ctx);
			pData->ctx = NULL;
		}
		if (pData->remaining_field != NULL) free(pData->remaining_field);
		free(pData);
		*dataPtr = NULL;
	}
};

/**
 * Parse string tokenized by given char-sequence
 * The sequence may appear 0 or more times, but zero times means 1 token.
 * NOTE: its not 0 tokens, but 1 token.
 *
 * The token found is parsed according to the field-type provided after
 *  tokenizer char-seq.
 */
#define DEFAULT_MATCHED_FIELD_NAME "default"

struct tokenized_parser_data_s {
	es_str_t *tok_str;
	ln_ctx ctx;
	char *remaining_field;
	int use_default_field;
	int free_ctx;
};

typedef struct tokenized_parser_data_s tokenized_parser_data_t;

PARSER(Tokenized)
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);

	tokenized_parser_data_t *pData = (tokenized_parser_data_t*) node->parser_data;

	if (pData != NULL ) {
		json_object *json_p = NULL;
		if (pData->use_default_field) CHKN(json_p = json_object_new_object());
		json_object *matches = NULL;
		CHKN(matches = json_object_new_array());

		int remaining_len = strLen - *offs;
		const char *remaining_str = str + *offs;
		json_object *remaining = NULL;
		json_object *match = NULL;

		while (remaining_len > 0) {
			if (! pData->use_default_field) {
				json_object_put(json_p);
				json_p = json_object_new_object();
			} /*TODO: handle null condition gracefully*/

			ln_normalize(pData->ctx, remaining_str, remaining_len, &json_p);

			if (remaining) json_object_put(remaining);

			if (pData->use_default_field
				&& json_object_object_get_ex(json_p, DEFAULT_MATCHED_FIELD_NAME, &match)) {
				json_object_array_add(matches, json_object_get(match));
			} else if (! (pData->use_default_field
				|| json_object_object_get_ex(json_p, UNPARSED_DATA_KEY, &match))) {
				json_object_array_add(matches, json_object_get(json_p));
			} else {
				if (json_object_array_length(matches) > 0) {
					remaining_len += es_strlen(pData->tok_str);
					break;
				} else {
					json_object_put(json_p);
					json_object_put(matches);
					FAIL(LN_WRONGPARSER);
				}
			}

			if (json_object_object_get_ex(json_p, pData->remaining_field, &remaining)) {
				remaining_len = json_object_get_string_len(remaining);
				if (remaining_len > 0) {
					remaining_str = json_object_get_string(json_object_get(remaining));
					json_object_object_del(json_p, pData->remaining_field);
					if (es_strbufcmp(pData->tok_str, (const unsigned char *)remaining_str,
					es_strlen(pData->tok_str))) {
						json_object_put(remaining);
						break;
					} else {
						remaining_str += es_strlen(pData->tok_str);
						remaining_len -= es_strlen(pData->tok_str);
					}
				}
			} else {
				remaining_len = 0;
				break;
			}

			if (pData->use_default_field) json_object_object_del(json_p, DEFAULT_MATCHED_FIELD_NAME);
		}
		json_object_put(json_p);

		/* success, persist */
		*parsed = (strLen - *offs) - remaining_len;
		*value =  matches;
	} else {
		FAIL(LN_BADPARSERSTATE);
	}

	r = 0; /* success */
done:
	return r;
}

void tokenized_parser_data_destructor(void** dataPtr) {
	tokenized_parser_data_t *data = (tokenized_parser_data_t*) *dataPtr;
	if (data->tok_str != NULL) es_deleteStr(data->tok_str);
	if (data->free_ctx && (data->ctx != NULL)) ln_exitCtx(data->ctx);
	if (data->remaining_field != NULL) free(data->remaining_field);
	free(data);
	*dataPtr = NULL;
}

static void load_generated_parser_samples(ln_ctx ctx,
	const char* const field_descr, const int field_descr_len,
	const char* const suffix, const int length) {
	static const char* const RULE_PREFIX = "rule=:%"DEFAULT_MATCHED_FIELD_NAME":";/*TODO: extract nice constants*/
	static const int RULE_PREFIX_LEN = 15;

	char *sample_str = NULL;
	es_str_t *field_decl = es_newStrFromCStr(RULE_PREFIX, RULE_PREFIX_LEN);
	if (! field_decl) goto free;

	if (es_addBuf(&field_decl, field_descr, field_descr_len)
		|| es_addBuf(&field_decl, "%", 1)
		|| es_addBuf(&field_decl, suffix, length)) {
		ln_dbgprintf(ctx, "couldn't prepare field for tokenized field-picking: '%s'", field_descr);
		goto free;
	}
	sample_str = es_str2cstr(field_decl, NULL);
	if (! sample_str) {
		ln_dbgprintf(ctx, "couldn't prepare sample-string for: '%s'", field_descr);
		goto free;
	}
	ln_v1_loadSample(ctx, sample_str);
free:
	if (sample_str) free(sample_str);
	if (field_decl) es_deleteStr(field_decl);
}

static ln_ctx generate_context_with_field_as_prefix(ln_ctx parent, const char* field_descr, int field_descr_len) {
	int r = LN_BADCONFIG;
	const char* remaining_field = "%"DEFAULT_REMAINING_FIELD_NAME":rest%";
	ln_ctx ctx = NULL;
	CHKN(ctx = ln_v1_inherittedCtx(parent));
	load_generated_parser_samples(ctx, field_descr, field_descr_len, remaining_field, strlen(remaining_field));
	load_generated_parser_samples(ctx, field_descr, field_descr_len, "", 0);
	r = 0;
done:
	if (r != 0) {
		ln_exitCtx(ctx);
		ctx = NULL;
	}
	return ctx;
}

static ln_fieldList_t* parse_tokenized_content_field(ln_ctx ctx, const char* field_descr, size_t field_descr_len) {
	es_str_t* tmp = NULL;
	es_str_t* descr = NULL;
	ln_fieldList_t *node = NULL;
	int r = 0;
	CHKN(tmp = es_newStr(80));
	CHKN(descr = es_newStr(80));
	const char* field_prefix = "%" DEFAULT_MATCHED_FIELD_NAME ":";
	CHKR(es_addBuf(&descr, field_prefix, strlen(field_prefix)));
	CHKR(es_addBuf(&descr, field_descr, field_descr_len));
	CHKR(es_addChar(&descr, '%'));
	es_size_t offset = 0;
	CHKN(node = ln_v1_parseFieldDescr(ctx, descr, &offset, &tmp, &r));
	if (offset != es_strlen(descr)) FAIL(LN_BADPARSERSTATE);
done:
	if (r != 0) {
		if (node != NULL) ln_deletePTreeNode(node);
		node = NULL;
	}
	if (descr != NULL) es_deleteStr(descr);
	if (tmp != NULL) es_deleteStr(tmp);
	return node;
}

void* tokenized_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	int r = LN_BADCONFIG;
	char* name = es_str2cstr(node->name, NULL);
	pcons_args_t *args = NULL;
	tokenized_parser_data_t *pData = NULL;
	const char *field_descr = NULL;
	ln_fieldList_t* field = NULL;
	const char *tok = NULL;

	CHKN(args = pcons_args(node->raw_data, 2));

	CHKN(pData = calloc(1, sizeof(tokenized_parser_data_t)));
	pcons_unescape_arg(args, 0);
	CHKN(tok = pcons_arg(args, 0, NULL));
	CHKN(pData->tok_str = es_newStrFromCStr(tok, strlen(tok)));
	es_unescapeStr(pData->tok_str);
	CHKN(field_descr = pcons_arg(args, 1, NULL));
	const int field_descr_len = strlen(field_descr);
	pData->free_ctx = 1;
	CHKN(field = parse_tokenized_content_field(ctx, field_descr, field_descr_len));
	if (field->parser == ln_parseRecursive) {
		pData->use_default_field = 0;
		struct recursive_parser_data_s *dat = (struct recursive_parser_data_s*) field->parser_data;
		if (dat != NULL) {
			CHKN(pData->remaining_field = strdup(dat->remaining_field));
			pData->free_ctx = dat->free_ctx;
			pData->ctx = dat->ctx;
			dat->free_ctx = 0;
		}
	} else {
		pData->use_default_field = 1;
		CHKN(pData->ctx = generate_context_with_field_as_prefix(ctx, field_descr, field_descr_len));
	}
	if (pData->remaining_field == NULL) CHKN(pData->remaining_field = strdup(DEFAULT_REMAINING_FIELD_NAME));
	r = 0;
done:
	if (r != 0) {
		if (name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for tokenized-field name");
		else if (args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for argument-parsing for field: %s", name);
		else if (pData == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for parser-data for field: %s", name);
		else if (tok == NULL)
			ln_dbgprintf(ctx, "token-separator not provided for field: %s", name);
		else if (pData->tok_str == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for token-separator "
			"for field: %s", name);
		else if (field_descr == NULL)
			ln_dbgprintf(ctx, "field-type not provided for field: %s", name);
		else if (field == NULL)
			ln_dbgprintf(ctx, "couldn't resolve single-token field-type for tokenized field: %s", name);
		else if (pData->ctx == NULL)
			ln_dbgprintf(ctx, "couldn't initialize normalizer-context for field: %s", name);
		else if (pData->remaining_field == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for "
				"remaining-field-name for field: %s", name);
		if (pData) tokenized_parser_data_destructor((void**) &pData);
	}
	if (name != NULL) free(name);
	if (field != NULL) ln_deletePTreeNode(field);
	if (args) free_pcons_args(&args);
	return pData;
}

#ifdef FEATURE_REGEXP

/**
 * Parse string matched by provided posix extended regex.
 *
 * Please note that using regex field in most cases will be
 * significantly slower than other field-types.
 */
struct regex_parser_data_s {
	pcre *re;
	int consume_group;
	int return_group;
	int max_groups;
};

PARSER(Regex)
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	unsigned int* ovector = NULL;

	struct regex_parser_data_s *pData = (struct regex_parser_data_s*) node->parser_data;
	if (pData != NULL) {
		ovector = calloc(pData->max_groups, sizeof(unsigned int) * 3);
		if (ovector == NULL) FAIL(LN_NOMEM);

		int result = pcre_exec(pData->re, NULL,	str, strLen, *offs, 0, (int*) ovector, pData->max_groups * 3);
		if (result == 0) result = pData->max_groups;
		if (result > pData->consume_group) {
			/*please check 'man 3 pcreapi' for cryptic '2 * n' and '2 * n + 1' magic*/
			if (ovector[2 * pData->consume_group] == *offs) {
				*parsed = ovector[2 * pData->consume_group + 1] - ovector[2 * pData->consume_group];
				if (pData->consume_group != pData->return_group) {
					char* val = NULL;
					if((val = strndup(str + ovector[2 * pData->return_group],
						ovector[2 * pData->return_group + 1] -
						ovector[2 * pData->return_group])) == NULL) {
						free(ovector);
						FAIL(LN_NOMEM);
					}
					*value = json_object_new_string(val);
					free(val);
					if (*value == NULL) {
						free(ovector);
						FAIL(LN_NOMEM);
					}
				}
			}
		}
		free(ovector);
	}
	r = 0; /* success */
done:
	return r;
}

static const char* regex_parser_configure_consume_and_return_group(pcons_args_t* args,
struct regex_parser_data_s *pData) {
	const char* consume_group_parse_error = "couldn't parse consume-group number";
	const char* return_group_parse_error = "couldn't parse return-group number";

	char* tmp = NULL;

	const char* consume_grp_str = NULL;
	const char* return_grp_str = NULL;

	if ((consume_grp_str = pcons_arg(args, 1, "0")) == NULL ||
		strlen(consume_grp_str) == 0) return consume_group_parse_error;
	if ((return_grp_str = pcons_arg(args, 2, consume_grp_str)) == NULL ||
		strlen(return_grp_str) == 0) return return_group_parse_error;

	errno = 0;
	pData->consume_group = strtol(consume_grp_str, &tmp, 10);
	if (errno != 0 || strlen(tmp) != 0) return consume_group_parse_error;

	pData->return_group = strtol(return_grp_str, &tmp, 10);
	if (errno != 0 || strlen(tmp) != 0) return return_group_parse_error;

	return NULL;
}

void* regex_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	int r = LN_BADCONFIG;
	char* exp = NULL;
	const char* grp_parse_err = NULL;
	pcons_args_t* args = NULL;
	char* name = NULL;
	struct regex_parser_data_s *pData = NULL;
	const char *unescaped_exp = NULL;
	const char *error = NULL;
	int erroffset = 0;


	CHKN(name = es_str2cstr(node->name, NULL));

	if (! ctx->opts & LN_CTXOPT_ALLOW_REGEX) FAIL(LN_BADCONFIG);
	CHKN(pData = malloc(sizeof(struct regex_parser_data_s)));
	pData->re = NULL;

	CHKN(args = pcons_args(node->raw_data, 3));
	pData->consume_group = pData->return_group = 0;
	CHKN(unescaped_exp = pcons_arg(args, 0, NULL));
	pcons_unescape_arg(args, 0);
	CHKN(exp = pcons_arg_copy(args, 0, NULL));

	if ((grp_parse_err = regex_parser_configure_consume_and_return_group(args, pData)) != NULL)
		FAIL(LN_BADCONFIG);

	CHKN(pData->re = pcre_compile(exp, 0, &error, &erroffset, NULL));

	pData->max_groups = ((pData->consume_group > pData->return_group) ? pData->consume_group :
					pData->return_group) + 1;
	r = 0;
done:
	if (r != 0) {
		if (name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory regex-field name");
		else if (! ctx->opts & LN_CTXOPT_ALLOW_REGEX)
			ln_dbgprintf(ctx, "regex support is not enabled for: '%s' "
				"(please check lognorm context initialization)", name);
		else if (pData == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for parser-data for field: %s", name);
		else if (args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for argument-parsing for field: %s", name);
		else if (unescaped_exp == NULL)
			ln_dbgprintf(ctx, "regular-expression missing for field: '%s'", name);
		else if (exp == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for regex-string for field: '%s'", name);
		else if (grp_parse_err != NULL)
			ln_dbgprintf(ctx, "%s for: '%s'", grp_parse_err, name);
		else if (pData->re == NULL)
			ln_dbgprintf(ctx, "couldn't compile regex(encountered error '%s' at char '%d' in pattern) "
				 "for regex-matched field: '%s'", error, erroffset, name);
		regex_parser_data_destructor((void**)&pData);
	}
	if (exp != NULL) free(exp);
	if (args != NULL) free_pcons_args(&args);
	if (name != NULL) free(name);
	return pData;
}

void regex_parser_data_destructor(void** dataPtr) {
	if ((*dataPtr) != NULL) {
		struct regex_parser_data_s *pData = (struct regex_parser_data_s*) *dataPtr;
		if (pData->re != NULL) pcre_free(pData->re);
		free(pData);
		*dataPtr = NULL;
	}
}

#endif

/**
 * Parse yet-to-be-matched portion of string by re-applying
 * top-level rules again.
 */
typedef enum interpret_type {
	/* If you change this, be sure to update json_type_to_name() too */
	it_b10int,
	it_b16int,
	it_floating_pt,
	it_boolean
} interpret_type;

struct interpret_parser_data_s {
	ln_ctx ctx;
	enum interpret_type intrprt;
};

static json_object* interpret_as_int(json_object *value, int base) {
	if (json_object_is_type(value, json_type_string)) {
		return json_object_new_int64(strtol(json_object_get_string(value), NULL, base));
	} else if (json_object_is_type(value, json_type_int)) {
		return value;
	} else {
		return NULL;
	}
}

static json_object* interpret_as_double(json_object *value) {
	double val = json_object_get_double(value);
	return json_object_new_double(val);
}

static json_object* interpret_as_boolean(json_object *value) {
	json_bool val;
	if (json_object_is_type(value, json_type_string)) {
		const char* str = json_object_get_string(value);
		val = (strcasecmp(str, "false") == 0 || strcasecmp(str, "no") == 0) ? 0 : 1;
	} else {
		val = json_object_get_boolean(value);
	}
	return json_object_new_boolean(val);
}

static int reinterpret_value(json_object **value, enum interpret_type to_type) {
	switch(to_type) {
	case it_b10int:
		*value = interpret_as_int(*value, 10);
		break;
	case it_b16int:
		*value = interpret_as_int(*value, 16);
		break;
	case it_floating_pt:
		*value = interpret_as_double(*value);
		break;
	case it_boolean:
		*value = interpret_as_boolean(*value);
		break;
	default:
		return 0;
	}
	return 1;
}

PARSER(Interpret)
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	json_object *unparsed = NULL;
	json_object *parsed_raw = NULL;

	struct interpret_parser_data_s* pData = (struct interpret_parser_data_s*) node->parser_data;

	if (pData != NULL) {
		int remaining_len = strLen - *offs;
		const char *remaining_str = str + *offs;

		CHKN(parsed_raw = json_object_new_object());

		ln_normalize(pData->ctx, remaining_str, remaining_len, &parsed_raw);

		if (json_object_object_get_ex(parsed_raw, UNPARSED_DATA_KEY, NULL)) {
			*parsed = 0;
		} else {
			json_object_object_get_ex(parsed_raw, DEFAULT_MATCHED_FIELD_NAME, value);
			json_object_object_get_ex(parsed_raw, DEFAULT_REMAINING_FIELD_NAME, &unparsed);
			if (reinterpret_value(value, pData->intrprt)) {
				*parsed = strLen - *offs - json_object_get_string_len(unparsed);
			}
		}
		json_object_put(parsed_raw);
	}
	r = 0; /* success */
done:
	return r;
}

void* interpret_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	int r = LN_BADCONFIG;
	char* name = NULL;
	struct interpret_parser_data_s *pData = NULL;
	pcons_args_t *args = NULL;
	int bad_interpret = 0;
	const char* type_str = NULL;
	const char *field_type = NULL;
	CHKN(name = es_str2cstr(node->name, NULL));
	CHKN(pData = calloc(1, sizeof(struct interpret_parser_data_s)));
	CHKN(args = pcons_args(node->raw_data, 2));
	CHKN(type_str = pcons_arg(args, 0, NULL));
	if (strcmp(type_str, "int") == 0 || strcmp(type_str, "base10int") == 0) {
		pData->intrprt = it_b10int;
	} else if (strcmp(type_str, "base16int") == 0) {
		pData->intrprt = it_b16int;
	} else if (strcmp(type_str, "float") == 0) {
		pData->intrprt = it_floating_pt;
	} else if (strcmp(type_str, "bool") == 0) {
		pData->intrprt = it_boolean;
	} else {
		bad_interpret = 1;
		FAIL(LN_BADCONFIG);
	}

	CHKN(field_type = pcons_arg(args, 1, NULL));
	CHKN(pData->ctx = generate_context_with_field_as_prefix(ctx, field_type, strlen(field_type)));
	r = 0;
done:
	if (r != 0) {
		if (name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for interpret-field name");
		else if (pData == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for parser-data for field: %s", name);
		else if (args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for argument-parsing for field: %s", name);
		else if (type_str == NULL)
			ln_dbgprintf(ctx, "no type provided for interpretation of field: %s", name);
		else if (bad_interpret != 0)
			ln_dbgprintf(ctx, "interpretation to unknown type '%s' requested for field: %s",
				type_str, name);
		else if (field_type == NULL)
			ln_dbgprintf(ctx, "field-type to actually match the content not provided for "
				"field: %s", name);
		else if (pData->ctx == NULL)
			ln_dbgprintf(ctx, "couldn't instantiate the normalizer context for matching "
				"field: %s", name);

		interpret_parser_data_destructor((void**) &pData);
	}
	free(name);
	free_pcons_args(&args);
	return pData;
}

void interpret_parser_data_destructor(void** dataPtr) {
	if (*dataPtr != NULL) {
		struct interpret_parser_data_s *pData = (struct interpret_parser_data_s*) *dataPtr;
		if (pData->ctx != NULL) ln_exitCtx(pData->ctx);
		free(pData);
		*dataPtr = NULL;
	}
};

/**
 * Parse suffixed char-sequence, where suffix is one of many possible suffixes.
 */
struct suffixed_parser_data_s {
	int nsuffix;
	int *suffix_offsets;
	int *suffix_lengths;
	char* suffixes_str;
	ln_ctx ctx;
	char* value_field_name;
	char* suffix_field_name;
};

PARSER(Suffixed) {
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	json_object *unparsed = NULL;
	json_object *parsed_raw = NULL;
	json_object *parsed_value = NULL;
	json_object *result = NULL;
	json_object *suffix = NULL;

	struct suffixed_parser_data_s *pData = (struct suffixed_parser_data_s*) node->parser_data;

	if (pData != NULL) {
		int remaining_len = strLen - *offs;
		const char *remaining_str = str + *offs;
		int i;

		CHKN(parsed_raw = json_object_new_object());

		ln_normalize(pData->ctx, remaining_str, remaining_len, &parsed_raw);

		if (json_object_object_get_ex(parsed_raw, UNPARSED_DATA_KEY, NULL)) {
			*parsed = 0;
		} else {
			json_object_object_get_ex(parsed_raw, DEFAULT_MATCHED_FIELD_NAME, &parsed_value);
			json_object_object_get_ex(parsed_raw, DEFAULT_REMAINING_FIELD_NAME, &unparsed);
		const char* unparsed_frag = json_object_get_string(unparsed);
			for(i = 0; i < pData->nsuffix; i++) {
		const char* possible_suffix = pData->suffixes_str + pData->suffix_offsets[i];
				int len = pData->suffix_lengths[i];
				if (strncmp(possible_suffix, unparsed_frag, len) == 0) {
				CHKN(result = json_object_new_object());
				CHKN(suffix = json_object_new_string(possible_suffix));
					json_object_get(parsed_value);
				json_object_object_add(result, pData->value_field_name, parsed_value);
				json_object_object_add(result, pData->suffix_field_name, suffix);
					*parsed = strLen - *offs - json_object_get_string_len(unparsed) + len;
				break;
				}
			}
			if (result != NULL) {
				*value = result;
			}
		}
	}
FAILParser
	if (r != 0) {
		if (result != NULL) json_object_put(result);
	}
	if (parsed_raw != NULL) json_object_put(parsed_raw);
} ENDFailParser

static struct suffixed_parser_data_s* _suffixed_parser_data_constructor(ln_fieldList_t *node,
	ln_ctx ctx,
	es_str_t* raw_args,
	const char* value_field,
	const char* suffix_field) {
	int r = LN_BADCONFIG;
	pcons_args_t* args = NULL;
	char* name = NULL;
	struct suffixed_parser_data_s *pData = NULL;
	const char *escaped_tokenizer = NULL;
	const char *uncopied_suffixes_str = NULL;
	const char *tokenizer = NULL;
	char *suffixes_str = NULL;
	const char *field_type = NULL;

	char *tok_saveptr = NULL;
	char *tok_input = NULL;
	int i = 0;
	char *tok = NULL;

	CHKN(name = es_str2cstr(node->name, NULL));

	CHKN(pData = calloc(1, sizeof(struct suffixed_parser_data_s)));

	if (value_field == NULL) value_field = "value";
	if (suffix_field == NULL) suffix_field = "suffix";
	pData->value_field_name = strdup(value_field);
	pData->suffix_field_name = strdup(suffix_field);

	CHKN(args = pcons_args(raw_args, 3));
	CHKN(escaped_tokenizer = pcons_arg(args, 0, NULL));
	pcons_unescape_arg(args, 0);
	CHKN(tokenizer = pcons_arg(args, 0, NULL));

	CHKN(uncopied_suffixes_str = pcons_arg(args, 1, NULL));
	pcons_unescape_arg(args, 1);
	CHKN(suffixes_str = pcons_arg_copy(args, 1, NULL));

	tok_input = suffixes_str;
	while (strtok_r(tok_input, tokenizer, &tok_saveptr) != NULL) {
		tok_input = NULL;
		pData->nsuffix++;
	}

	if (pData->nsuffix == 0) {
		FAIL(LN_INVLDFDESCR);
	}
	CHKN(pData->suffix_offsets = calloc(pData->nsuffix, sizeof(int)));
	CHKN(pData->suffix_lengths = calloc(pData->nsuffix, sizeof(int)));
	CHKN(pData->suffixes_str = pcons_arg_copy(args, 1, NULL));

	tok_input = pData->suffixes_str;
	while ((tok = strtok_r(tok_input, tokenizer, &tok_saveptr)) != NULL) {
		tok_input = NULL;
		pData->suffix_offsets[i] = tok - pData->suffixes_str;
	pData->suffix_lengths[i++] = strlen(tok);
	}

	CHKN(field_type = pcons_arg(args, 2, NULL));
	CHKN(pData->ctx = generate_context_with_field_as_prefix(ctx, field_type, strlen(field_type)));
	
	r = 0;
done:
	if (r != 0) {
		if (name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory suffixed-field name");
		else if (pData == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for parser-data for field: %s", name);
		else if (pData->value_field_name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for value-field's name for field: %s", name);
		else if (pData->suffix_field_name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for suffix-field's name for field: %s", name);
		else if (args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for argument-parsing for field: %s", name);
		else if (escaped_tokenizer == NULL)
			ln_dbgprintf(ctx, "suffix token-string missing for field: '%s'", name);
		else if (tokenizer == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for unescaping token-string for field: '%s'",
				name);
		else if (uncopied_suffixes_str == NULL)
			ln_dbgprintf(ctx, "suffix-list missing for field: '%s'", name);
		else if (suffixes_str == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for suffix-list for field: '%s'", name);
		else if (pData->nsuffix == 0)
			ln_dbgprintf(ctx, "could't read suffix-value(s) for field: '%s'", name);
		else if (pData->suffix_offsets == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for suffix-list element references for field: "
				"'%s'", name);
		else if (pData->suffix_lengths == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for suffix-list element lengths for field: '%s'",
				name);
		else if (pData->suffixes_str == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for suffix-list for field: '%s'", name);
		else if (field_type == NULL)
			ln_dbgprintf(ctx, "field-type declaration missing for field: '%s'", name);
		else if (pData->ctx == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for normalizer-context for field: '%s'", name);
		suffixed_parser_data_destructor((void**)&pData);
	}
	free_pcons_args(&args);
	if (suffixes_str != NULL) free(suffixes_str);
	if (name != NULL) free(name);
	return pData;
}

void* suffixed_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	return _suffixed_parser_data_constructor(node, ctx, node->raw_data, NULL, NULL);
}

void* named_suffixed_parser_data_constructor(ln_fieldList_t *node, ln_ctx ctx) {
	int r = LN_BADCONFIG;
	pcons_args_t* args = NULL;
	char* name = NULL;
	const char* value_field_name = NULL;
	const char* suffix_field_name = NULL;
	const char* remaining_args = NULL;
	es_str_t* unnamed_suffix_args = NULL;
	struct suffixed_parser_data_s* pData = NULL;
	CHKN(name = es_str2cstr(node->name, NULL));
	CHKN(args = pcons_args(node->raw_data, 3));
	CHKN(value_field_name = pcons_arg(args, 0, NULL));
	CHKN(suffix_field_name = pcons_arg(args, 1, NULL));
	CHKN(remaining_args = pcons_arg(args, 2, NULL));
	CHKN(unnamed_suffix_args = es_newStrFromCStr(remaining_args, strlen(remaining_args)));
	
	CHKN(pData = _suffixed_parser_data_constructor(node, ctx, unnamed_suffix_args, value_field_name,
		suffix_field_name));
	r = 0;
done:
	if (r != 0) {
		if (name == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory named_suffixed-field name");
		else if (args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for argument-parsing for field: %s", name);
		else if (value_field_name == NULL)
			ln_dbgprintf(ctx, "key-name for value not provided for field: %s", name);
		else if (suffix_field_name == NULL)
			ln_dbgprintf(ctx, "key-name for suffix not provided for field: %s", name);
		else if (unnamed_suffix_args == NULL)
			ln_dbgprintf(ctx, "couldn't allocate memory for unnamed-suffix-field args for field: %s",
				name);
		else if (pData == NULL)
			ln_dbgprintf(ctx, "couldn't create parser-data for field: %s", name);
		suffixed_parser_data_destructor((void**)&pData);
	}
	if (unnamed_suffix_args != NULL) free(unnamed_suffix_args);
	if (args != NULL) free_pcons_args(&args);
	if (name != NULL) free(name);
	return pData;
}


void suffixed_parser_data_destructor(void** dataPtr) {
	if ((*dataPtr) != NULL) {
		struct suffixed_parser_data_s *pData = (struct suffixed_parser_data_s*) *dataPtr;
		if (pData->suffixes_str != NULL) free(pData->suffixes_str);
		if (pData->suffix_offsets != NULL) free(pData->suffix_offsets);
		if (pData->suffix_lengths != NULL) free(pData->suffix_lengths);
		if (pData->value_field_name != NULL) free(pData->value_field_name);
		if (pData->suffix_field_name != NULL) free(pData->suffix_field_name);
		if (pData->ctx != NULL)	ln_exitCtx(pData->ctx);
		free(pData);
		*dataPtr = NULL;
	}
}

/**
 * Just get everything till the end of string.
 */
PARSER(Rest)
	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);

	/* silence the warning about unused variable */
	(void)str;
	/* success, persist */
	*parsed = strLen - *offs;
	r = 0;
	return r;
}

/**
 * Parse a possibly quoted string. In this initial implementation, escaping of the quote
 * char is not supported. A quoted string is one start starts with a double quote,
 * has some text (not containing double quotes) and ends with the first double
 * quote character seen. The extracted string does NOT include the quote characters.
 * swisskid, 2015-01-21
 */
PARSER(OpQuotedString)
	const char *c;
	size_t i;
	char *cstr = NULL;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	if(c[i] != '"') {
		while(i < strLen && c[i] != ' ')
			i++;

		if(i == *offs)
			goto done;

		/* success, persist */
		*parsed = i - *offs;
		/* create JSON value to save quoted string contents */
		CHKN(cstr = strndup((char*)c + *offs, *parsed));
	} else {
	    ++i;

	    /* search end of string */
	    while(i < strLen && c[i] != '"')
		    i++;

	    if(i == strLen || c[i] != '"')
		    goto done;
	    /* success, persist */
	    *parsed = i + 1 - *offs; /* "eat" terminal double quote */
	    /* create JSON value to save quoted string contents */
	    CHKN(cstr = strndup((char*)c + *offs + 1, *parsed - 2));
	}
	CHKN(*value = json_object_new_string(cstr));

	r = 0; /* success */
done:
	free(cstr);
	return r;
}

/**
 * Parse a quoted string. In this initial implementation, escaping of the quote
 * char is not supported. A quoted string is one start starts with a double quote,
 * has some text (not containing double quotes) and ends with the first double
 * quote character seen. The extracted string does NOT include the quote characters.
 * rgerhards, 2011-01-14
 */
PARSER(QuotedString)
	const char *c;
	size_t i;
	char *cstr = NULL;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;
	if(i + 2 > strLen)
		goto done;	/* needs at least 2 characters */

	if(c[i] != '"')
		goto done;
	++i;

	/* search end of string */
	while(i < strLen && c[i] != '"')
		i++;

	if(i == strLen || c[i] != '"')
		goto done;

	/* success, persist */
	*parsed = i + 1 - *offs; /* "eat" terminal double quote */
	/* create JSON value to save quoted string contents */
	CHKN(cstr = strndup((char*)c + *offs + 1, *parsed - 2));
	CHKN(*value = json_object_new_string(cstr));
	r = 0; /* success */
done:
	free(cstr);
	return r;
}


/**
 * Parse an ISO date, that is YYYY-MM-DD (exactly this format).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 * rgerhards, 2011-01-14
 */
PARSER(ISODate)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	if(*offs+10 > strLen)
		goto done;	/* if it is not 10 chars, it can't be an ISO date */

	/* year */
	if(!isdigit(c[i])) goto done;
	if(!isdigit(c[i+1])) goto done;
	if(!isdigit(c[i+2])) goto done;
	if(!isdigit(c[i+3])) goto done;
	if(c[i+4] != '-') goto done;
	/* month */
	if(c[i+5] == '0') {
		if(c[i+6] < '1' || c[i+6] > '9') goto done;
	} else if(c[i+5] == '1') {
		if(c[i+6] < '0' || c[i+6] > '2') goto done;
	} else {
		goto done;
	}
	if(c[i+7] != '-') goto done;
	/* day */
	if(c[i+8] == '0') {
		if(c[i+9] < '1' || c[i+9] > '9') goto done;
	} else if(c[i+8] == '1' || c[i+8] == '2') {
		if(!isdigit(c[i+9])) goto done;
	} else if(c[i+8] == '3') {
		if(c[i+9] != '0' && c[i+9] != '1') goto done;
	} else {
		goto done;
	}

	/* success, persist */
	*parsed = 10;

	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a Cisco interface spec. Sample for such a spec are:
 *   outside:192.168.52.102/50349
 *   inside:192.168.1.15/56543 (192.168.1.112/54543)
 *   outside:192.168.1.13/50179 (192.168.1.13/50179)(LOCAL\some.user)
 *   outside:192.168.1.25/41850(LOCAL\RG-867G8-DEL88D879BBFFC8)
 *   inside:192.168.1.25/53 (192.168.1.25/53) (some.user)
 *   192.168.1.15/0(LOCAL\RG-867G8-DEL88D879BBFFC8)
 * From this, we conclude the format is:
 *   [interface:]ip/port [SP (ip2/port2)] [[SP](username)]
 * In order to match, this syntax must start on a non-whitespace char
 * other than colon.
 */
PARSER(CiscoInterfaceSpec)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	if(c[i] == ':' || isspace(c[i])) goto done;

	/* first, check if we have an interface. We do this by trying
	 * to detect if we have an IP. If we have, obviously no interface
	 * is present. Otherwise, we check if we have a valid interface.
	 */
	int bHaveInterface = 0;
	size_t idxInterface = 0;
	size_t lenInterface = 0;
	int bHaveIP = 0;
	size_t lenIP;
	size_t idxIP = i;
	if(ln_parseIPv4(str, strLen, &i, node, &lenIP, NULL) == 0) {
		bHaveIP = 1;
		i += lenIP - 1; /* position on delimiter */
	} else {
		idxInterface = i;
		while(i < strLen) {
			if(isspace(c[i])) goto done;
			if(c[i] == ':')
				break;
			++i;
		}
		lenInterface = i - idxInterface;
		bHaveInterface = 1;
	}
	if(i == strLen) goto done;
	++i; /* skip over colon */

	/* we now utilize our other parser helpers */
	if(!bHaveIP) {
		idxIP = i;
		if(ln_parseIPv4(str, strLen, &i, node, &lenIP, NULL) != 0) goto done;
		i += lenIP;
	}
	if(i == strLen || c[i] != '/') goto done;
	++i; /* skip slash */
	const size_t idxPort = i;
	size_t lenPort;
	if(ln_parseNumber(str, strLen, &i, node, &lenPort, NULL) != 0) goto done;
	i += lenPort;
	if(i == strLen) goto success;

	/* check if optional second ip/port is present
	 * We assume we must at least have 5 chars [" (::1)"]
	 */
	int bHaveIP2 = 0;
	size_t idxIP2 = 0, lenIP2 = 0;
	size_t idxPort2 = 0, lenPort2 = 0;
	if(i+5 < strLen && c[i] == ' ' && c[i+1] == '(') {
		size_t iTmp = i+2; /* skip over " (" */
		idxIP2 = iTmp;
		if(ln_parseIPv4(str, strLen, &iTmp, node, &lenIP2, NULL) == 0) {
			iTmp += lenIP2;
			if(i < strLen || c[iTmp] == '/') {
				++iTmp; /* skip slash */
				idxPort2 = iTmp;
				if(ln_parseNumber(str, strLen, &iTmp, node, &lenPort2, NULL) == 0) {
					iTmp += lenPort2;
					if(iTmp < strLen && c[iTmp] == ')') {
						i = iTmp + 1; /* match, so use new index */
						bHaveIP2 = 1;
					}
				}
			}
		}
	}

	/* check if optional username is present
	 * We assume we must at least have 3 chars ["(n)"]
	 */
	int bHaveUser = 0;
	size_t idxUser = 0;
	size_t lenUser = 0;
	if(   (i+2 < strLen && c[i] == '(' && !isspace(c[i+1]) )
	   || (i+3 < strLen && c[i] == ' ' && c[i+1] == '(' && !isspace(c[i+2])) ) {
		idxUser = i + ((c[i] == ' ') ? 2 : 1); /* skip [SP]'(' */
		size_t iTmp = idxUser;
		while(iTmp < strLen && !isspace(c[iTmp]) && c[iTmp] != ')')
			++iTmp; /* just scan */
		if(iTmp < strLen && c[iTmp] == ')') {
			i = iTmp + 1; /* we have a match, so use new index */
			bHaveUser = 1;
			lenUser = iTmp - idxUser;
		}
	}

	/* all done, save data */
	if(value == NULL)
		goto success;

	CHKN(*value = json_object_new_object());
	json_object *json;
	if(bHaveInterface) {
		CHKN(json = json_object_new_string_len(c+idxInterface, lenInterface));
		json_object_object_add_ex(*value, "interface", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	}
	CHKN(json = json_object_new_string_len(c+idxIP, lenIP));
	json_object_object_add_ex(*value, "ip", json, JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	CHKN(json = json_object_new_string_len(c+idxPort, lenPort));
	json_object_object_add_ex(*value, "port", json, JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	if(bHaveIP2) {
		CHKN(json = json_object_new_string_len(c+idxIP2, lenIP2));
		json_object_object_add_ex(*value, "ip2", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
		CHKN(json = json_object_new_string_len(c+idxPort2, lenPort2));
		json_object_object_add_ex(*value, "port2", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	}
	if(bHaveUser) {
		CHKN(json = json_object_new_string_len(c+idxUser, lenUser));
		json_object_object_add_ex(*value, "user", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	}

success: /* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */
done:
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		*value = NULL; /* to be on the save side */
	}
	return r;
}

/**
 * Parse a duration. A duration is similar to a timestamp, except that
 * it tells about time elapsed. As such, hours can be larger than 23
 * and hours may also be specified by a single digit (this, for example,
 * is commonly done in Cisco software).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 */
PARSER(Duration)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	/* hour is a bit tricky */
	if(!isdigit(c[i])) goto done;
	++i;
	if(isdigit(c[i]))
		++i;
	if(c[i] == ':')
		++i;
	else
		goto done;

	if(i+5 > strLen)
		goto done;/* if it is not 5 chars from here, it can't be us */

	if(c[i] < '0' || c[i] > '5') goto done;
	if(!isdigit(c[i+1])) goto done;
	if(c[i+2] != ':') goto done;
	if(c[i+3] < '0' || c[i+3] > '5') goto done;
	if(!isdigit(c[i+4])) goto done;

	/* success, persist */
	*parsed = (i + 5) - *offs;

	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a timestamp in 24hr format (exactly HH:MM:SS).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 * rgerhards, 2011-01-14
 */
PARSER(Time24hr)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	if(*offs+8 > strLen)
		goto done;	/* if it is not 8 chars, it can't be us */

	/* hour */
	if(c[i] == '0' || c[i] == '1') {
		if(!isdigit(c[i+1])) goto done;
	} else if(c[i] == '2') {
		if(c[i+1] < '0' || c[i+1] > '3') goto done;
	} else {
		goto done;
	}
	/* TODO: the code below is a duplicate of 24hr parser - create common function */
	if(c[i+2] != ':') goto done;
	if(c[i+3] < '0' || c[i+3] > '5') goto done;
	if(!isdigit(c[i+4])) goto done;
	if(c[i+5] != ':') goto done;
	if(c[i+6] < '0' || c[i+6] > '5') goto done;
	if(!isdigit(c[i+7])) goto done;

	/* success, persist */
	*parsed = 8;

	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a timestamp in 12hr format (exactly HH:MM:SS).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 * TODO: the code below is a duplicate of 24hr parser - create common function?
 * rgerhards, 2011-01-14
 */
PARSER(Time12hr)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = str;
	i = *offs;

	if(*offs+8 > strLen)
		goto done;	/* if it is not 8 chars, it can't be us */

	/* hour */
	if(c[i] == '0') {
		if(!isdigit(c[i+1])) goto done;
	} else if(c[i] == '1') {
		if(c[i+1] < '0' || c[i+1] > '2') goto done;
	} else {
		goto done;
	}
	if(c[i+2] != ':') goto done;
	if(c[i+3] < '0' || c[i+3] > '5') goto done;
	if(!isdigit(c[i+4])) goto done;
	if(c[i+5] != ':') goto done;
	if(c[i+6] < '0' || c[i+6] > '5') goto done;
	if(!isdigit(c[i+7])) goto done;

	/* success, persist */
	*parsed = 8;

	r = 0; /* success */
done:
	return r;
}


/* helper to IPv4 address parser, checks the next set of numbers.
 * Syntax 1 to 3 digits, value together not larger than 255.
 * @param[in] str parse buffer
 * @param[in/out] offs offset into buffer, updated if successful
 * @return 0 if OK, 1 otherwise
 */
static int
chkIPv4AddrByte(const char *str, size_t strLen, size_t *offs)
{
	int val = 0;
	int r = 1;	/* default: done -- simplifies things */
	const char *c;
	size_t i = *offs;

	c = str;
	if(i == strLen || !isdigit(c[i]))
		goto done;
	val = c[i++] - '0';
	if(i < strLen && isdigit(c[i])) {
		val = val * 10 + c[i++] - '0';
		if(i < strLen && isdigit(c[i]))
			val = val * 10 + c[i++] - '0';
	}
	if(val > 255)	/* cannot be a valid IP address byte! */
		goto done;

	*offs = i;
	r = 0;
done:
	return r;
}

/**
 * Parser for IPv4 addresses.
 */
PARSER(IPv4)
	const char *c;
	size_t i;

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	i = *offs;
	if(i + 7 > strLen) {
		/* IPv4 addr requires at least 7 characters */
		goto done;
	}
	c = str;

	/* byte 1*/
	if(chkIPv4AddrByte(str, strLen, &i) != 0) goto done;
	if(i == strLen || c[i++] != '.') goto done;
	/* byte 2*/
	if(chkIPv4AddrByte(str, strLen, &i) != 0) goto done;
	if(i == strLen || c[i++] != '.') goto done;
	/* byte 3*/
	if(chkIPv4AddrByte(str, strLen, &i) != 0) goto done;
	if(i == strLen || c[i++] != '.') goto done;
	/* byte 4 - we do NOT need any char behind it! */
	if(chkIPv4AddrByte(str, strLen, &i) != 0) goto done;

	/* if we reach this point, we found a valid IP address */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	return r;
}


/* skip past the IPv6 address block, parse pointer is set to
 * first char after the block. Returns an error if already at end
 * of string.
 * @param[in] str parse buffer
 * @param[in/out] offs offset into buffer, updated if successful
 * @return 0 if OK, 1 otherwise
 */
static int
skipIPv6AddrBlock(const char *const __restrict__ str,
	const size_t strLen,
	size_t *const __restrict__ offs)
{
	int j;
	if(*offs == strLen)
		return 1;

	for(j = 0 ; j < 4  && *offs+j < strLen && isxdigit(str[*offs+j]) ; ++j)
		/*just skip*/ ;

	*offs += j;
	return 0;
}

/**
 * Parser for IPv6 addresses.
 * Bases on RFC4291 Section 2.2. The address must be followed
 * by whitespace or end-of-string, else it is not considered
 * a valid address. This prevents false positives.
 */
PARSER(IPv6)
	const char *c;
	size_t i;
	size_t beginBlock; /* last block begin in case we need IPv4 parsing */
	int hasIPv4 = 0;
	int nBlocks = 0; /* how many blocks did we already have? */
	int bHad0Abbrev = 0; /* :: already used? */

	assert(str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	i = *offs;
	if(i + 2 > strLen) {
		/* IPv6 addr requires at least 2 characters ("::") */
		goto done;
	}
	c = str;

	/* check that first block is non-empty */
	if(! ( isxdigit(c[i]) || (c[i] == ':' && c[i+1] == ':') ) )
		goto done;

	/* try for all potential blocks plus one more (so we see errors!) */
	for(int j = 0 ; j < 9 ; ++j) {
		beginBlock = i;
		if(skipIPv6AddrBlock(str, strLen, &i) != 0) goto done;
		nBlocks++;
		if(i == strLen) goto chk_ok;
		if(isspace(c[i])) goto chk_ok;
		if(c[i] == '.'){ /* IPv4 processing! */
			hasIPv4 = 1;
			break;
		}
		if(c[i] != ':') goto done;
		i++; /* "eat" ':' */
		if(i == strLen) goto chk_ok;
		/* check for :: */
		if(bHad0Abbrev) {
			if(c[i] == ':') goto done;
		} else {
			if(c[i] == ':') {
				bHad0Abbrev = 1;
				++i;
				if(i == strLen) goto chk_ok;
			}
		}
	}

	if(hasIPv4) {
		size_t ipv4_parsed;
		--nBlocks;
		/* prevent pure IPv4 address to be recognized */
		if(beginBlock == *offs) goto done;
		i = beginBlock;
		if(ln_parseIPv4(str, strLen, &i, node, &ipv4_parsed, NULL) != 0)
			goto done;
		i += ipv4_parsed;
	}

chk_ok:	/* we are finished parsing, check if things are ok */
	if(nBlocks > 8) goto done;
	if(bHad0Abbrev && nBlocks >= 8) goto done;
	/* now check if trailing block is missing. Note that i is already
	 * on next character, so we need to go two back. Two are always
	 * present, else we would not reach this code here.
	 */
	if(c[i-1] == ':' && c[i-2] != ':') goto done;

	/* if we reach this point, we found a valid IP address */
	*parsed = i - *offs;

	r = 0; /* success */
done:
	return r;
}

/* check if a char is valid inside a name of the iptables motif.
 * We try to keep the set as slim as possible, because the iptables
 * parser may otherwise create a very broad match (especially the
 * inclusion of simple words like "DF" cause grief here).
 * Note: we have taken the permitted set from iptables log samples.
 * Report bugs if we missed some additional rules.
 */
static inline int
isValidIPTablesNameChar(const char c)
{
	/* right now, upper case only is valid */
	return ('A' <= c && c <= 'Z') ? 1 : 0;
}

/* helper to iptables parser, parses out a a single name=value pair
 */
static int
parseIPTablesNameValue(const char *const __restrict__ str,
	const size_t strLen,
	size_t *const __restrict__ offs,
	struct json_object *const __restrict__ valroot)
{
	int r = LN_WRONGPARSER;
	size_t i = *offs;
	char *name = NULL;

	const size_t iName = i;
	while(i < strLen && isValidIPTablesNameChar(str[i]))
		++i;
	if(i == iName || (i < strLen && str[i] != '=' && str[i] != ' '))
		goto done; /* no name at all! */

	const ssize_t lenName = i - iName;

	ssize_t iVal = -1;
	size_t lenVal = i - iVal;
	if(i < strLen && str[i] != ' ') {
		/* we have a real value (not just a flag name like "DF") */
		++i; /* skip '=' */
		iVal = i;
		while(i < strLen && !isspace(str[i]))
			++i;
		lenVal = i - iVal;
	}

	/* parsing OK */
	*offs = i;
	r = 0;

	if(valroot == NULL)
		goto done;

	CHKN(name = malloc(lenName+1));
	memcpy(name, str+iName, lenName);
	name[lenName] = '\0';
	json_object *json;
	if(iVal == -1) {
		json = NULL;
	} else {
		CHKN(json = json_object_new_string_len(str+iVal, lenVal));
	}
	json_object_object_add(valroot, name, json);
done:
	free(name);
	return r;
}

/**
 * Parser for iptables logs (the structured part).
 * This parser is named "v2-iptables" because of a traditional
 * parser named "iptables", which we do not want to replace, at
 * least right now (we may re-think this before the first release).
 * For performance reasons, this works in two stages. In the first
 * stage, we only detect if the motif is correct. The second stage is
 * only called when we know it is. In it, we go once again over the
 * message again and actually extract the data. This is done because
 * data extraction is relatively expensive and in most cases we will
 * have much more frequent mismatches than matches.
 * Note that this motif must have at least one field, otherwise it
 * could detect things that are not iptables to be it. Further limits
 * may be imposed in the future as we see additional need.
 * added 2015-04-30 rgerhards
 */
PARSER(v2IPTables)
	size_t i = *offs;
	int nfields = 0;

	/* stage one */
	while(i < strLen) {
		CHKR(parseIPTablesNameValue(str, strLen, &i, NULL));
		++nfields;
		/* exactly one SP is permitted between fields */
		if(i < strLen && str[i] == ' ')
			++i;
	}

	if(nfields < 2) {
		FAIL(LN_WRONGPARSER);
	}

	/* success, persist */
	*parsed = i - *offs;
	r = 0;

	/* stage two */
	if(value == NULL)
		goto done;

	i = *offs;
	CHKN(*value = json_object_new_object());
	while(i < strLen) {
		CHKR(parseIPTablesNameValue(str, strLen, &i, *value));
		while(i < strLen && isspace(str[i]))
			++i;
	}

done:
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		*value = NULL;
	}
	return r;
}

/**
 * Parse JSON. This parser tries to find JSON data inside a message.
 * If it finds valid JSON, it will extract it. Extra data after the
 * JSON is permitted.
 * Note: the json-c JSON parser treats whitespace after the actual
 * json to be part of the json. So in essence, any whitespace is
 * processed by this parser. We use the same semantics to keep things
 * neatly in sync. If json-c changes for some reason or we switch to
 * an alternate json lib, we probably need to be sure to keep that
 * behaviour, and probably emulate it.
 * added 2015-04-28 by rgerhards, v1.1.2
 */
PARSER(JSON)
	const size_t i = *offs;
	struct json_tokener *tokener = NULL;

	if(str[i] != '{' && str[i] != ']') {
		/* this can't be json, see RFC4627, Sect. 2
		 * see this bug in json-c:
		 * https://github.com/json-c/json-c/issues/181
		 * In any case, it's better to do this quick check,
		 * even if json-c did not have the bug because this
		 * check here is much faster than calling the parser.
		 */
		goto done;
	}

	if((tokener = json_tokener_new()) == NULL)
		goto done;

	struct json_object *const json
		= json_tokener_parse_ex(tokener, str+i, (int) (strLen - i));

	if(json == NULL)
		goto done;

	/* success, persist */
	*parsed =  (i + tokener->char_offset) - *offs;
	r = 0; /* success */

	if(value == NULL) {
		json_object_put(json);
	} else {
		*value = json;
	}

done:
	if(tokener != NULL)
		json_tokener_free(tokener);
	return r;
}


/* check if a char is valid inside a name of a NameValue list
 * The set of valid characters may be extended if there is good
 * need to do so. We have selected the current set carefully, but
 * may have overlooked some cases.
 */
static inline int
isValidNameChar(const char c)
{
	return (isalnum(c)
		|| c == '.'
		|| c == '_'
		|| c == '-'
		) ? 1 : 0;
}
/* helper to NameValue parser, parses out a a single name=value pair
 *
 * name must be alphanumeric characters, value must be non-whitespace
 * characters, if quoted than with symmetric quotes. Supported formats
 * - name=value
 * - name="value"
 * - name='value'
 * Note "name=" is valid and means a field with empty value.
 * TODO: so far, quote characters are not permitted WITHIN quoted values.
 */
static int
parseNameValue(const char *const __restrict__ str,
	const size_t strLen,
	size_t *const __restrict__ offs,
	struct json_object *const __restrict__ valroot)
{
	int r = LN_WRONGPARSER;
	size_t i = *offs;
	char *name = NULL;

	const size_t iName = i;
	while(i < strLen && isValidNameChar(str[i]))
		++i;
	if(i == iName || str[i] != '=')
		goto done; /* no name at all! */

	const size_t lenName = i - iName;
	++i; /* skip '=' */

	const size_t iVal = i;
	while(i < strLen && !isspace(str[i]))
		++i;
	const size_t lenVal = i - iVal;

	/* parsing OK */
	*offs = i;
	r = 0;

	if(valroot == NULL)
		goto done;

	CHKN(name = malloc(lenName+1));
	memcpy(name, str+iName, lenName);
	name[lenName] = '\0';
	json_object *json;
	CHKN(json = json_object_new_string_len(str+iVal, lenVal));
	json_object_object_add(valroot, name, json);
done:
	free(name);
	return r;
}

/**
 * Parse CEE syslog.
 * This essentially is a JSON parser, with additional restrictions:
 * The message must start with "@cee:" and json must immediately follow (whitespace permitted).
 * after the JSON, there must be no other non-whitespace characters.
 * In other words: the message must consist of a single JSON object,
 * only.
 * added 2015-04-28 by rgerhards, v1.1.2
 */
PARSER(CEESyslog)
	size_t i = *offs;
	struct json_tokener *tokener = NULL;
	struct json_object *json = NULL;

	if(strLen < i + 7  || /* "@cee:{}" is minimum text */
	   str[i]   != '@' ||
	   str[i+1] != 'c' ||
	   str[i+2] != 'e' ||
	   str[i+3] != 'e' ||
	   str[i+4] != ':')
	   	goto done;
	
	/* skip whitespace */
	for(i += 5 ; i < strLen && isspace(str[i]) ; ++i)
		/* just skip */;

	if(i == strLen || str[i] != '{')
		goto done;
		/* note: we do not permit arrays in CEE mode */

	if((tokener = json_tokener_new()) == NULL)
		goto done;

	json = json_tokener_parse_ex(tokener, str+i, (int) (strLen - i));

	if(json == NULL)
		goto done;

	if(i + tokener->char_offset != strLen)
		goto done;

	/* success, persist */
	*parsed =  strLen;
	r = 0; /* success */

	if(value != NULL) {
		*value = json;
		json = NULL; /* do NOT free below! */
	}

done:
	if(tokener != NULL)
		json_tokener_free(tokener);
	if(json != NULL)
		json_object_put(json);
	return r;
}

/**
 * Parser for name/value pairs.
 * On entry must point to alnum char. All following chars must be
 * name/value pairs delimited by whitespace up until the end of string.
 * For performance reasons, this works in two stages. In the first
 * stage, we only detect if the motif is correct. The second stage is
 * only called when we know it is. In it, we go once again over the
 * message again and actually extract the data. This is done because
 * data extraction is relatively expensive and in most cases we will
 * have much more frequent mismatches than matches.
 * added 2015-04-25 rgerhards
 */
PARSER(NameValue)
	size_t i = *offs;

	/* stage one */
	while(i < strLen) {
		CHKR(parseNameValue(str, strLen, &i, NULL));
		while(i < strLen && isspace(str[i]))
			++i;
	}

	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */

	/* stage two */
	if(value == NULL)
		goto done;

	i = *offs;
	CHKN(*value = json_object_new_object());
	while(i < strLen) {
		CHKR(parseNameValue(str, strLen, &i, *value));
		while(i < strLen && isspace(str[i]))
			++i;
	}

	/* TODO: fix mem leak if alloc json fails */

done:
	return r;
}

/**
 * Parse a MAC layer address.
 * The standard (IEEE 802) format for printing MAC-48 addresses in
 * human-friendly form is six groups of two hexadecimal digits,
 * separated by hyphens (-) or colons (:), in transmission order
 * (e.g. 01-23-45-67-89-ab or 01:23:45:67:89:ab ).
 * This form is also commonly used for EUI-64.
 * from: http://en.wikipedia.org/wiki/MAC_address
 *
 * This parser must start on a hex digit.
 * added 2015-05-04 by rgerhards, v1.1.2
 */
PARSER(MAC48)
	size_t i = *offs;
	char delim;

	if(strLen < i + 17 || /* this motif has exactly 17 characters */
	   !isxdigit(str[i]) ||
	   !isxdigit(str[i+1])
	   )
		FAIL(LN_WRONGPARSER);

	if(str[i+2] == ':')
		delim = ':';
	else if(str[i+2] == '-')
		delim = '-';
	else
		FAIL(LN_WRONGPARSER);

	/* first byte ok */
	if(!isxdigit(str[i+3])  ||
	   !isxdigit(str[i+4])  ||
	   str[i+5] != delim    || /* 2nd byte ok */
	   !isxdigit(str[i+6])  ||
	   !isxdigit(str[i+7])  ||
	   str[i+8] != delim    || /* 3rd byte ok */
	   !isxdigit(str[i+9])  ||
	   !isxdigit(str[i+10]) ||
	   str[i+11] != delim   || /* 4th byte ok */
	   !isxdigit(str[i+12]) ||
	   !isxdigit(str[i+13]) ||
	   str[i+14] != delim   || /* 5th byte ok */
	   !isxdigit(str[i+15]) ||
	   !isxdigit(str[i+16])    /* 6th byte ok */
	   )
		FAIL(LN_WRONGPARSER);

	/* success, persist */
	*parsed = 17;
	r = 0; /* success */

	if(value != NULL) {
		CHKN(*value = json_object_new_string_len(str+i, 17));
	}

done:
	return r;
}


/* This parses the extension value and updates the index
 * to point to the end of it.
 */
static int
cefParseExtensionValue(const char *const __restrict__ str,
	const size_t strLen,
	size_t *__restrict__ iEndVal)
{
	int r = 0;
	size_t i = *iEndVal;
	size_t iLastWordBegin;
	/* first find next unquoted equal sign and record begin of
	 * last word in front of it - this is the actual end of the
	 * current name/value pair and the begin of the next one.
	 */
	int hadSP = 0;
	int inEscape = 0;
	for(iLastWordBegin = 0 ; i < strLen ; ++i) {
		if(inEscape) {
			if(str[i] != '=' &&
			   str[i] != '\\' &&
			   str[i] != 'r' &&
			   str[i] != 'n')
			FAIL(LN_WRONGPARSER);
			inEscape = 0;
		} else {
			if(str[i] == '=') {
				break;
			} else if(str[i] == '\\') {
				inEscape = 1;
			} else if(str[i] == ' ') {
				hadSP = 1;
			} else {
				if(hadSP) {
					iLastWordBegin = i;
					hadSP = 0;
				}
			}
		}
	}

	/* Note: iLastWordBegin can never be at offset zero, because
	 * the CEF header starts there!
	 */
	if(i < strLen) {
		*iEndVal = (iLastWordBegin == 0) ? i : iLastWordBegin - 1;
	} else {
		*iEndVal = i;
	}
done:
	return r;
}

/* must be positioned on first char of name, returns index
 * of end of name.
 * Note: ArcSight violates the CEF spec ifself: they generate
 * leading underscores in their extension names, which are
 * definetly not alphanumeric. We still accept them...
 * They also seem to use dots.
 */
static int
cefParseName(const char *const __restrict__ str,
	const size_t strLen,
	size_t *const __restrict__ i)
{
	int r = 0;
	while(*i < strLen && str[*i] != '=') {
		if(!(isalnum(str[*i]) || str[*i] == '_' || str[*i] == '.'))
			FAIL(LN_WRONGPARSER);
		++(*i);
	}
done:
	return r;
}

/* parse CEF extensions. They are basically name=value
 * pairs with the ugly exception that values may contain
 * spaces but need NOT to be quoted. Thankfully, at least
 * names are specified as being alphanumeric without spaces
 * in them. So we must add a lookahead parser to check if
 * a word is a name (and thus the begin of a new pair) or
 * not. This is done by subroutines.
 */
static int
cefParseExtensions(const char *const __restrict__ str,
	const size_t strLen,
	size_t *const __restrict__ offs,
	json_object *const __restrict__ jroot)
{
	int r = 0;
	size_t i = *offs;
	size_t iName, lenName;
	size_t iValue, lenValue;
	char *name = NULL;
	char *value = NULL;
	
	while(i < strLen) {
		while(i < strLen && str[i] == ' ')
			++i;
		iName = i;
		CHKR(cefParseName(str, strLen, &i));
		if(i+1 >= strLen || str[i] != '=')
			FAIL(LN_WRONGPARSER);
		lenName = i - iName;
		++i; /* skip '=' */

		iValue = i;
		CHKR(cefParseExtensionValue(str, strLen, &i));
		lenValue = i - iValue;

		++i; /* skip past value */

		if(jroot != NULL) {
			CHKN(name = malloc(sizeof(char) * (lenName + 1)));
			memcpy(name, str+iName, lenName);
			name[lenName] = '\0';
			CHKN(value = malloc(sizeof(char) * (lenValue + 1)));
			/* copy value but escape it */
			size_t iDst = 0;
			for(size_t iSrc = 0 ; iSrc < lenValue ; ++iSrc) {
				if(str[iValue+iSrc] == '\\') {
					++iSrc; /* we know the next char must exist! */
					switch(str[iValue+iSrc]) {
					case '=':	value[iDst] = '=';
							break;
					case 'n':	value[iDst] = '\n';
							break;
					case 'r':	value[iDst] = '\r';
							break;
					case '\\':	value[iDst] = '\\';
							break;
					default:	break;
					}
				} else {
					value[iDst] = str[iValue+iSrc];
				}
				++iDst;
			}
			value[iDst] = '\0';
			json_object *json;
			CHKN(json = json_object_new_string(value));
			json_object_object_add(jroot, name, json);
			free(name); name = NULL;
			free(value); value = NULL;
		}
	}

done:
	free(name);
	free(value);
	return r;
}

/* gets a CEF header field. Must be positioned on the
 * first char after the '|' in front of field.
 * Note that '|' may be escaped as "\|", which also means
 * we need to supprot "\\" (see CEF spec for details).
 * We return the string in *val, if val is non-null. In
 * that case we allocate memory that the caller must free.
 * This is necessary because there are potentially escape
 * sequences inside the string.
 */
static int
cefGetHdrField(const char *const __restrict__ str,
	const size_t strLen,
	size_t *const __restrict__ offs,
	char **val)
{
	int r = 0;
	size_t i = *offs;
	assert(str[i] != '|');
	while(i < strLen && str[i] != '|') {
		if(str[i] == '\\') {
			++i; /* skip esc char */
			if(str[i] != '\\' && str[i] != '|')
				FAIL(LN_WRONGPARSER);
		}
		++i; /* scan to next delimiter */
	}

	if(str[i] != '|')
		FAIL(LN_WRONGPARSER);

	const size_t iBegin = *offs;
	/* success, persist */
	*offs = i + 1;

	if(val == NULL) {
		r = 0;
		goto done;
	}
	
	const size_t len = i - iBegin;
	CHKN(*val = malloc(len + 1));
	size_t iDst = 0;
	for(size_t iSrc = 0 ; iSrc < len ; ++iSrc) {
		if(str[iBegin+iSrc] == '\\')
			++iSrc; /* we already checked above that this is OK! */
		(*val)[iDst++] = str[iBegin+iSrc];
	}
	(*val)[iDst] = 0;
	r = 0;
done:
	return r;
}

/**
 * Parser for ArcSight Common Event Format (CEF) version 0.
 * added 2015-05-05 by rgerhards, v1.1.2
 */
PARSER(CEF)
	size_t i = *offs;
	char *vendor = NULL;
	char *product = NULL;
	char *version = NULL;
	char *sigID = NULL;
	char *name = NULL;
	char *severity = NULL;

	/* minumum header: "CEF:0|x|x|x|x|x|x|" -->  17 chars */
	if(strLen < i + 17 ||
	   str[i]   != 'C' ||
	   str[i+1] != 'E' ||
	   str[i+2] != 'F' ||
	   str[i+3] != ':' ||
	   str[i+4] != '0' ||
	   str[i+5] != '|'
	   )	FAIL(LN_WRONGPARSER);
	
	i += 6; /* position on '|' */

	CHKR(cefGetHdrField(str, strLen, &i, (value == NULL) ? NULL : &vendor));
	CHKR(cefGetHdrField(str, strLen, &i, (value == NULL) ? NULL : &product));
	CHKR(cefGetHdrField(str, strLen, &i, (value == NULL) ? NULL : &version));
	CHKR(cefGetHdrField(str, strLen, &i, (value == NULL) ? NULL : &sigID));
	CHKR(cefGetHdrField(str, strLen, &i, (value == NULL) ? NULL : &name));
	CHKR(cefGetHdrField(str, strLen, &i, (value == NULL) ? NULL : &severity));
	++i; /* skip over terminal '|' */

	/* OK, we now know we have a good header. Now, we need
	 * to process extensions.
	 * This time, we do NOT pre-process the extension, but rather
	 * persist them directly to JSON. This is contrary to other
	 * parsers, but as the CEF header is pretty unique, this time
	 * it is exteremely unlike we will get a no-match during
	 * extension processing. Even if so, nothing bad happens, as
	 * the extracted data is discarded. But the regular case saves
	 * us processing time and complexity. The only time when we
	 * cannot directly process it is when the caller asks us not
	 * to persist the data. So this must be handled differently.
	 */
	 size_t iBeginExtensions = i;
	 CHKR(cefParseExtensions(str, strLen, &i, NULL));

	/* success, persist */
	*parsed = *offs - i;
	r = 0; /* success */

	if(value != NULL) {
		CHKN(*value = json_object_new_object());
		json_object *json;
		CHKN(json = json_object_new_string(vendor));
		json_object_object_add(*value, "DeviceVendor", json);
		CHKN(json = json_object_new_string(product));
		json_object_object_add(*value, "DeviceProduct", json);
		CHKN(json = json_object_new_string(version));
		json_object_object_add(*value, "DeviceVersion", json);
		CHKN(json = json_object_new_string(sigID));
		json_object_object_add(*value, "SignatureID", json);
		CHKN(json = json_object_new_string(name));
		json_object_object_add(*value, "Name", json);
		CHKN(json = json_object_new_string(severity));
		json_object_object_add(*value, "Severity", json);

		json_object *jext;
		CHKN(jext = json_object_new_object());
		json_object_object_add(*value, "Extensions", jext);

		i = iBeginExtensions;
		cefParseExtensions(str, strLen, &i, jext);
	}

done:
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		value = NULL;
	}
	free(vendor);
	free(product);
	free(version);
	free(sigID);
	free(name);
	free(severity);
	return r;
}

/**
 * Parser for Checkpoint LEA on-disk format.
 * added 2015-06-18 by rgerhards, v1.1.2
 */
PARSER(CheckpointLEA)
	size_t i = *offs;
	size_t iName, lenName;
	size_t iValue, lenValue;
	int foundFields = 0;
	char *name = NULL;
	char *val = NULL;

	while(i < strLen) {
		while(i < strLen && str[i] == ' ') /* skip leading SP */
			++i;
		if(i == strLen) { /* OK if just trailing space */
			if(foundFields == 0)
				FAIL(LN_WRONGPARSER);
			break; /* we are done with the loop, all processed */
		} else {
			++foundFields;
		}
		iName = i;
		/* TODO: do a stricter check? ... but we don't have a spec */
		while(i < strLen && str[i] != ':') {
			++i;
		}
		if(i+1 >= strLen || str[i] != ':')
			FAIL(LN_WRONGPARSER);
		lenName = i - iName;
		++i; /* skip ':' */

		while(i < strLen && str[i] == ' ') /* skip leading SP */
			++i;
		iValue = i;
		while(i < strLen && str[i] != ';') {
			++i;
		}
		if(i+1 > strLen || str[i] != ';')
			FAIL(LN_WRONGPARSER);
		lenValue = i - iValue;
		++i; /* skip ';' */

		if(value != NULL) {
			CHKN(name = malloc(sizeof(char) * (lenName + 1)));
			memcpy(name, str+iName, lenName);
			name[lenName] = '\0';
			CHKN(val = malloc(sizeof(char) * (lenValue + 1)));
			memcpy(val, str+iValue, lenValue);
			val[lenValue] = '\0';
			if(*value == NULL)
				CHKN(*value = json_object_new_object());
			json_object *json;
			CHKN(json = json_object_new_string(val));
			json_object_object_add(*value, name, json);
			free(name); name = NULL;
			free(val); val = NULL;
		}
	}

	/* success, persist */
	*parsed = *offs - i;
	r = 0; /* success */

done:
	free(name);
	free(val);
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		value = NULL;
	}
	return r;
}
