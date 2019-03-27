/**
 * @file enc_csv.c
 * Encoder for CSV format. Note: CEE currently think about what a
 * CEE-compliant CSV format may look like. As such, the format of
 * this output will most probably change once the final decision
 * has been made. At this time (2010-12), I do NOT even try to
 * stay inline with the discussion.
 *
 * This file contains code from all related objects that is required in
 * order to encode this format. The core idea of putting all of this into
 * a single file is that this makes it very straightforward to write
 * encoders for different encodings, as all is in one place.
 *
 */
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
#include <string.h>

#include <libestr.h>

#include "lognorm.h"
#include "internal.h"
#include "enc.h"

static char hexdigit[16] =
	{'0', '1', '2', '3', '4', '5', '6', '7', '8',
	 '9', 'A', 'B', 'C', 'D', 'E', 'F' };

/* TODO: CSV encoding for Unicode characters is as of RFC4627 not fully
 * supported. The algorithm is that we must build the wide character from
 * UTF-8 (if char > 127) and build the full 4-octet Unicode character out
 * of it. Then, this needs to be encoded. Currently, we work on a
 * byte-by-byte basis, which simply is incorrect.
 * rgerhards, 2010-11-09
 */
static int
ln_addValue_CSV(const char *buf, es_str_t **str)
{
	int r;
	unsigned char c;
	es_size_t i;
	char numbuf[4];
	int j;

	assert(str != NULL);
	assert(*str != NULL);
	assert(buf != NULL);

	for(i = 0; i < strlen(buf); i++) {
		c = buf[i];
		if((c >= 0x23 && c <= 0x5b)
		   || (c >= 0x5d /* && c <= 0x10FFFF*/)
		   || c == 0x20 || c == 0x21) {
			/* no need to escape */
			es_addChar(str, c);
		} else {
			/* we must escape, try RFC4627-defined special sequences first */
			switch(c) {
			case '\0':
				es_addBuf(str, "\\u0000", 6);
				break;
			case '\"':
				es_addBuf(str, "\\\"", 2);
				break;
			case '\\':
				es_addBuf(str, "\\\\", 2);
				break;
			case '\010':
				es_addBuf(str, "\\b", 2);
				break;
			case '\014':
				es_addBuf(str, "\\f", 2);
				break;
			case '\n':
				es_addBuf(str, "\\n", 2);
				break;
			case '\r':
				es_addBuf(str, "\\r", 2);
				break;
			case '\t':
				es_addBuf(str, "\\t", 2);
				break;
			default:
				/* TODO : proper Unicode encoding (see header comment) */
				for(j = 0 ; j < 4 ; ++j) {
					numbuf[3-j] = hexdigit[c % 16];
					c = c / 16;
				}
				es_addBuf(str, "\\u", 2);
				es_addBuf(str, numbuf, 4);
				break;
			}
		}
	}
	r = 0;

	return r;
}


static int
ln_addField_CSV(struct json_object *field, es_str_t **str)
{
	int r, i;
	struct json_object *obj;
	int needComma = 0;
	const char *value;
	
	assert(field != NULL);
	assert(str != NULL);
	assert(*str != NULL);

	switch(json_object_get_type(field)) {
	case json_type_array:
		CHKR(es_addChar(str, '['));
		for (i = json_object_array_length(field) - 1; i >= 0; i--) {
			if(needComma)
				es_addChar(str, ',');
			else
				needComma = 1;
			CHKN(obj = json_object_array_get_idx(field, i));
			CHKN(value = json_object_get_string(obj));
			CHKR(ln_addValue_CSV(value, str));
		}
		CHKR(es_addChar(str, ']'));
		break;
	case json_type_string:
	case json_type_int:
		CHKN(value = json_object_get_string(field));
		CHKR(ln_addValue_CSV(value, str));
		break;
	case json_type_null:
	case json_type_boolean:
	case json_type_double:
	case json_type_object:
		CHKR(es_addBuf(str, "***unsupported type***", sizeof("***unsupported type***")-1));
		break;
	default:
		CHKR(es_addBuf(str, "***OBJECT***", sizeof("***OBJECT***")-1));
	}

	r = 0;

done:
	return r;
}


int
ln_fmtEventToCSV(struct json_object *json, es_str_t **str, es_str_t *extraData)
{
	int r = -1;
	int needComma = 0;
	struct json_object *field;
	char *namelist = NULL, *name, *nn;

	assert(json != NULL);
	assert(json_object_is_type(json, json_type_object));
	
	if((*str = es_newStr(256)) == NULL)
		goto done;
	if(extraData == NULL)
		goto done;

	CHKN(namelist = es_str2cstr(extraData, NULL));

	for (name = namelist; name != NULL; name = nn) {
		for (nn = name; *nn != '\0' && *nn != ',' && *nn != ' '; nn++)
			{ /* do nothing */ }
		if (*nn == '\0') {
			nn = NULL;
		} else {
			*nn = '\0';
			nn++;
		}
		json_object_object_get_ex(json, name, &field);
		if (needComma) {
			CHKR(es_addChar(str, ','));
		} else {
			needComma = 1;
		}
		if (field != NULL) {
			CHKR(es_addChar(str, '"'));
			ln_addField_CSV(field, str);
			CHKR(es_addChar(str, '"'));
		}
	}
	r = 0;
done:
	if (namelist != NULL)
		free(namelist);
	return r;
}
