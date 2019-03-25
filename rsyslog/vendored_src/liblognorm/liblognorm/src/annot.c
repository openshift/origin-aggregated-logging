/**
 * @file annot.c
 * @brief Implementation of the annotation set object.
 * @class ln_annot annot.h
 *//*
 * Copyright 2011 by Rainer Gerhards and Adiscon GmbH.
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
 * Foundation, Inc., 51 Franklin Sannott, Fifth Floor, Boston, MA  02110-1301  USA
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

#include "lognorm.h"
#include "samp.h"
#include "annot.h"
#include "internal.h"

ln_annotSet*
ln_newAnnotSet(ln_ctx ctx)
{
	ln_annotSet *as;

	if((as = calloc(1, sizeof(struct ln_annotSet_s))) == NULL)
		goto done;
	as->ctx = ctx;
done:	return as;
}


void
ln_deleteAnnotSet(ln_annotSet *as)
{
	ln_annot *node, *nextnode;
	if(as == NULL)
		goto done;

	for(node = as->aroot; node != NULL; node = nextnode) {
		nextnode = node->next;
		ln_deleteAnnot(node);
	}
	free(as);
done:	return;
}


ln_annot*
ln_findAnnot(ln_annotSet *as, es_str_t *tag)
{
	ln_annot *annot;
	if(as == NULL) {
		annot = NULL;
		goto done;
	}

	for(  annot = as->aroot
	    ; annot != NULL && es_strcmp(annot->tag, tag)
	    ; annot = annot->next) {
		; /* do nothing, just search... */
	}
done:	return annot;
}


/**
 * Combine two annotations.
 * @param[in] annot currently existing and surviving annotation
 * @param[in] add   annotation to be added. This will be destructed
 *                  as part of the process.
 * @returns 0 if ok, something else otherwise
 */
static int
ln_combineAnnot(ln_annot *annot, ln_annot *add)
{
	int r = 0;
	ln_annot_op *op, *nextop;

	for(op = add->oproot; op != NULL; op = nextop) {
		CHKR(ln_addAnnotOp(annot, op->opc, op->name, op->value));
		nextop = op->next;
		free(op);
	}
	es_deleteStr(add->tag);
	free(add);
	
done:	return r;
}


int
ln_addAnnotToSet(ln_annotSet *as, ln_annot *annot)
{
	int r = 0;
	ln_annot *aexist;
	assert(annot->tag != NULL);
	aexist = ln_findAnnot(as, annot->tag);
	if(aexist == NULL) {
		/* does not yet exist, simply store new annot */
		annot->next = as->aroot;
		as->aroot = annot;
	} else { /* annotation already exists, combine */
		r = ln_combineAnnot(aexist, annot);
	}
	return r;
}


ln_annot*
ln_newAnnot(es_str_t *tag)
{
	ln_annot *annot;

	if((annot = calloc(1, sizeof(struct ln_annot_s))) == NULL)
		goto done;
	annot->tag = tag;
done:	return annot;
}


void
ln_deleteAnnot(ln_annot *annot)
{
	ln_annot_op *op, *nextop;
	if(annot == NULL)
		goto done;

	es_deleteStr(annot->tag);
	for(op = annot->oproot; op != NULL; op = nextop) {
		es_deleteStr(op->name);
		if(op->value != NULL)
			es_deleteStr(op->value);
		nextop = op->next;
		free(op);
	}
	free(annot);
done:	return;
}


int
ln_addAnnotOp(ln_annot *annot, ln_annot_opcode opc, es_str_t *name, es_str_t *value)
{
	int r = -1;
	ln_annot_op *node;

	if((node = calloc(1, sizeof(struct ln_annot_op_s))) == NULL)
		goto done;
	node->opc = opc;
	node->name = name;
	node->value = value;

	if(annot->oproot != NULL) {
		node->next = annot->oproot;
	}
	annot->oproot = node;
	r = 0;

done:	return r;
}


/* annotate the event with a specific tag. helper to keep code
 * small and easy to follow.
 */
static inline int
ln_annotateEventWithTag(ln_ctx ctx, struct json_object *json, es_str_t *tag)
{
	int r=0;
	ln_annot *annot;
	ln_annot_op *op;
	struct json_object *field;
	char *cstr;

	if (NULL == (annot = ln_findAnnot(ctx->pas, tag)))
		goto done;
	for(op = annot->oproot ; op != NULL ; op = op->next) {
		if(op->opc == ln_annot_ADD) {
			CHKN(cstr = ln_es_str2cstr(&op->value));
			CHKN(field = json_object_new_string(cstr));
			CHKN(cstr = ln_es_str2cstr(&op->name));
			json_object_object_add(json, cstr, field);
		} else {
			// TODO: implement
		}
	}

done: 	return r;
}


int
ln_annotate(ln_ctx ctx, struct json_object *json, struct json_object *tagbucket)
{
	int r = 0;
	es_str_t *tag;
	struct json_object *tagObj;
	const char *tagCstr;
	int i;

	ln_dbgprintf(ctx, "ln_annotate called [aroot=%p]", ctx->pas->aroot);
	/* shortcut: terminate immediately if nothing to do... */
	if(ctx->pas->aroot == NULL)
		goto done;

	/* iterate over tagbucket */
	for (i = json_object_array_length(tagbucket) - 1; i >= 0; i--) {
		CHKN(tagObj = json_object_array_get_idx(tagbucket, i));
		CHKN(tagCstr = json_object_get_string(tagObj));
		ln_dbgprintf(ctx, "ln_annotate, current tag %d, cstr %s", i, tagCstr);
		CHKN(tag = es_newStrFromCStr(tagCstr, strlen(tagCstr)));
		CHKR(ln_annotateEventWithTag(ctx, json, tag));
		es_deleteStr(tag);
	}

done:	return r;
}
