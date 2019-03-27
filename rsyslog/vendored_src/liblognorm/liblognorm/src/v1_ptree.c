/**
 * @file ptree.c
 * @brief Implementation of the parse tree object.
 * @class ln_ptree ptree.h
 *//*
 * Copyright 2010 by Rainer Gerhards and Adiscon GmbH.
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
#include <libestr.h>

#define LOGNORM_V1_SUBSYSTEM /* indicate we are old cruft */
#include "v1_liblognorm.h"
#include "annot.h"
#include "internal.h"
#include "lognorm.h"
#include "v1_ptree.h"
#include "v1_samp.h"
#include "v1_parser.h"

/**
 * Get base addr of common prefix. Takes length of prefix in account
 * and selects the right buffer.
 */
static inline unsigned char*
prefixBase(struct ln_ptree *tree)
{
	return (tree->lenPrefix <= sizeof(tree->prefix))
	       ? tree->prefix.data : tree->prefix.ptr;
}


struct ln_ptree*
ln_newPTree(ln_ctx ctx, struct ln_ptree **parentptr)
{
	struct ln_ptree *tree;

	if((tree = calloc(1, sizeof(struct ln_ptree))) == NULL)
		goto done;
	
	tree->parentptr = parentptr;
	tree->ctx = ctx;
	ctx->nNodes++;
done:	return tree;
}

void
ln_deletePTreeNode(ln_fieldList_t *node)
{
	ln_deletePTree(node->subtree);
	es_deleteStr(node->name);
	if(node->data != NULL)
		es_deleteStr(node->data);
	if(node->raw_data != NULL)
		es_deleteStr(node->raw_data);
	if(node->parser_data != NULL && node->parser_data_destructor != NULL)
		node->parser_data_destructor(&(node->parser_data));
	free(node);
}

void
ln_deletePTree(struct ln_ptree *tree)
{
	ln_fieldList_t *node, *nextnode;
	size_t i;

	if(tree == NULL)
		goto done;

	if(tree->tags != NULL)
		json_object_put(tree->tags);
	for(node = tree->froot; node != NULL; node = nextnode) {
		nextnode = node->next;
		ln_deletePTreeNode(node);
	}

	/* need to free a large prefix buffer? */
	if(tree->lenPrefix > sizeof(tree->prefix))
		free(tree->prefix.ptr);

	for(i = 0 ; i < 256 ; ++i)
		if(tree->subtree[i] != NULL)
			ln_deletePTree(tree->subtree[i]);
	free(tree);

done:	return;
}


/**
 * Set the common prefix inside a note, taking into account the subtle
 * issues associated with it.
 * @return 0 on success, something else otherwise
 */
static int
setPrefix(struct ln_ptree *tree, unsigned char *buf, size_t lenBuf, size_t offs)
{
	int r;
LN_DBGPRINTF(tree->ctx, "setPrefix lenBuf %zu, offs %zu", lenBuf, offs);
	tree->lenPrefix = lenBuf - offs;
	if(tree->lenPrefix > sizeof(tree->prefix)) {
		/* too-large for standard buffer, need to alloc one */
		if((tree->prefix.ptr = malloc(tree->lenPrefix * sizeof(unsigned char))) == NULL) {
			r = LN_NOMEM;
			goto done; /* fail! */
		}
		memcpy(tree->prefix.ptr, buf, tree->lenPrefix);
	} else {
		/* note: r->lenPrefix may be 0, but that is OK */
		memcpy(tree->prefix.data, buf, tree->lenPrefix);
	}
	r = 0;

done:	return r;
}


/**
 * Check if the provided tree is a leaf. This means that it
 * does not contain any subtrees.
 * @return 1 if it is a leaf, 0 otherwise
 */
