/* samp.c -- code for ln_v1_samp objects.
 *
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
#include "config.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>

#define LOGNORM_V1_SUBSYSTEM /* indicate we are old cruft */
#include "v1_liblognorm.h"
#include "internal.h"
#include "lognorm.h"
#include "samp.h"
#include "v1_ptree.h"
#include "v1_samp.h"
#include "v1_parser.h"


/**
 * Construct a sample object.
 */
struct ln_v1_samp*
ln_v1_sampCreate(ln_ctx __attribute__((unused)) ctx)
{
	struct ln_v1_samp* samp;

	if((samp = calloc(1, sizeof(struct ln_v1_samp))) == NULL)
		goto done;

	/* place specific init code here (none at this time) */

done:	return samp;
}

void
ln_v1_sampFree(ln_ctx __attribute__((unused)) ctx, struct ln_v1_samp *samp)
{
	free(samp);
}


/**
 * Extract a field description from a sample.
 * The field description is added to the tail of the current
 * subtree's field list. The parse buffer must be position on the
 * leading '%' that starts a field definition. It is a program error
 * if this condition is not met.
 *
 * Note that we break up the object model and access ptree members
 * directly. Let's consider us a friend of ptree. This is necessary
 * to optimize the structure for a high-speed parsing process.
 *
 * @param[in] str a temporary work string. This is passed in to save the
 * 		  creation overhead
 * @returns 0 on success, something else otherwise
 */
static int
addFieldDescr(ln_ctx ctx, struct ln_ptree **subtree, es_str_t *rule,
	        es_size_t *bufOffs, es_str_t **str)
{
	int r;
	ln_fieldList_t *node = ln_v1_parseFieldDescr(ctx, rule, bufOffs, str, &r);
	assert(subtree != NULL);

	if (node != NULL) CHKR(ln_addFDescrToPTree(subtree, node));
done:
	return r;
}

