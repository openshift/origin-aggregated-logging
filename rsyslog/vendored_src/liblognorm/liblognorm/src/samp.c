/* samp.c -- code for ln_samp objects.
 * This code handles rulebase processing. Rulebases have been called
 * "sample bases" in the early days of liblognorm, thus the name.
 *
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
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <errno.h>

#include "liblognorm.h"
#include "lognorm.h"
#include "samp.h"
#include "internal.h"
#include "parser.h"
#include "pdag.h"
#include "v1_liblognorm.h"
#include "v1_ptree.h"

void
ln_sampFree(ln_ctx __attribute__((unused)) ctx, struct ln_samp *samp)
{
	free(samp);
}

static int
ln_parseLegacyFieldDescr(ln_ctx ctx,
	const char *const buf,
	const size_t lenBuf,
	size_t *bufOffs,
	es_str_t **str,
	json_object **prscnf)
{
	int r = 0;
	char *cstr;	/* for debug mode strings */
	char *ftype = NULL;
	char name[MAX_FIELDNAME_LEN];
	size_t iDst;
	struct json_object *json = NULL;
	char *ed = NULL;
	es_size_t i = *bufOffs;
	es_str_t *edata = NULL;

	for(  iDst = 0
	    ; iDst < (MAX_FIELDNAME_LEN - 1) && i < lenBuf && buf[i] != ':'
	    ; ++iDst) {
		name[iDst] = buf[i++];
	}
	name[iDst] = '\0';
	if(iDst == (MAX_FIELDNAME_LEN - 1)) {
		ln_errprintf(ctx, 0, "field name too long in: %s", buf+(*bufOffs));
		FAIL(LN_INVLDFDESCR);
	}
	if(i == lenBuf) {
		ln_errprintf(ctx, 0, "field definition wrong in: %s", buf+(*bufOffs));
		FAIL(LN_INVLDFDESCR);
	}

	if(iDst == 0) {
		FAIL(LN_INVLDFDESCR);
	}

	if(ctx->debug) {
		ln_dbgprintf(ctx, "parsed field: '%s'", name);
	}

	if(buf[i] != ':') {
		ln_errprintf(ctx, 0, "missing colon in: %s", buf+(*bufOffs));
		FAIL(LN_INVLDFDESCR);
	}
	++i; /* skip ':' */

	/* parse and process type (trailing whitespace must be trimmed) */
	es_emptyStr(*str);
	size_t j = i;
	/* scan for terminator */
	while(j < lenBuf && buf[j] != ':' && buf[j] != '{' && buf[j] != '%')
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
		ln_errprintf(ctx, 0, "premature end (missing %%?) in: %s", buf+(*bufOffs));
		FAIL(LN_INVLDFDESCR);
	}

	ftype = es_str2cstr(*str, NULL);
	ln_dbgprintf(ctx, "field type '%s', i %d", ftype, i);

	if(buf[i] == '{') {
		struct json_tokener *tokener = json_tokener_new();
		json = json_tokener_parse_ex(tokener, buf+i, (int) (lenBuf - i));
		if(json == NULL) {
			ln_errprintf(ctx, 0, "invalid json in '%s'", buf+i);
		}
		i += tokener->char_offset;
		json_tokener_free(tokener);
	}

	if(buf[i] == '%') {
		i++;
	} else {
		/* parse extra data */
		CHKN(edata = es_newStr(8));
		i++;
		while(i < lenBuf) {
			if(buf[i] == '%') {
				++i;
				break; /* end of field */
			}
			CHKR(es_addChar(&edata, buf[i++]));
		}
		es_unescapeStr(edata);
		if(ctx->debug) {
			cstr = es_str2cstr(edata, NULL);
			ln_dbgprintf(ctx, "parsed extra data: '%s'", cstr);
			free(cstr);
		}
	}

	struct json_object *val;
	*prscnf = json_object_new_object();
	CHKN(val = json_object_new_string(name));
	json_object_object_add(*prscnf, "name", val);
	CHKN(val = json_object_new_string(ftype));
	json_object_object_add(*prscnf, "type", val);
	if(edata != NULL) {
		ed = es_str2cstr(edata, " ");
		CHKN(val = json_object_new_string(ed));
		json_object_object_add(*prscnf, "extradata", val);
	}
	if(json != NULL) {
		/* now we need to merge the json params into the main object */
		struct json_object_iterator it = json_object_iter_begin(json);
		struct json_object_iterator itEnd = json_object_iter_end(json);
		while (!json_object_iter_equal(&it, &itEnd)) {
			struct json_object *const v = json_object_iter_peek_value(&it);
			json_object_get(v);
			json_object_object_add(*prscnf, json_object_iter_peek_name(&it), v);
			json_object_iter_next(&it);
		}
	}

	*bufOffs = i;