static int
isLeaf(struct ln_ptree *tree)
{
	int r = 0;
	int i;

	if(tree->froot != NULL)
		goto done;
	
	for(i = 0 ; i < 256 ; ++i) {
		if(tree->subtree[i] != NULL)
			goto done;
	}
	r = 1;

done:	return r;
}


/**
 * Check if the provided tree is a true leaf. This means that it
 * does not contain any subtrees of any kind and no prefix,
 * and it is not terminal leaf.
 * @return 1 if it is a leaf, 0 otherwise
 */
static inline int
isTrueLeaf(struct ln_ptree *tree)
{
	return((tree->lenPrefix == 0) && isLeaf(tree)) && !tree->flags.isTerminal;
}


struct ln_ptree *
ln_addPTree(struct ln_ptree *tree, es_str_t *str, size_t offs)
{
	struct ln_ptree *r;
	struct ln_ptree **parentptr;	 /**< pointer in parent that needs to be updated */

LN_DBGPRINTF(tree->ctx, "addPTree: offs %zu", offs);
	parentptr = &(tree->subtree[es_getBufAddr(str)[offs]]);
	/* First check if tree node is totaly empty. If so, we can simply add
	 * the prefix to this node. This case is important, because it happens
	 * every time with a new field.
	 */
	if(isTrueLeaf(tree)) {
		if(setPrefix(tree, es_getBufAddr(str), es_strlen(str), offs) != 0) {
			r = NULL;
		} else {
			r = tree;
		}
		goto done;
	}

	if(tree->ctx->debug) {
		char *cstr = es_str2cstr(str, NULL);
		LN_DBGPRINTF(tree->ctx, "addPTree: add '%s', offs %zu, tree %p",
			     cstr + offs, offs, tree);
		free(cstr);
	}

	if((r = ln_newPTree(tree->ctx, parentptr)) == NULL)
		goto done;

	if(setPrefix(r, es_getBufAddr(str) + offs + 1, es_strlen(str) - offs - 1, 0) != 0) {
		free(r);
		r = NULL;
		goto done;
	}

	*parentptr = r;

done:	return r;
}


/**
 * Split the provided tree (node) into two at the provided index into its
 * common prefix. This function exists to support splitting nodes when
 * a mismatch in the common prefix requires that. This function more or less
 * keeps the tree as it is, just changes the structure. No new node is added.
 * Usually, it is desired to add a new node. This must be made afterwards.
 * Note that we need to create a new tree *in front of* the current one, as
 * the current one contains field etc. subtree pointers.
 * @param[in] tree tree to split
 * @param[in] offs offset into common prefix (must be less than prefix length!)
 */
static struct ln_ptree*
splitTree(struct ln_ptree *tree, unsigned short offs)
{
	unsigned char *c;
	struct ln_ptree *r;
	unsigned short newlen;
	ln_ptree **newparentptr;	 /**< pointer in parent that needs to be updated */

	assert(offs < tree->lenPrefix);
	if((r = ln_newPTree(tree->ctx, tree->parentptr)) == NULL)
		goto done;

	LN_DBGPRINTF(tree->ctx, "splitTree %p at offs %u", tree, offs);
	/* note: the overall prefix is reduced by one char, which is now taken
	 * care of inside the "branch table".
	 */
	c = prefixBase(tree);
//LN_DBGPRINTF(tree->ctx, "splitTree new bb, *(c+offs): '%s'", c);
	if(setPrefix(r, c, offs, 0) != 0) {
		ln_deletePTree(r);
		r = NULL;
		goto done; /* fail! */
	}

LN_DBGPRINTF(tree->ctx, "splitTree new tree %p lenPrefix=%u, char '%c'", r, r->lenPrefix, r->prefix.data[0]);
	/* add the proper branch table entry for the new node. must be done
	 * here, because the next step will destroy the required index char!
	 */
	newparentptr = &(r->subtree[c[offs]]);
	r->subtree[c[offs]] = tree;

	/* finally fix existing common prefix */
	newlen = tree->lenPrefix - offs - 1;
	if(tree->lenPrefix > sizeof(tree->prefix) && (newlen <= sizeof(tree->prefix))) {
		/* note: c is a different pointer; the original
		 * pointer is overwritten by memcpy! */
LN_DBGPRINTF(tree->ctx, "splitTree new case one bb, offs %u, lenPrefix %u, newlen %u", offs, tree->lenPrefix, newlen);
//LN_DBGPRINTF(tree->ctx, "splitTree new case one bb, *(c+offs): '%s'", c);
		memcpy(tree->prefix.data, c+offs+1, newlen);
		free(c);
	} else {
LN_DBGPRINTF(tree->ctx, "splitTree new case two bb, offs=%u, newlen %u", offs, newlen);
		memmove(c, c+offs+1, newlen);
	}
	tree->lenPrefix = tree->lenPrefix - offs - 1;

	if(tree->parentptr == 0)
		tree->ctx->ptree = r;	/* root does not have a parent! */
	else
		*(tree->parentptr) = r;
	tree->parentptr = newparentptr;

done:	return r;
}