ln_fieldList_t*
ln_v1_parseFieldDescr(ln_ctx ctx, es_str_t *rule, es_size_t *bufOffs, es_str_t **str, int* ret)
{
	int r = 0;
	ln_fieldList_t *node;
	es_size_t i = *bufOffs;
	char *cstr;	/* for debug mode strings */
	unsigned char *buf;
	es_size_t lenBuf;
	void* (*constructor_fn)(ln_fieldList_t *, ln_ctx) = NULL;

	buf = es_getBufAddr(rule);
	lenBuf = es_strlen(rule);
	assert(buf[i] == '%');
	++i;	/* "eat" ':' */
	CHKN(node = calloc(1, sizeof(ln_fieldList_t)));
	node->subtree = NULL;
	node->next = NULL;
	node->data = NULL;
	node->raw_data = NULL;
	node->parser_data = NULL;
	node->parser_data_destructor = NULL;
	CHKN(node->name = es_newStr(16));

	/* skip leading whitespace in field name */
	while(i < lenBuf && isspace(buf[i]))
		++i;
	while(i < lenBuf && buf[i] != ':') {
		CHKR(es_addChar(&node->name, buf[i++]));
	}

	if(es_strlen(node->name) == 0) {
		FAIL(LN_INVLDFDESCR);
	}

	if(ctx->debug) {
		cstr = es_str2cstr(node->name, NULL);
		ln_dbgprintf(ctx, "parsed field: '%s'", cstr);
		free(cstr);
	}

	if(buf[i] != ':') {
		/* may be valid later if we have a loaded CEE dictionary
		 * and the name is present inside it.
		 */
		FAIL(LN_INVLDFDESCR);
	}
	++i; /* skip ':' */

	/* parse and process type (trailing whitespace must be trimmed) */
	es_emptyStr(*str);
	size_t j = i;
	/* scan for terminator */
	while(j < lenBuf && buf[j] != ':' && buf[j] != '%')
		++j;
	/* now trim trailing space backwards */
	size_t next = j;
	--j;
	while(j >= i && isspace(buf[j]))
		--j;
	/* now copy */
	while(i <= j) {
		CHKR(es_addChar(str, buf[i++]));
	}
	/* finally move i to consumed position */
	i = next;

	if(i == lenBuf) {
		FAIL(LN_INVLDFDESCR);
	}

	node->isIPTables = 0; /* first assume no special parser is used */
	if(!es_strconstcmp(*str, "date-rfc3164")) {
		node->parser = ln_parseRFC3164Date;
	} else if(!es_strconstcmp(*str, "date-rfc5424")) {
		node->parser = ln_parseRFC5424Date;
	} else if(!es_strconstcmp(*str, "number")) {
		node->parser = ln_parseNumber;
	} else if(!es_strconstcmp(*str, "float")) {
		node->parser = ln_parseFloat;
	} else if(!es_strconstcmp(*str, "hexnumber")) {
		node->parser = ln_parseHexNumber;
	} else if(!es_strconstcmp(*str, "kernel-timestamp")) {
		node->parser = ln_parseKernelTimestamp;
	} else if(!es_strconstcmp(*str, "whitespace")) {
		node->parser = ln_parseWhitespace;
	} else if(!es_strconstcmp(*str, "ipv4")) {
		node->parser = ln_parseIPv4;
	} else if(!es_strconstcmp(*str, "ipv6")) {
		node->parser = ln_parseIPv6;
	} else if(!es_strconstcmp(*str, "word")) {
		node->parser = ln_parseWord;
	} else if(!es_strconstcmp(*str, "alpha")) {
		node->parser = ln_parseAlpha;
	} else if(!es_strconstcmp(*str, "rest")) {
		node->parser = ln_parseRest;
	} else if(!es_strconstcmp(*str, "op-quoted-string")) {
		node->parser = ln_parseOpQuotedString;
	} else if(!es_strconstcmp(*str, "quoted-string")) {
		node->parser = ln_parseQuotedString;
	} else if(!es_strconstcmp(*str, "date-iso")) {
		node->parser = ln_parseISODate;
	} else if(!es_strconstcmp(*str, "time-24hr")) {
		node->parser = ln_parseTime24hr;
	} else if(!es_strconstcmp(*str, "time-12hr")) {
		node->parser = ln_parseTime12hr;
	} else if(!es_strconstcmp(*str, "duration")) {
		node->parser = ln_parseDuration;
	} else if(!es_strconstcmp(*str, "cisco-interface-spec")) {
		node->parser = ln_parseCiscoInterfaceSpec;
	} else if(!es_strconstcmp(*str, "json")) {
		node->parser = ln_parseJSON;
	} else if(!es_strconstcmp(*str, "cee-syslog")) {
		node->parser = ln_parseCEESyslog;
	} else if(!es_strconstcmp(*str, "mac48")) {
		node->parser = ln_parseMAC48;
	} else if(!es_strconstcmp(*str, "name-value-list")) {
		node->parser = ln_parseNameValue;
	} else if(!es_strconstcmp(*str, "cef")) {
		node->parser = ln_parseCEF;
	} else if(!es_strconstcmp(*str, "checkpoint-lea")) {
		node->parser = ln_parseCheckpointLEA;
	} else if(!es_strconstcmp(*str, "v2-iptables")) {
		node->parser = ln_parsev2IPTables;
	} else if(!es_strconstcmp(*str, "iptables")) {
		node->parser = NULL;
		node->isIPTables = 1;
	} else if(!es_strconstcmp(*str, "string-to")) {
		/* TODO: check extra data!!!! (very important) */
		node->parser = ln_parseStringTo;
	} else if(!es_strconstcmp(*str, "char-to")) {
		/* TODO: check extra data!!!! (very important) */
		node->parser = ln_parseCharTo;
	} else if(!es_strconstcmp(*str, "char-sep")) {
		/* TODO: check extra data!!!! (very important) */
		node->parser = ln_parseCharSeparated;
	} else if(!es_strconstcmp(*str, "tokenized")) {
		node->parser = ln_parseTokenized;
		constructor_fn = tokenized_parser_data_constructor;
		node->parser_data_destructor = tokenized_parser_data_destructor;
	}
#ifdef FEATURE_REGEXP
	else if(!es_strconstcmp(*str, "regex")) {
		node->parser = ln_parseRegex;
		constructor_fn = regex_parser_data_constructor;
		node->parser_data_destructor = regex_parser_data_destructor;
	}
#endif
	else if (!es_strconstcmp(*str, "recursive")) {
		node->parser = ln_parseRecursive;
		constructor_fn = recursive_parser_data_constructor;
		node->parser_data_destructor = recursive_parser_data_destructor;
	} else if (!es_strconstcmp(*str, "descent")) {
		node->parser = ln_parseRecursive;
		constructor_fn = descent_parser_data_constructor;
		node->parser_data_destructor = recursive_parser_data_destructor;
	} else if (!es_strconstcmp(*str, "interpret")) {
		node->parser = ln_parseInterpret;
		constructor_fn = interpret_parser_data_constructor;
		node->parser_data_destructor = interpret_parser_data_destructor;
	} else if (!es_strconstcmp(*str, "suffixed")) {
		node->parser = ln_parseSuffixed;
		constructor_fn = suffixed_parser_data_constructor;
		node->parser_data_destructor = suffixed_parser_data_destructor;
	} else if (!es_strconstcmp(*str, "named_suffixed")) {
		node->parser = ln_parseSuffixed;
		constructor_fn = named_suffixed_parser_data_constructor;
		node->parser_data_destructor = suffixed_parser_data_destructor;
	} else {
		cstr = es_str2cstr(*str, NULL);
		ln_errprintf(ctx, 0, "invalid field type '%s'", cstr);
		free(cstr);
		FAIL(LN_INVLDFDESCR);
	}

	if(buf[i] == '%') {
		i++;
	} else {
		/* parse extra data */
		CHKN(node->data = es_newStr(8));
		i++;
		while(i < lenBuf) {
			if(buf[i] == '%') {
				++i;
				break; /* end of field */
			}
			CHKR(es_addChar(&node->data, buf[i++]));
		}
		node->raw_data = es_strdup(node->data);
		es_unescapeStr(node->data);
		if(ctx->debug) {
			cstr = es_str2cstr(node->data, NULL);
			ln_dbgprintf(ctx, "parsed extra data: '%s'", cstr);
			free(cstr);
		}
	}

	if (constructor_fn) node->parser_data = constructor_fn(node, ctx);


	*bufOffs = i;
done:
	if (r != 0) {
		if (node->name != NULL) es_deleteStr(node->name);
		free(node);
		node = NULL;
	}
	*ret = r;
	return node;
}

