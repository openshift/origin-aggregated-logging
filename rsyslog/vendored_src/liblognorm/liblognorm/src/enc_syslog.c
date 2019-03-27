/**
 * @file enc_syslog.c
 * Encoder for syslog format.
 * This file contains code from all related objects that is required in
 * order to encode syslog format. The core idea of putting all of this into
 * a single file is that this makes it very straightforward to write
 * encoders for different encodings, as all is in one place.
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

#include <libestr.h>

#include "internal.h"
#include "liblognorm.h"
#include "enc.h"

static int
ln_addValue_Syslog(const char *value, es_str_t **str)
{
	int r;
	es_size_t i;

	assert(str != NULL);
	assert(*str != NULL);
	assert(value != NULL);

	for(i = 0; i < strlen(value); i++) {
		switch(value[i]) {
		case '\0':
			es_addChar(str, '\\');
			es_addChar(str, '0');
			break;
		case '\n':
			es_addChar(str, '\\');
			es_addChar(str, 'n');
			break;
		/* TODO : add rest of control characters here... */
		case ',': /* comma is CEE-reserved for lists */
			es_addChar(str, '\\');
			es_addChar(str, ',');
			break;
#if 0 /* alternative encoding for discussion */
		case '^': /* CEE-reserved for lists */
			es_addChar(str, '\\');
			es_addChar(str, '^');
			break;
#endif
		/* at this layer ... do we need to think about transport
		 * encoding at all? Or simply leave it to the transport agent?
		 */
		case '\\': /* RFC5424 reserved */
			es_addChar(str, '\\');
			es_addChar(str, '\\');
			break;
		case ']': /* RFC5424 reserved */
			es_addChar(str, '\\');
			es_addChar(str, ']');
			break;
		case '\"': /* RFC5424 reserved */
			es_addChar(str, '\\');
			es_addChar(str, '\"');
			break;
		default:
			es_addChar(str, value[i]);
			break;
		}
	}
	r = 0;

	return r;
}


static int
ln_addField_Syslog(char *name, struct json_object *field, es_str_t **str)
{
	int r;
	const char *value;
	int needComma = 0;
	struct json_object *obj;
	int i;

	assert(field != NULL);
	assert(str != NULL);
	assert(*str != NULL);

	CHKR(es_addBuf(str, name, strlen(name)));
	CHKR(es_addBuf(str, "=\"", 2));
	switch(json_object_get_type(field)) {
	case json_type_array:
		for (i = json_object_array_length(field) - 1; i >= 0; i--) {
			if(needComma)
				es_addChar(str, ',');
			else
				needComma = 1;
			CHKN(obj = json_object_array_get_idx(field, i));
			CHKN(value = json_object_get_string(obj));
			CHKR(ln_addValue_Syslog(value, str));
		}
		break;
	case json_type_string:
	case json_type_int:
		CHKN(value = json_object_get_string(field));
		CHKR(ln_addValue_Syslog(value, str));
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
	CHKR(es_addChar(str, '\"'));
	r = 0;

done:
	return r;
}


static inline int
ln_addTags_Syslog(struct json_object *taglist, es_str_t **str)
{
	int r = 0;
	struct json_object *tagObj;
	int needComma = 0;
	const char *tagCstr;
	int i;

	assert(json_object_is_type(taglist, json_type_array));

	CHKR(es_addBuf(str, " event.tags=\"", 13));
	for (i = json_object_array_length(taglist) - 1; i >= 0; i--) {
		if(needComma)
			es_addChar(str, ',');
		else
			needComma = 1;
		CHKN(tagObj = json_object_array_get_idx(taglist, i));
		CHKN(tagCstr = json_object_get_string(tagObj));
		CHKR(es_addBuf(str, (char*)tagCstr, strlen(tagCstr)));
	}
	es_addChar(str, '"');

done:	return r;
}


int
ln_fmtEventToRFC5424(struct json_object *json, es_str_t **str)
{
	int r = -1;
	struct json_object *tags;

	assert(json != NULL);
	assert(json_object_is_type(json, json_type_object));
	if((*str = es_newStr(256)) == NULL)
		goto done;

	es_addBuf(str, "[cee@115", 8);

	if(json_object_object_get_ex(json, "event.tags", &tags)) {
		CHKR(ln_addTags_Syslog(tags, str));
	}
	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		char *const name = (char*)json_object_iter_peek_name(&it);
		if (strcmp(name, "event.tags")) {
			es_addChar(str, ' ');
			ln_addField_Syslog(name, json_object_iter_peek_value(&it), str);
		}
		json_object_iter_next(&it);
	}
	es_addChar(str, ']');

done:
	return r;
}