struct ln_ptree *
ln_buildPTree(struct ln_ptree *tree, es_str_t *str, size_t offs)
{
	struct ln_ptree *r;
	unsigned char *c;
	unsigned char *cpfix;
	size_t i;
	unsigned short ipfix;

	assert(tree != NULL);
	LN_DBGPRINTF(tree->ctx, "buildPTree: begin at %p, offs %zu", tree, offs);
	c = es_getBufAddr(str);

	/* check if the prefix matches and, if not, at what offset it is different */
	ipfix = 0;
	cpfix = prefixBase(tree);
	for(  i = offs
	    ; (i < es_strlen(str)) && (ipfix < tree->lenPrefix) && (c[i] == cpfix[ipfix])
	    ; ++i, ++ipfix) {
	    	; /*DO NOTHING - just find end of match */
		LN_DBGPRINTF(tree->ctx, "buildPTree: tree %p, i %zu, char '%c'", tree, i, c[i]);
	}

	/* if we reach this point, we have processed as much of the common prefix
	 * as we could. The following code now does the proper actions based on
	 * the possible cases.
	 */
	if(i == es_strlen(str)) {
		/* all of our input is consumed, no more recursion */
		if(ipfix == tree->lenPrefix) {
			LN_DBGPRINTF(tree->ctx, "case 1.1");
			/* exact match, we are done! */
			r = tree;
		} else {
			LN_DBGPRINTF(tree->ctx, "case 1.2");
			/* we need to split the node at the current position */
			r = splitTree(tree, ipfix);
		}
	} else if(ipfix < tree->lenPrefix) {
			LN_DBGPRINTF(tree->ctx, "case 2, i=%zu, ipfix=%u", i, ipfix);
			/* we need to split the node at the current position */
			if((r = splitTree(tree, ipfix)) == NULL)
				goto done; /* fail */
LN_DBGPRINTF(tree->ctx, "pre addPTree: i %zu", i);
			if((r = ln_addPTree(r, str, i)) == NULL)
				goto done;
			//r = ln_buildPTree(r, str, i + 1);
	} else {
		/* we could consume the current common prefix, but now need
		 * to traverse the rest of the tree based on the next char.
		 */
		if(tree->subtree[c[i]] == NULL) {
			LN_DBGPRINTF(tree->ctx, "case 3.1");
			/* non-match, need new subtree */
			r = ln_addPTree(tree, str, i);
		} else {
			LN_DBGPRINTF(tree->ctx, "case 3.2");
			/* match, follow subtree */
			r = ln_buildPTree(tree->subtree[c[i]], str, i + 1);
		}
	}

//LN_DBGPRINTF(tree->ctx, "---------------------------------------");
//ln_displayPTree(tree, 0);
//LN_DBGPRINTF(tree->ctx, "=======================================");
done:	return r;
}