/**
 * Parse a Literal string out of the template and add it to the tree.
 * @param[in] ctx the context
 * @param[in/out] subtree on entry, current subtree, on exist newest
 *    		deepest subtree
 * @param[in] rule string with current rule
 * @param[in/out] bufOffs parse pointer, up to which offset is parsed
 * 		(is updated so that it points to first char after consumed
 * 		string on exit).
 * @param[out] str literal extracted (is empty, when no litral could be found)
 * @return 0 on success, something else otherwise
 */
static int
parseLiteral(ln_ctx ctx, struct ln_ptree **subtree, es_str_t *rule,
	     es_size_t *bufOffs, es_str_t **str)
{
	int r = 0;
	es_size_t i = *bufOffs;
	unsigned char *buf;
	es_size_t lenBuf;

	es_emptyStr(*str);
	buf = es_getBufAddr(rule);
	lenBuf = es_strlen(rule);
	/* extract maximum length literal */
	while(i < lenBuf) {
		if(buf[i] == '%') {
			if(i+1 < lenBuf && buf[i+1] != '%') {
				break; /* field start is end of literal */
			}
			if (++i == lenBuf) break;
		}
		CHKR(es_addChar(str, buf[i]));
		++i;
	}

	es_unescapeStr(*str);
	if(ctx->debug) {
		char *cstr = es_str2cstr(*str, NULL);
		ln_dbgprintf(ctx, "parsed literal: '%s'", cstr);
		free(cstr);
	}

	*subtree = ln_buildPTree(*subtree, *str, 0);
	*bufOffs = i;
	r = 0;

done:	return r;
}


/* Implementation note:
 * We read in the sample, and split it into chunks of literal text and
 * fields. Each literal text is added as whole to the tree, as is each
 * field individually. To do so, we keep track of our current subtree
 * root, which changes whenever a new part of the tree is build. It is
 * set to the then-lowest part of the tree, where the next step sample
 * data is to be added.
 *
 * This function processes the whole string or returns an error.
 *
 * format: literal1%field:type:extra-data%literal2
 *
 * @returns the new subtree root (or NULL in case of error)
 */
static int
addSampToTree(ln_ctx ctx, es_str_t *rule, struct json_object *tagBucket)
{
	int r = -1;
	struct ln_ptree* subtree;
	es_str_t *str = NULL;
	es_size_t i;

	subtree = ctx->ptree;
	CHKN(str = es_newStr(256));
	i = 0;
	while(i < es_strlen(rule)) {
		ln_dbgprintf(ctx, "addSampToTree %d of %d", i, es_strlen(rule));
		CHKR(parseLiteral(ctx, &subtree, rule, &i, &str));
		/* After the literal there can be field only*/
		if (i < es_strlen(rule)) {
			CHKR(addFieldDescr(ctx, &subtree, rule, &i, &str));
			if (i == es_strlen(rule)) {
				/* finish the tree with empty literal to avoid false merging*/
				CHKR(parseLiteral(ctx, &subtree, rule, &i, &str));
			}
		}
	}

	ln_dbgprintf(ctx, "end addSampToTree %d of %d", i, es_strlen(rule));
	/* we are at the end of rule processing, so this node is a terminal */
	subtree->flags.isTerminal = 1;
	subtree->tags = tagBucket;

done:
	if(str != NULL)
		es_deleteStr(str);
	return r;
}