done:
	free(ed);
	if(edata != NULL)
		es_deleteStr(edata);
	free(ftype);
	if(json != NULL)
		json_object_put(json);
	return r;
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
addFieldDescr(ln_ctx ctx, struct ln_pdag **pdag, es_str_t *rule,
	        size_t *bufOffs, es_str_t **str)
{
	int r = 0;
	es_size_t i = *bufOffs;
	char *ftype = NULL;
	const char *buf;
	es_size_t lenBuf;
	struct json_object *prs_config = NULL;

	buf = (const char*)es_getBufAddr(rule);
	lenBuf = es_strlen(rule);
	assert(buf[i] == '%');
	++i;	/* "eat" ':' */

	/* skip leading whitespace in field name */
	while(i < lenBuf && isspace(buf[i]))
		++i;
	/* check if we have new-style json config */
	if(buf[i] == '{' || buf[i] == '[') {
		struct json_tokener *tokener = json_tokener_new();
		prs_config = json_tokener_parse_ex(tokener, buf+i, (int) (lenBuf - i));
		i += tokener->char_offset;
		json_tokener_free(tokener);
		if(prs_config == NULL || i == lenBuf || buf[i] != '%') {
			ln_errprintf(ctx, 0, "invalid json in '%s'", buf+i);
			r = -1;
			goto done;
		}
		*bufOffs = i+1; /* eat '%' - if above ensures it is present */
	} else {
		*bufOffs = i;
		CHKR(ln_parseLegacyFieldDescr(ctx, buf, lenBuf, bufOffs, str, &prs_config));
	}

	CHKR(ln_pdagAddParser(ctx, pdag, prs_config));

done:
	free(ftype);
	return r;
}


/**
 *  Construct a literal parser json definition.
 */
static json_object *
newLiteralParserJSONConf(char lit)
{
	char buf[] = "x";
	buf[0] = lit;
	struct json_object *val;
	struct json_object *prscnf = json_object_new_object();

	val = json_object_new_string("literal");
	json_object_object_add(prscnf, "type", val);

	val = json_object_new_string(buf);
	json_object_object_add(prscnf, "text", val);

	return prscnf;
}

/**
 * Parse a Literal string out of the template and add it to the tree.
 * This function is used to create the unoptimized tree. So we do
 * one node for each character. These will be compacted by the optimizer
 * in a later stage. The advantage is that we do not need to care about
 * splitting the tree. As such the processing is fairly simple:
 *
 *   for each character in literal (left-to-right):
 *      create literal parser object o
 *      add new DAG node o, advance to it
 *
 * @param[in] ctx the context
 * @param[in/out] subtree on entry, current subtree, on exist newest
 *    		deepest subtree
 * @param[in] rule string with current rule
 * @param[in/out] bufOffs parse pointer, up to which offset is parsed
 * 		(is updated so that it points to first char after consumed
 * 		string on exit).
 * @param    str a work buffer, provided to prevent creation of a new object
 * @return 0 on success, something else otherwise
 */