int
ln_addFDescrToPTree(struct ln_ptree **tree, ln_fieldList_t *node)
{
	int r;
	ln_fieldList_t *curr;

	assert(tree != NULL);assert(*tree != NULL);
	assert(node != NULL);

	if((node->subtree = ln_newPTree((*tree)->ctx, &node->subtree)) == NULL) {
		r = -1;
		goto done;
	}
	LN_DBGPRINTF((*tree)->ctx, "got new subtree %p", node->subtree);

	/* check if we already have this field, if so, merge
	 * TODO: optimized, check logic
	 */
	for(curr = (*tree)->froot ; curr != NULL ; curr = curr->next) {
		if(!es_strcmp(curr->name, node->name)
				&& curr->parser == node->parser
				&& ((curr->raw_data == NULL && node->raw_data == NULL)
					|| (curr->raw_data != NULL && node->raw_data != NULL
						&& !es_strcmp(curr->raw_data, node->raw_data)))) {
			*tree = curr->subtree;
			ln_deletePTreeNode(node);
			r = 0;
			LN_DBGPRINTF((*tree)->ctx, "merging with tree %p\n", *tree);
			goto done;
		}
	}

	if((*tree)->froot == NULL) {
		(*tree)->froot = (*tree)->ftail = node;
	} else {
		(*tree)->ftail->next = node;
		(*tree)->ftail = node;
	}
	r = 0;
	LN_DBGPRINTF((*tree)->ctx, "prev subtree %p", *tree);
	*tree = node->subtree;
	LN_DBGPRINTF((*tree)->ctx, "new subtree %p", *tree);

done:	return r;
}


void
ln_displayPTree(struct ln_ptree *tree, int level)
{
	int i;
	int nChildLit;
	int nChildField;
	es_str_t *str;
	char *cstr;
	ln_fieldList_t *node;
	char indent[2048];

	if(level > 1023)
		level = 1023;
	memset(indent, ' ', level * 2);
	indent[level * 2] = '\0';

	nChildField = 0;
	for(node = tree->froot ; node != NULL ; node = node->next ) {
		++nChildField;
	}

	nChildLit = 0;
	for(i = 0 ; i < 256 ; ++i) {
		if(tree->subtree[i] != NULL) {
			nChildLit++;
		}
	}

	str = es_newStr(sizeof(tree->prefix));
	es_addBuf(&str, (char*) prefixBase(tree), tree->lenPrefix);
	cstr = es_str2cstr(str, NULL);
	es_deleteStr(str);
	LN_DBGPRINTF(tree->ctx, "%ssubtree%s %p (prefix: '%s', children: %d literals, %d fields) [visited %u "
	"backtracked %u terminated %u]",
			indent, tree->flags.isTerminal ? " TERM" : "", tree, cstr, nChildLit, nChildField,
			tree->stats.visited, tree->stats.backtracked, tree->stats.terminated);
	free(cstr);
	/* display char subtrees */
	for(i = 0 ; i < 256 ; ++i) {
		if(tree->subtree[i] != NULL) {
			LN_DBGPRINTF(tree->ctx, "%schar %2.2x(%c):", indent, i, i);
			ln_displayPTree(tree->subtree[i], level + 1);
		}
	}

	/* display field subtrees */
	for(node = tree->froot ; node != NULL ; node = node->next ) {
		cstr = es_str2cstr(node->name, NULL);
		LN_DBGPRINTF(tree->ctx, "%sfield %s:", indent, cstr);
		free(cstr);
		ln_displayPTree(node->subtree, level + 1);
	}
}


/* the following is a quick hack, which should be moved to the
 * string class.
 */
static inline void dotAddPtr(es_str_t **str, void *p)
{
	char buf[64];
	int i;
	i = snprintf(buf, sizeof(buf), "%p", p);
	es_addBuf(str, buf, i);
}
/**
 * recursive handler for DOT graph generator.
 */