/**
 * get the initial word of a rule line that tells us the type of the
 * line.
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[out] offs offset after "="
 * @param[out] str string with "linetype-word" (newly created)
 * @returns 0 on success, something else otherwise
 */
static int
getLineType(const char *buf, es_size_t lenBuf, es_size_t *offs, es_str_t **str)
{
	int r = -1;
	es_size_t i;

	*str = es_newStr(16);
	for(i = 0 ; i < lenBuf && buf[i] != '=' ; ++i) {
		CHKR(es_addChar(str, buf[i]));
	}

	if(i < lenBuf)
		++i; /* skip over '=' */
	*offs = i;

done:	return r;
}


/**
 * Get a new common prefix from the config file. That is actually everything from
 * the current offset to the end of line.
 *
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in] offs offset after "="
 * @param[in/out] str string to store common offset. If NULL, it is created,
 * 	 	otherwise it is emptied.
 * @returns 0 on success, something else otherwise
 */
static int
getPrefix(const char *buf, es_size_t lenBuf, es_size_t offs, es_str_t **str)
{
	int r;

	if(*str == NULL) {
		CHKN(*str = es_newStr(lenBuf - offs));
	} else {
		es_emptyStr(*str);
	}

	r = es_addBuf(str, (char*)buf + offs, lenBuf - offs);
done:	return r;
}

/**
 * Extend the common prefix. This means that the line is concatenated
 * to the prefix. This is useful if the same rulebase is to be used with
 * different prefixes (well, not strictly necessary, but probably useful).
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in] offs offset to-be-added text starts
 * @returns 0 on success, something else otherwise
 */
static int
extendPrefix(ln_ctx ctx, const char *buf, es_size_t lenBuf, es_size_t offs)
{
	return es_addBuf(&ctx->rulePrefix, (char*)buf+offs, lenBuf - offs);
}


/**
 * Add a tag to the tag bucket. Helper to processTags.
 * @param[in] ctx current context
 * @param[in] tagname string with tag name
 * @param[out] tagBucket tagbucket to which new tags shall be added
 *                       the tagbucket is created if it is NULL
 * @returns 0 on success, something else otherwise
 */
static int
addTagStrToBucket(ln_ctx ctx, es_str_t *tagname, struct json_object **tagBucket)
{
	int r = -1;
	char *cstr;
	struct json_object *tag;

	if(*tagBucket == NULL) {
		CHKN(*tagBucket = json_object_new_array());
	}
	cstr = es_str2cstr(tagname, NULL);
	ln_dbgprintf(ctx, "tag found: '%s'", cstr);
	CHKN(tag = json_object_new_string(cstr));
	json_object_array_add(*tagBucket, tag);
	free(cstr);
	r = 0;

done:	return r;
}


/**
 * Extract the tags and create a tag bucket out of them
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in,out] poffs offset where tags start, on exit and success
 *                      offset after tag part (excluding ':')
 * @param[out] tagBucket tagbucket to which new tags shall be added
 *                       the tagbucket is created if it is NULL
 * @returns 0 on success, something else otherwise
 */
static int
processTags(ln_ctx ctx, const char *buf, es_size_t lenBuf, es_size_t *poffs, struct json_object **tagBucket)
{
	int r = -1;
	es_str_t *str = NULL;
	es_size_t i;

	assert(poffs != NULL);
	i = *poffs;
	while(i < lenBuf && buf[i] != ':') {
		if(buf[i] == ',') {
			/* end of this tag */
			CHKR(addTagStrToBucket(ctx, str, tagBucket));
			es_deleteStr(str);
			str = NULL;
		} else {
			if(str == NULL) {
				CHKN(str = es_newStr(32));
			}
			CHKR(es_addChar(&str, buf[i]));
		}
		++i;
	}

	if(buf[i] != ':')
		goto done;
	++i; /* skip ':' */

	if(str != NULL) {
		CHKR(addTagStrToBucket(ctx, str, tagBucket));
		es_deleteStr(str);
	}

	*poffs = i;
	r = 0;

done:	return r;
}