static int
parseLiteral(ln_ctx ctx, struct ln_pdag **pdag, es_str_t *rule,
	     size_t *const __restrict__ bufOffs, es_str_t **str)
{
	int r = 0;
	size_t i = *bufOffs;
	unsigned char *buf = es_getBufAddr(rule);
	const size_t lenBuf = es_strlen(rule);
	const char *cstr = NULL;

	es_emptyStr(*str);
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
	cstr = es_str2cstr(*str, NULL);
	if(ctx->debug) {
		ln_dbgprintf(ctx, "parsed literal: '%s'", cstr);
	}

	*bufOffs = i;

	/* we now add the string to the tree */
	for(i = 0 ; cstr[i] != '\0' ; ++i) {
		struct json_object *const prscnf =
			newLiteralParserJSONConf(cstr[i]);
		CHKN(prscnf);
		CHKR(ln_pdagAddParser(ctx, pdag, prscnf));
	}

	r = 0;

done:
	free((void*)cstr);
	return r;
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
 * @returns the new dag root (or NULL in case of error)
 */
static int
addSampToTree(ln_ctx ctx,
	es_str_t *rule,
	ln_pdag *dag,
	struct json_object *tagBucket)
{
	int r = -1;
	es_str_t *str = NULL;
	size_t i;

	CHKN(str = es_newStr(256));
	i = 0;
	while(i < es_strlen(rule)) {
		LN_DBGPRINTF(ctx, "addSampToTree %zu of %d", i, es_strlen(rule));
		CHKR(parseLiteral(ctx, &dag, rule, &i, &str));
		/* After the literal there can be field only*/
		if (i < es_strlen(rule)) {
			CHKR(addFieldDescr(ctx, &dag, rule, &i, &str));
			if (i == es_strlen(rule)) {
				/* finish the tree with empty literal to avoid false merging*/
				CHKR(parseLiteral(ctx, &dag, rule, &i, &str));
			}
		}
	}

	LN_DBGPRINTF(ctx, "end addSampToTree %zu of %d", i, es_strlen(rule));
	/* we are at the end of rule processing, so this node is a terminal */
	dag->flags.isTerminal = 1;
	dag->tags = tagBucket;
	dag->rb_file = strdup(ctx->conf_file);
	dag->rb_lineno = ctx->conf_ln_nbr;

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
getLineType(const char *buf, es_size_t lenBuf, size_t *offs, es_str_t **str)
{
	int r = -1;
	size_t i;

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
 * Process a new rule and add it to pdag.
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

	ln_dbgprintf(ctx, "rule line to add: '%s'", buf+offs);
	CHKR(processTags(ctx, buf, lenBuf, &offs, &tagBucket));

	if(offs == lenBuf) {
		ln_errprintf(ctx, 0, "error: actual message sample part is missing");
		goto done;
	}
	if(ctx->rulePrefix == NULL) {
		CHKN(str = es_newStr(lenBuf));
	} else {
		CHKN(str = es_strdup(ctx->rulePrefix));
	}
	CHKR(es_addBuf(&str, (char*)buf + offs, lenBuf - offs));
	addSampToTree(ctx, str, ctx->pdag, tagBucket);
	es_deleteStr(str);
	r = 0;
done:	return r;
}


static int
getTypeName(ln_ctx ctx,
	const char *const __restrict__ buf,
	const size_t lenBuf,
	size_t *const __restrict__ offs,
	char *const __restrict__ dstbuf)
{
	int r = -1;
	size_t iDst;
	size_t i = *offs;
	
	if(buf[i] != '@') {
		ln_errprintf(ctx, 0, "user-defined type name must "
			"start with '@'");
		goto done;
	}
	for(  iDst = 0
	    ; i < lenBuf && buf[i] != ':' && iDst < MAX_TYPENAME_LEN - 1
	    ; ++i, ++iDst) {
		if(isspace(buf[i])) {
			ln_errprintf(ctx, 0, "user-defined type name must "
				"not contain whitespace");
			goto done;
		}
		dstbuf[iDst] = buf[i];
	}
	dstbuf[iDst] = '\0';

	if(i < lenBuf && buf[i] == ':') {
		r = 0,
		*offs = i+1; /* skip ":" */
	}
done:
	return r;
}

/**
 * Process a type definition and add it to the PDAG
 * disconnected components.
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer
 * @param[in] len length of buffer
 * @param[in] offs offset where rule starts
 * @returns 0 on success, something else otherwise
 */
static int
processType(ln_ctx ctx,
	const char *const __restrict__ buf,
	const size_t lenBuf,
	size_t offs)
{
	int r = -1;
	es_str_t *str;
	char typename[MAX_TYPENAME_LEN];

	ln_dbgprintf(ctx, "type line to add: '%s'", buf+offs);
	CHKR(getTypeName(ctx, buf, lenBuf, &offs, typename));
	ln_dbgprintf(ctx, "type name is '%s'", typename);

	ln_dbgprintf(ctx, "type line to add: '%s'", buf+offs);
	if(offs == lenBuf) {
		ln_errprintf(ctx, 0, "error: actual message sample part is missing in type def");
		goto done;
	}
	// TODO: optimize
	CHKN(str = es_newStr(lenBuf));
	CHKR(es_addBuf(&str, (char*)buf + offs, lenBuf - offs));
	struct ln_type_pdag *const td = ln_pdagFindType(ctx, typename, 1);
	CHKN(td);
	addSampToTree(ctx, str, td->pdag, NULL);
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

	switch(buf[i]) {
	case '+':
		opc = ln_annot_ADD;
		break;
	case '#':
		ln_dbgprintf(ctx, "inline comment in 'annotate' line: %s", buf);
		*offs = lenBuf;
		r = 0;
		goto done;
	case '-':
		ln_dbgprintf(ctx, "annotate op '-' not yet implemented - failing");
		/*FALLTHROUGH*/
	default:ln_errprintf(ctx, 0, "invalid annotate operation '%c': %s", buf[i], buf+i);
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

/**
 * Process include directive. This permits to add unlimited layers
 * of include files.
 *
 * @param[in] ctx current context
 * @param[in] buf line buffer, a C-string
 * @param[in] offs offset where annotation starts
 * @returns 0 on success, something else otherwise
 */
static int
processInclude(ln_ctx ctx, const char *buf, const size_t offs)
{
	int r;
	const char *const conf_file_save = ctx->conf_file;
	char *const fname = strdup(buf+offs);
	size_t lenfname = strlen(fname);
	const unsigned conf_ln_nbr_save = ctx->conf_ln_nbr;

	/* trim string - not optimized but also no need to */
	for(size_t i = lenfname - 1 ; i > 0 ; --i) {
		if(isspace(fname[i])) {
			fname[i] = '\0';
			--lenfname;
		}
	}

	CHKR(ln_loadSamples(ctx, fname));

done:
	free(fname);
	ctx->conf_file = conf_file_save;
	ctx->conf_ln_nbr = conf_ln_nbr_save;

	return r;
}

/**
 * Reads a rule (sample) stored in buffer buf and creates a new ln_samp object
 * out of it, which it adds to the pdag (if required).
 *
 * @param[ctx] ctx current library context
 * @param[buf] cstr buffer containing the string contents of the sample
 * @param[lenBuf] length of the sample contained within buf
 * @return standard error code
 */
static int
ln_processSamp(ln_ctx ctx, const char *buf, const size_t lenBuf)
{
	int r = 0;
	es_str_t *typeStr = NULL;
	size_t offs;

	if(getLineType(buf, lenBuf, &offs, &typeStr) != 0)
		goto done;

	if(!es_strconstcmp(typeStr, "prefix")) {
		if(getPrefix(buf, lenBuf, offs, &ctx->rulePrefix) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "extendprefix")) {
		if(extendPrefix(ctx, buf, lenBuf, offs) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "rule")) {
		if(processRule(ctx, buf, lenBuf, offs) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "type")) {
		if(processType(ctx, buf, lenBuf, offs) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "annotate")) {
		if(processAnnotate(ctx, buf, lenBuf, offs) != 0) goto done;
	} else if(!es_strconstcmp(typeStr, "include")) {
		CHKR(processInclude(ctx, buf, offs));
	} else {
		char *str;
		str = es_str2cstr(typeStr, NULL);
		ln_errprintf(ctx, 0, "invalid record type detected: '%s'", str);
		free(str);
		goto done;
	}

done:
	if(typeStr != NULL)
		es_deleteStr(typeStr);
	return r;
}


/**
 * Read a character from our sample source.
 */
static int
ln_sampReadChar(const ln_ctx ctx, FILE *const __restrict__ repo, const char **inpbuf)
{
	int c;
	assert((repo != NULL && inpbuf == NULL) || (repo == NULL && inpbuf != NULL));
	if(repo == NULL) {
		c = (**inpbuf == '\0') ? EOF : *(*inpbuf)++;
	} else {
		c = fgetc(repo);
	}
	return c;
}

/* note: comments are only supported at beginning of line! */
/* skip to end of line */
void
ln_sampSkipCommentLine(ln_ctx ctx, FILE * const __restrict__ repo, const char **inpbuf)
{
	int c;
	do {
		c = ln_sampReadChar(ctx, repo, inpbuf);
	} while(c != EOF && c != '\n');
	++ctx->conf_ln_nbr;
}


/* this checks if in a multi-line rule, the next line seems to be a new
 * rule, which would meand we have some unmatched percent signs inside
 * our rule (what we call a "runaway rule"). This can easily happen and
 * is otherwise hard to debug, so let's see if it is the case...
 * @return 1 if this is a runaway rule, 0 if not
 */
int
ln_sampChkRunawayRule(ln_ctx ctx, FILE *const __restrict__ repo, const char **inpbuf)
{
	int r = 1;
	fpos_t fpos;
	char buf[6];
	int cont = 1;
	int read;

	fgetpos(repo, &fpos);
	while(cont) {
		fpos_t inner_fpos;
		fgetpos(repo, &inner_fpos);
		if((read = fread(buf, sizeof(char), sizeof(buf)-1, repo)) == 0) {
			r = 0;
			goto done;
		}
		if(buf[0] == '\n') {
			fsetpos(repo, &inner_fpos);
			if(fread(buf, sizeof(char), 1, repo)) {}; /* skip '\n' */
			continue;
		} else if(buf[0] == '#') {
			fsetpos(repo, &inner_fpos);
			const unsigned conf_ln_nbr_save = ctx->conf_ln_nbr;
			ln_sampSkipCommentLine(ctx, repo, inpbuf);
			ctx->conf_ln_nbr = conf_ln_nbr_save;
			continue;
		}
		if(read != 5)
			goto done; /* cannot be a rule= line! */
		cont = 0; /* no comment, so we can decide */
		buf[5] = '\0';
		if(!strncmp(buf, "rule=", 5)) {
			ln_errprintf(ctx, 0, "line has 'rule=' at begin of line, which "
				"does look like a typo in the previous lines (unmatched "
				"%% character) and is forbidden. If valid, please re-format "
				"the rule to start with other characters. Rule ignored.");
			goto done;
		}
	}

	r = 0;
done:
	fsetpos(repo, &fpos);
	return r;
}

/**
 * Read a rule (sample) from repository (sequentially).
 *
 * Reads a sample starting with the current file position and
 * creates a new ln_samp object out of it, which it adds to the
 * pdag.
 *
 * @param[in] ctx current library context
 * @param[in] repo repository descriptor if file input is desired
 * @param[in/out] ptr to ptr of input buffer; this is used if a string is
 *                provided instead of a file. If so, this pointer is advanced
 *                as data is consumed.
 * @param[out] isEof must be set to 0 on entry and is switched to 1 if EOF occured.
 * @return standard error code
 */
static int
ln_sampRead(ln_ctx ctx, FILE *const __restrict__ repo, const char **inpbuf,
	int *const __restrict__ isEof)
{
	int r = 0;
	char buf[64*1024]; /**< max size of rule - TODO: make configurable */

	size_t i = 0;
	int inParser = 0;
	int done = 0;
	while(!done) {
		const int c = ln_sampReadChar(ctx, repo, inpbuf);
		if(c == EOF) {
			*isEof = 1;
			if(i == 0)
				goto done;
			else
				done = 1; /* last line missing LF, still process it! */
		} else if(c == '\n') {
			++ctx->conf_ln_nbr;
			if(inParser) {
				if(ln_sampChkRunawayRule(ctx, repo, inpbuf)) {
					/* ignore previous rule */
					inParser = 0;
					i = 0;
				}
			}
			if(!inParser && i != 0)
				done = 1;
		} else if(c == '#' && i == 0) {
			ln_sampSkipCommentLine(ctx, repo, inpbuf);
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
	CHKR(ln_processSamp(ctx, buf, i));

done:
	return r;
}

/* check rulebase format version. Returns 2 if this is v2 rulebase,
 * 1 for any pre-v2 and -1 if there was a problem reading the file.
 */
static int
checkVersion(FILE *const fp)
{
	char buf[64];

	if(fgets(buf, sizeof(buf), fp) == NULL)
		return -1;
	if(!strcmp(buf, "version=2\n")) {
		return 2;
	} else {
		return 1;
	}
}

/* we have a v1 rulebase, so let's do all stuff that we need
 * to make that ole piece of ... work.
 */
static int
doOldCruft(ln_ctx ctx, const char *file)
{
	int r = -1;
	if((ctx->ptree = ln_newPTree(ctx, NULL)) == NULL) {
		free(ctx);
		r = -1;
		goto done;
	}
	r = ln_v1_loadSamples(ctx, file);
done:
	return r;
}

/* try to open a rulebase file. This also tries to see if we need to
 * load it from some pre-configured alternative location.
 * @returns open file pointer or NULL in case of error
 */
static FILE *
tryOpenRBFile(ln_ctx ctx, const char *const file)
{
	FILE *repo = NULL;

	if((repo = fopen(file, "r")) != NULL)
		goto done;
	const int eno1 = errno;

	const char *const rb_lib = getenv("LIBLOGNORM_RULEBASES");
	if(rb_lib == NULL || *file == '/') {
		ln_errprintf(ctx, eno1, "cannot open rulebase '%s'", file);
		goto done;
	}

	char *fname = NULL;
	int len;
	len = asprintf(&fname, (rb_lib[strlen(rb_lib)-1] == '/') ? "%s%s" : "%s/%s", rb_lib, file);
	if(len == -1) {
		ln_errprintf(ctx, errno, "alloc error: cannot open rulebase '%s'", file);
		goto done;
	}
	if((repo = fopen(fname, "r")) == NULL) {
		const int eno2 = errno;
		ln_errprintf(ctx, eno1, "cannot open rulebase '%s'", file);
		ln_errprintf(ctx, eno2, "also tried to locate %s via "
			"rulebase directory without success. Expanded "
			"name was '%s'", file, fname);
	}
	free(fname);

done:
	return repo;
}

/* @return 0 if all is ok, 1 if an error occured */
int
ln_sampLoad(ln_ctx ctx, const char *file)
{
	int r = 1;
	FILE *repo;
	int isEof = 0;

	ln_dbgprintf(ctx, "loading rulebase file '%s'", file);
	if(file == NULL) goto done;
	if((repo = tryOpenRBFile(ctx, file)) == NULL)
		goto done;
	const int version = checkVersion(repo);
	ln_dbgprintf(ctx, "rulebase version is %d\n", version);
	if(version == -1) {
		ln_errprintf(ctx, errno, "error determing version of %s", file);
		goto done;
	}
	if(ctx->version != 0 && version != ctx->version) {
		ln_errprintf(ctx, errno, "rulebase '%s' must be version %d, but is version %d "
			" - can not be processed", file, ctx->version, version);
		goto done;
	}
	ctx->version = version;
	if(ctx->version == 1) {
		fclose(repo);
		r = doOldCruft(ctx, file);
		goto done;
	}

	/* now we are in our native code */
	++ctx->conf_ln_nbr; /* "version=2" is line 1! */
	while(!isEof) {
		CHKR(ln_sampRead(ctx, repo, NULL, &isEof));
	}
	fclose(repo);
	r = 0;

	if(ctx->include_level == 1)
		ln_pdagOptimize(ctx);
done:
	return r;
}

/* @return 0 if all is ok, 1 if an error occured */
int
ln_sampLoadFromString(ln_ctx ctx, const char *string)
{
	int r = 1;
	int isEof = 0;

	if(string == NULL)
		goto done;

	ln_dbgprintf(ctx, "loading v2 rulebase from string '%s'", string);
	ctx->version = 2;
	while(!isEof) {
		CHKR(ln_sampRead(ctx, NULL, &string, &isEof));
	}
	r = 0;

	if(ctx->include_level == 1)
		ln_pdagOptimize(ctx);
done:
	return r;
}