static void
ln_genDotPTreeGraphRec(struct ln_ptree *tree, es_str_t **str)
{
	int i;
	ln_fieldList_t *node;


	dotAddPtr(str, tree);
	es_addBufConstcstr(str, " [label=\"");
	if(tree->lenPrefix > 0) {
		es_addChar(str, '\'');
		es_addBuf(str, (char*) prefixBase(tree), tree->lenPrefix);
		es_addChar(str, '\'');
	}
	es_addBufConstcstr(str, "\"");
	if(isLeaf(tree)) {
		es_addBufConstcstr(str, " style=\"bold\"");
	}
	es_addBufConstcstr(str, "]\n");

	/* display char subtrees */
	for(i = 0 ; i < 256 ; ++i) {
		if(tree->subtree[i] != NULL) {
			dotAddPtr(str, tree);
			es_addBufConstcstr(str, " -> ");
			dotAddPtr(str, tree->subtree[i]);
			es_addBufConstcstr(str, " [label=\"");
			es_addChar(str, (char) i);
			es_addBufConstcstr(str, "\"]\n");
			ln_genDotPTreeGraphRec(tree->subtree[i], str);
		}
	}

	/* display field subtrees */
	for(node = tree->froot ; node != NULL ; node = node->next ) {
		dotAddPtr(str, tree);
		es_addBufConstcstr(str, " -> ");
		dotAddPtr(str, node->subtree);
		es_addBufConstcstr(str, " [label=\"");
		es_addStr(str, node->name);
		es_addBufConstcstr(str, "\" style=\"dotted\"]\n");
		ln_genDotPTreeGraphRec(node->subtree, str);
	}
}


void
ln_genDotPTreeGraph(struct ln_ptree *tree, es_str_t **str)
{
	es_addBufConstcstr(str, "digraph ptree {\n");
	ln_genDotPTreeGraphRec(tree, str);
	es_addBufConstcstr(str, "}\n");
}


/**
 * add unparsed string to event.
 */
static int
addUnparsedField(const char *str, size_t strLen, int offs, struct json_object *json)
{
	int r = 1;
	struct json_object *value;
	char *s = NULL;
	CHKN(s = strndup(str, strLen));
	value = json_object_new_string(s);
	if (value == NULL) {
		goto done;
	}
	json_object_object_add(json, ORIGINAL_MSG_KEY, value);
	
	value = json_object_new_string(s + offs);
	if (value == NULL) {
		goto done;
	}
	json_object_object_add(json, UNPARSED_DATA_KEY, value);

	r = 0;
done:
	free(s);
	return r;
}


/**
 * Special parser for iptables-like name/value pairs.
 * The pull multiple fields. Note that once this parser has been selected,
 * it is very unlikely to be left, as it is *very* generic. This parser is
 * required because practice shows that already-structured data like iptables
 * can otherwise not be processed by liblognorm in a meaningful way.
 *
 * @param[in] tree current tree to process
 * @param[in] str string to be matched against (the to-be-normalized data)
 * @param[in] strLen length of str
 * @param[in/out] offs start position in input data, on exit first unparsed position
 * @param[in/out] event handle to event that is being created during normalization
 *
 * @return 0 if parser was successfully, something else on error
 */
static int
ln_iptablesParser(struct ln_ptree *tree, const char *str, size_t strLen, size_t *offs,
		  struct json_object *json)
{
	int r;
	size_t o = *offs;
	es_str_t *fname;
	es_str_t *fval;
	const char *pstr;
	const char *end;
	struct json_object *value;

LN_DBGPRINTF(tree->ctx, "%zu enter iptables parser, len %zu", *offs, strLen);
	if(o == strLen) {
		r = -1; /* can not be, we have no n/v pairs! */
		goto done;
	}
	