/**
 * Process a new rule and add it to tree.
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in] offs offset where rule starts
 * @returns 0 on success, something else otherwise
 */
static int
processRule(ln_ctx ctx, const char *buf, es_size_t lenBuf, es_size_t offs)
{
	int r = -1;
	es_str_t *str;
	struct json_object *tagBucket = NULL;

	ln_dbgprintf(ctx, "sample line to add: '%s'\n", buf+offs);
	CHKR(processTags(ctx, buf, lenBuf, &offs, &tagBucket));

	if(offs == lenBuf) {
		ln_dbgprintf(ctx, "error, actual message sample part is missing");
		// TODO: provide some error indicator to app? We definitely must do (a callback?)
		goto done;
	}
	if(ctx->rulePrefix == NULL) {
		CHKN(str = es_newStr(lenBuf));
	} else {
		CHKN(str = es_strdup(ctx->rulePrefix));
	}
	CHKR(es_addBuf(&str, (char*)buf + offs, lenBuf - offs));
	addSampToTree(ctx, str, tagBucket);
	es_deleteStr(str);
	r = 0;
done:	return r;
}


/**
 * Obtain a field name from a rule base line.
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in/out] offs on entry: offset where tag starts,
 * 		       on exit: updated offset AFTER TAG and (':')
 * @param [out] strTag obtained tag, if successful
 * @returns 0 on success, something else otherwise
 */
static int
getFieldName(ln_ctx __attribute__((unused)) ctx, const char *buf, es_size_t lenBuf, es_size_t *offs,
es_str_t **strTag)
{
	int r = -1;
	es_size_t i;

	i = *offs;
	while(i < lenBuf &&
	       (isalnum(buf[i]) || buf[i] == '_' || buf[i] == '.')) {
		if(*strTag == NULL) {
			CHKN(*strTag = es_newStr(32));
		}
		CHKR(es_addChar(strTag, buf[i]));
		++i;
	}
	*offs = i;
	r = 0;
done:	return r;
}


/**
 * Skip over whitespace.
 * Skips any whitespace present at the offset.
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in/out] offs on entry: offset first unprocessed position
 */
static void
skipWhitespace(ln_ctx __attribute__((unused)) ctx, const char *buf, es_size_t lenBuf, es_size_t *offs)
{
	while(*offs < lenBuf && isspace(buf[*offs])) {
		(*offs)++;
	}
}


/**
 * Obtain an annotation (field) operation.
 * This usually is a plus or minus sign followed by a field name
 * followed (if plus) by an equal sign and the field value. On entry,
 * offs must be positioned on the first unprocessed field (after ':' for
 * the initial field!). Extra whitespace is detected and, if present,
 * skipped. The obtained operation is added to the annotation set provided.
 * Note that extracted string objects are passed to the annotation; thus it
 * is vital NOT to free them (most importantly, this is *not* a memory leak).
 *
 * @param[in] ctx current context
 * @param[in] annot active annotation set to which the operation is to be added
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in/out] offs on entry: offset where tag starts,
 * 		       on exit: updated offset AFTER TAG and (':')
 * @param [out] strTag obtained tag, if successful
 * @returns 0 on success, something else otherwise
 */
static int
getAnnotationOp(ln_ctx ctx, ln_annot *annot, const char *buf, es_size_t lenBuf, es_size_t *offs)
{
	int r = -1;
	es_size_t i;
	es_str_t *fieldName = NULL;
	es_str_t *fieldVal = NULL;
	ln_annot_opcode opc;

	i = *offs;
	skipWhitespace(ctx, buf, lenBuf, &i);
	if(i == lenBuf) {
		r = 0;
		goto done; /* nothing left to process (no error!) */
	}

	if(buf[i] == '+') {
		opc = ln_annot_ADD;
	} else if(buf[i] == '-') {
		ln_dbgprintf(ctx, "annotate op '-' not yet implemented - failing");
		goto fail;
	} else {
		ln_dbgprintf(ctx, "invalid annotate opcode '%c' - failing" , buf[i]);
		goto fail;
	}
	i++;

	if(i == lenBuf) goto fail; /* nothing left to process */

	CHKR(getFieldName(ctx, buf, lenBuf, &i, &fieldName));
	if(i == lenBuf) goto fail; /* nothing left to process */
	if(buf[i] != '=') goto fail; /* format error */
	i++;

	skipWhitespace(ctx, buf, lenBuf, &i);
	if(buf[i] != '"') goto fail; /* format error */
	++i;

	while(i < lenBuf && buf[i] != '"') {
		if(fieldVal == NULL) {
			CHKN(fieldVal = es_newStr(32));
		}
		CHKR(es_addChar(&fieldVal, buf[i]));
		++i;
	}
	*offs = (i == lenBuf) ? i : i+1;
	CHKR(ln_addAnnotOp(annot, opc, fieldName, fieldVal));
	r = 0;
done:	return r;
fail:	return -1;
}


