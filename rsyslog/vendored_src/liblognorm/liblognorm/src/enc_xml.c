/**
 * @file enc-xml.c
 * Encoder for XML format.
 *
 * This file contains code from all related objects that is required in
 * order to encode this format. The core idea of putting all of this into
 * a single file is that this makes it very straightforward to write
 * encoders for different encodings, as all is in one place.
 *
 */
/*
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2016 by Rainer Gerhards and Adiscon GmbH.
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

#include "lognorm.h"
#include "internal.h"
#include "enc.h"

#if 0
static char hexdigit[16] =
	{'0', '1', '2', '3', '4', '5', '6', '7', '8',
	 '9', 'A', 'B', 'C', 'D', 'E', 'F' };
#endif

/* TODO: XML encoding for Unicode characters is as of RFC4627 not fully
 * supported. The algorithm is that we must build the wide character from
 * UTF-8 (if char > 127) and build the full 4-octet Unicode character out
 * of it. Then, this needs to be encoded. Currently, we work on a
 * byte-by-byte basis, which simply is incorrect.
 * rgerhards, 2010-11-09
 */
static int
ln_addValue_XML(const char *value, es_str_t **str)
{
	int r;
	unsigned char c;
	es_size_t i;
#if 0
	char numbuf[4];
	int j;
#endif

	assert(str != NULL);
	assert(*str != NULL);
	assert(value != NULL);
	// TODO: support other types!
	es_addBuf(str, "<value>", 7);

	for(i = 0 ; i < strlen(value) ; ++i) {
		c = value[i];
		switch(c) {
		case '\0':
			es_addBuf(str, "&#00;", 5);
			break;
#if 0
		case '\n':
			es_addBuf(str, "&#10;", 5);
			break;
		case '\r':
			es_addBuf(str, "&#13;", 5);
			break;
		case '\t':
			es_addBuf(str, "&x08;", 5);
			break;
		case '\"':
			es_addBuf(str, "&quot;", 6);
			break;
#endif
		case '<':
			es_addBuf(str, "&lt;", 4);
			break;
		case '&':
			es_addBuf(str, "&amp;", 5);
			break;
#if 0
		case ',':
			es_addBuf(str, "\\,", 2);
			break;
		case '\'':
			es_addBuf(str, "&apos;", 6);
			break;
#endif
		default:
			es_addChar(str, c);
#if 0
			/* TODO : proper Unicode encoding (see header comment) */
			for(j = 0 ; j < 4 ; ++j) {
				numbuf[3-j] = hexdigit[c % 16];
				c = c / 16;
			}
			es_addBuf(str, "\\u", 2);
			es_addBuf(str, numbuf, 4);
			break;
#endif
		}
	}
	es_addBuf(str, "</value>", 8);
	r = 0;

	return r;
}


static int
ln_addField_XML(char *name, struct json_object *field, es_str_t **str)
{
	int r;
	int i;
	const char *value;
	struct json_object *obj;

	assert(field != NULL);
	assert(str != NULL);
	assert(*str != NULL);

	CHKR(es_addBuf(str, "<field name=\"", 13));
	CHKR(es_addBuf(str, name, strlen(name)));
	CHKR(es_addBuf(str, "\">", 2));

	switch(json_object_get_type(field)) {
	case json_type_array:
		for (i = json_object_array_length(field) - 1; i >= 0; i--) {
			CHKN(obj = json_object_array_get_idx(field, i));
			CHKN(value = json_object_get_string(obj));
			CHKR(ln_addValue_XML(value, str));
		}
		break;
	case json_type_string:
	case json_type_int:
		CHKN(value = json_object_get_string(field));
		CHKR(ln_addValue_XML(value, str));
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
	
	CHKR(es_addBuf(str, "</field>", 8));
	r = 0;

done:
	return r;
}


static inline int
ln_addTags_XML(struct json_object *taglist, es_str_t **str)
{
	int r = 0;
	struct json_object *tagObj;
	const char *tagCstr;
	int i;

	CHKR(es_addBuf(str, "<event.tags>", 12));
	for (i = json_object_array_length(taglist) - 1; i >= 0; i--) {
		CHKR(es_addBuf(str, "<tag>", 5));
		CHKN(tagObj = json_object_array_get_idx(taglist, i));
		CHKN(tagCstr = json_object_get_string(tagObj));
		CHKR(es_addBuf(str, (char*)tagCstr, strlen(tagCstr)));
		CHKR(es_addBuf(str, "</tag>", 6));
	}
	CHKR(es_addBuf(str, "</event.tags>", 13));

done:	return r;
}


int
ln_fmtEventToXML(struct json_object *json, es_str_t **str)
{
	int r = -1;
	struct json_object *tags;

	assert(json != NULL);
	assert(json_object_is_type(json, json_type_object));
	
	if((*str = es_newStr(256)) == NULL)
		goto done;

	es_addBuf(str, "<event>", 7);
	if(json_object_object_get_ex(json, "event.tags", &tags)) {
		CHKR(ln_addTags_XML(tags, str));
	}
	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		char *const name = (char*) json_object_iter_peek_name(&it);
		if (strcmp(name, "event.tags")) {
			ln_addField_XML(name, json_object_iter_peek_value(&it), str);
		}
		json_object_iter_next(&it);
	}

	es_addBuf(str, "</event>", 8);

done:
	return r;
}