	end = str + strLen;
	pstr = str + o;
	while(pstr < end) {
		while(pstr < end && isspace(*pstr))
			++pstr;
		CHKN(fname = es_newStr(16));
		while(pstr < end && !isspace(*pstr) && *pstr != '=') {
			es_addChar(&fname, *pstr);
			++pstr;
		}
		if(pstr < end && *pstr == '=') {
			CHKN(fval = es_newStr(16));
			++pstr;
			/* error on space */
			while(pstr < end && !isspace(*pstr)) {
				es_addChar(&fval, *pstr);
				++pstr;
			}
		} else {
			CHKN(fval = es_newStrFromCStr("[*PRESENT*]",
					sizeof("[*PRESENT*]")-1));
		}
		char *cn, *cv;
		CHKN(cn = ln_es_str2cstr(&fname));
		CHKN(cv = ln_es_str2cstr(&fval));
		if (tree->ctx->debug) {
			LN_DBGPRINTF(tree->ctx, "iptables parser extracts %s=%s", cn, cv);
		}
		CHKN(value = json_object_new_string(cv));
		json_object_object_add(json, cn, value);
		es_deleteStr(fval);
		es_deleteStr(fname);
	}

	r = 0;
	*offs = strLen;

done:
	LN_DBGPRINTF(tree->ctx, "%zu iptables parser returns %d", *offs, r);
	return r;
}


/**
 * Recursive step of the normalizer. It walks the parse tree and calls itself
 * recursively when this is appropriate. It also implements backtracking in
 * those (hopefully rare) cases where it is required.
 *
 * @param[in] tree current tree to process
 * @param[in] string string to be matched against (the to-be-normalized data)
 * @param[in] strLen length of the to-be-matched string
 * @param[in] offs start position in input data
 * @param[in/out] json ... that is being created during normalization
 * @param[out] endNode if a match was found, this is the matching node (undefined otherwise)
 *
 * @return number of characters left unparsed by following the subtree, negative if
 *         the to-be-parsed message is shorter than the rule sample by this number of
 *         characters.
 */
static int
ln_v1_normalizeRec(struct ln_ptree *tree, const char *str, size_t strLen, size_t offs, struct json_object *json,
		struct ln_ptree **endNode)
{
	int r;
	int localR;
	size_t i;
	int left;
	ln_fieldList_t *node;
	ln_fieldList_t *restMotifNode = NULL;
	char *cstr;
	const char *c;
	unsigned char *cpfix;
	unsigned ipfix;
	size_t parsed;
	char *namestr;
	struct json_object *value;
	
	++tree->stats.visited;
	if(offs >= strLen) {
		*endNode = tree;
		r = -tree->lenPrefix;
		goto done;
	}

LN_DBGPRINTF(tree->ctx, "%zu: enter parser, tree %p", offs, tree);
	c = str;
	cpfix = prefixBase(tree);
	node = tree->froot;
	r = strLen - offs;
	/* first we need to check if the common prefix matches (and consume input data while we do) */
	ipfix = 0;
	while(offs < strLen && ipfix < tree->lenPrefix) {
		LN_DBGPRINTF(tree->ctx, "%zu: prefix compare '%c', '%c'", offs, c[offs], cpfix[ipfix]);
		if(c[offs] != cpfix[ipfix]) {
			r -= ipfix;
			goto done;
		}
		++offs, ++ipfix;
	}
	
	if(ipfix != tree->lenPrefix) {
		/* incomplete prefix match --> to-be-normalized string too short */
		r = ipfix - tree->lenPrefix;
		goto done;
	}

	r -= ipfix;
	LN_DBGPRINTF(tree->ctx, "%zu: prefix compare succeeded, still valid", offs);