/**
 * Process a new annotation and add it to the annotation set.
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in] offs offset where annotation starts
 * @returns 0 on success, something else otherwise
 */
static int
processAnnotate(ln_ctx ctx, const char *buf, es_size_t lenBuf, es_size_t offs)
{
	int r;
	es_str_t *tag = NULL;
	ln_annot *annot;

	ln_dbgprintf(ctx, "sample annotation to add: '%s'", buf+offs);
	CHKR(getFieldName(ctx, buf, lenBuf, &offs, &tag));
	skipWhitespace(ctx, buf, lenBuf, &offs);
	if(buf[offs] != ':' || tag == NULL) {
		ln_dbgprintf(ctx, "invalid tag field in annotation, line is '%s'", buf);
		r=-1;
		goto done;
	}
	++offs;

	/* we got an annotation! */
	CHKN(annot = ln_newAnnot(tag));

	while(offs < lenBuf) {
		CHKR(getAnnotationOp(ctx, annot, buf, lenBuf, &offs));
	}

	r = ln_addAnnotToSet(ctx->pas, annot);

done:	return r;
}

struct ln_v1_samp *
ln_v1_processSamp(ln_ctx ctx, const char *buf, es_size_t lenBuf)
{
	struct ln_v1_samp *samp = NULL;
	es_str_t *typeStr = NULL;
	es_size_t offs;

	if(getLineType(buf, lenBuf, &offs, &typeStr) != 0)
		goto done;

	if(!es_strconstcmp(typeStr, "prefix")) {
		if(getPrefix(buf, lenBuf, offs, &ctx->rulePrefix) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "extendprefix")) {
		if(extendPrefix(ctx, buf, lenBuf, offs) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "rule")) {
		if(processRule(ctx, buf, lenBuf, offs) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "annotate")) {
		if(processAnnotate(ctx, buf, lenBuf, offs) != 0) goto done;
	} else {
		/* TODO error reporting */
		char *str;
		str = es_str2cstr(typeStr, NULL);
		ln_dbgprintf(ctx, "invalid record type detected: '%s'", str);
		free(str);
		goto done;
	}

done:
	if(typeStr != NULL)
		es_deleteStr(typeStr);

	return samp;
}


struct ln_v1_samp *
ln_v1_sampRead(ln_ctx ctx, FILE *const __restrict__ repo, int *const __restrict__ isEof)
{
	struct ln_v1_samp *samp = NULL;
	char buf[10*1024]; /**< max size of rule - TODO: make configurable */

	size_t i = 0;
	int inParser = 0;
	int done = 0;
	while(!done) {
		int c = fgetc(repo);
		if(c == EOF) {
			*isEof = 1;
			if(i == 0)
				goto done;
			else
				done = 1; /* last line missing LF, still process it! */
		} else if(c == '\n') {
			++ctx->conf_ln_nbr;
			if(inParser) {
				if(ln_sampChkRunawayRule(ctx, repo, NULL)) {
					/* ignore previous rule */
					inParser = 0;
					i = 0;
				}
			}
			if(!inParser && i != 0)
				done = 1;
		} else if(c == '#' && i == 0) {
			ln_sampSkipCommentLine(ctx, repo, NULL);
			i = 0; /* back to beginning */
		} else {
			if(c == '%')
				inParser = (inParser) ? 0 : 1;
			buf[i++] = c;
			if(i >= sizeof(buf)) {
				ln_errprintf(ctx, 0, "line is too long");
				goto done;
			}
		}
	}
	buf[i] = '\0';

	ln_dbgprintf(ctx, "read rulebase line[~%d]: '%s'", ctx->conf_ln_nbr, buf);
	ln_v1_processSamp(ctx, buf, i);

ln_dbgprintf(ctx, "---------------------------------------");
ln_displayPTree(ctx->ptree, 0);
ln_dbgprintf(ctx, "=======================================");
done:
	return samp;
}