	/* now try the parsers */
	while(node != NULL) {
		if(tree->ctx->debug) {
			cstr = es_str2cstr(node->name, NULL);
			LN_DBGPRINTF(tree->ctx, "%zu:trying parser for field '%s': %p",
					offs, cstr, node->parser);
			free(cstr);
		}
		i = offs;
		if(node->isIPTables) {
			localR = ln_iptablesParser(tree, str, strLen, &i, json);
			LN_DBGPRINTF(tree->ctx, "%zu iptables parser return, i=%zu",
						offs, i);
			if(localR == 0) {
				/* potential hit, need to verify */
				LN_DBGPRINTF(tree->ctx, "potential hit, trying subtree");
				left = ln_v1_normalizeRec(node->subtree, str, strLen, i, json, endNode);
				if(left == 0 && (*endNode)->flags.isTerminal) {
					LN_DBGPRINTF(tree->ctx, "%zu: parser matches at %zu", offs, i);
					r = 0;
					goto done;
				}
				LN_DBGPRINTF(tree->ctx, "%zu nonmatch, backtracking required, left=%d",
						offs, left);
				++tree->stats.backtracked;
				if(left < r)
					r = left;
			}
		} else if(node->parser == ln_parseRest) {
			/* This is a quick and dirty adjustment to handle "rest" more intelligently.
			 * It's just a tactical fix: in the longer term, we'll handle the whole
			 * situation differently. However, it makes sense to fix this now, as this
			 * solves some real-world problems immediately. -- rgerhards, 2015-04-15
			 */
			restMotifNode = node;
		} else {
			value = NULL;
			localR = node->parser(str, strLen, &i, node, &parsed, &value);
			LN_DBGPRINTF(tree->ctx, "parser returns %d, parsed %zu", localR, parsed);
			if(localR == 0) {
				/* potential hit, need to verify */
				LN_DBGPRINTF(tree->ctx, "%zu: potential hit, trying subtree %p", offs, node->subtree);
				left = ln_v1_normalizeRec(node->subtree, str, strLen, i + parsed, json, endNode);
				LN_DBGPRINTF(tree->ctx, "%zu: subtree returns %d", offs, r);
				if(left == 0 && (*endNode)->flags.isTerminal) {
					LN_DBGPRINTF(tree->ctx, "%zu: parser matches at %zu", offs, i);
					if(es_strbufcmp(node->name, (unsigned char*)"-", 1)) {
						/* Store the value here; create json if not already created */
						if (value == NULL) {
							CHKN(cstr = strndup(str + i, parsed));
							value = json_object_new_string(cstr);
							free(cstr);
						}
						if (value == NULL) {
							LN_DBGPRINTF(tree->ctx, "unable to create json");
							goto done;
						}
						namestr = ln_es_str2cstr(&node->name);
						json_object_object_add(json, namestr, value);
					} else {
						if (value != NULL) {
							/* Free the unneeded value */
							json_object_put(value);
						}
					}
					r = 0;
					goto done;
				}
				LN_DBGPRINTF(tree->ctx, "%zu nonmatch, backtracking required, left=%d",
						offs, left);
				if (value != NULL) {
					/* Free the value if it was created */
					json_object_put(value);
				}
				if(left > 0 && left < r)
					r = left;
				LN_DBGPRINTF(tree->ctx, "%zu nonmatch, backtracking required, left=%d, r now %d",
						offs, left, r);
				++tree->stats.backtracked;
			}
		}
		node = node->next;
	}

	if(offs == strLen) {
		*endNode = tree;
		r = 0;
		goto done;
	}

if(offs < strLen) {
unsigned char cc = str[offs];
LN_DBGPRINTF(tree->ctx, "%zu no field, trying subtree char '%c': %p", offs, cc, tree->subtree[cc]);
} else {
LN_DBGPRINTF(tree->ctx, "%zu no field, offset already beyond end", offs);
}
	/* now let's see if we have a literal */
	if(tree->subtree[(unsigned char)str[offs]] != NULL) {
		left = ln_v1_normalizeRec(tree->subtree[(unsigned char)str[offs]],
				       str, strLen, offs + 1, json, endNode);
LN_DBGPRINTF(tree->ctx, "%zu got left %d, r %d", offs, left, r);
		if(left < r)
			r = left;
LN_DBGPRINTF(tree->ctx, "%zu got return %d", offs, r);
	}

	if(r == 0 && (*endNode)->flags.isTerminal)
		goto done;

	/* and finally give "rest" a try if it was present. Note that we MUST do this after
	 * literal evaluation, otherwise "rest" can never be overriden by other rules.
	 */
	if(restMotifNode != NULL) {
		LN_DBGPRINTF(tree->ctx, "rule has rest motif, forcing match via it");
		value = NULL;
		restMotifNode->parser(str, strLen, &i, restMotifNode, &parsed, &value);
#		ifndef NDEBUG
		left = /* we only need this for the assert below */
#		endif
		       ln_v1_normalizeRec(restMotifNode->subtree, str, strLen, i + parsed, json, endNode);
		assert(left == 0); /* with rest, we have this invariant */
		assert((*endNode)->flags.isTerminal); /* this one also */
		LN_DBGPRINTF(tree->ctx, "%zu: parser matches at %zu", offs, i);
		if(es_strbufcmp(restMotifNode->name, (unsigned char*)"-", 1)) {
			/* Store the value here; create json if not already created */
			if (value == NULL) {
				CHKN(cstr = strndup(str + i, parsed));
				value = json_object_new_string(cstr);
				free(cstr);
			}
			if (value == NULL) {
				LN_DBGPRINTF(tree->ctx, "unable to create json");
				goto done;
			}
			namestr = ln_es_str2cstr(&restMotifNode->name);
			json_object_object_add(json, namestr, value);
		} else {
			if (value != NULL) {
				/* Free the unneeded value */
				json_object_put(value);
			}
		}
		r = 0;
		goto done;
	}
done:
	LN_DBGPRINTF(tree->ctx, "%zu returns %d", offs, r);
	if(r == 0 && *endNode == tree)
		++tree->stats.terminated;
	return r;
}


int
ln_v1_normalize(ln_ctx ctx, const char *str, size_t strLen, struct json_object **json_p)
{
	int r;
	int left;
	struct ln_ptree *endNode = NULL;

	if(*json_p == NULL) {
		CHKN(*json_p = json_object_new_object());
	}

	left = ln_v1_normalizeRec(ctx->ptree, str, strLen, 0, *json_p, &endNode);

	if(ctx->debug) {
		if(left == 0) {
			LN_DBGPRINTF(ctx, "final result for normalizer: left %d, endNode %p, "
				     "isTerminal %d, tagbucket %p",
				     left, endNode, endNode->flags.isTerminal, endNode->tags);
		} else {
			LN_DBGPRINTF(ctx, "final result for normalizer: left %d, endNode %p",
				     left, endNode);
		}
	}
	if(left != 0 || !endNode->flags.isTerminal) {
		/* we could not successfully parse, some unparsed items left */
		if(left < 0) {
			addUnparsedField(str, strLen, strLen, *json_p);
		} else {
			addUnparsedField(str, strLen, strLen - left, *json_p);
		}
	} else {
		/* success, finalize event */
		if(endNode->tags != NULL) {
			/* add tags to an event */
			json_object_get(endNode->tags);
			json_object_object_add(*json_p, "event.tags", endNode->tags);
			CHKR(ln_annotate(ctx, *json_p, endNode->tags));
		}
	}

	r = 0;

done:	return r;
}


/**
 * Gather and output pdag statistics for the full pdag (ctx)
 * including all disconnected components (type defs).
 *
 * Data is sent to given file ptr.
 */
void
ln_fullPTreeStats(ln_ctx ctx, FILE __attribute__((unused)) *const fp,
const int  __attribute__((unused)) extendedStats)
{
	ln_displayPTree(ctx->ptree, 0);
}
