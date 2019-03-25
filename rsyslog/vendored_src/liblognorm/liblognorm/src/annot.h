/**
 * @file annot.h
 * @brief The annotation set object
 * @class ln_annot annot.h
 *//*
 * Copyright 2011 by Rainer Gerhards and Adiscon GmbH.
 *
 * Modified by Pavel Levshin (pavel@levshin.spb.ru) in 2013
 *
 * This file is meant to be included by applications using liblognorm.
 * For lognorm library files themselves, include "lognorm.h".
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
#ifndef LIBLOGNORM_ANNOT_H_INCLUDED
#define	LIBLOGNORM_ANNOT_H_INCLUDED
#include <libestr.h>

typedef struct ln_annotSet_s ln_annotSet;
typedef struct ln_annot_s ln_annot;
typedef struct ln_annot_op_s ln_annot_op;
typedef enum {ln_annot_ADD=0, ln_annot_RM=1} ln_annot_opcode;

/**
 * List of annotation operations.
 */
struct ln_annot_op_s {
	ln_annot_op *next;
	ln_annot_opcode opc; /**< opcode */
	es_str_t *name;
	es_str_t *value;
};

/**
 * annotation object
 */
struct ln_annot_s {
	ln_annot *next;	/**< used for chaining annotations */
	es_str_t *tag;	/**< tag associated for this annotation */
	ln_annot_op *oproot;
};

/**
 * annotation set object
 *
 * Note: we do not (yet) use a hash table. However, performance should
 * be gained by pre-processing rules so that tags directly point into
 * the annotation. This is even faster than hash table access.
 */
struct ln_annotSet_s {
	ln_annot *aroot;
	ln_ctx ctx;	/**< save our context for easy dbgprintf et al... */
};

/* Methods */


/**
 * Allocates and initializes a new annotation set.
 * @memberof ln_annot
 *
 * @param[in] ctx current library context. This MUST match the
 * 		context of the parent.
 *
 * @return pointer to new node or NULL on error
 */
ln_annotSet* ln_newAnnotSet(ln_ctx ctx);


/**
 * Free annotation set and destruct all members.
 * @memberof ln_annot
 *
 * @param[in] tree pointer to annot to free
 */
void ln_deleteAnnotSet(ln_annotSet *as);


/**
 * Find annotation inside set based on given tag name.
 * @memberof ln_annot
 *
 * @param[in] as annotation set
 * @param[in] tag tag name to look for
 *
 * @returns NULL if not found, ptr to object otherwise
 */
ln_annot* ln_findAnnot(ln_annotSet *as, es_str_t *tag);


/**
 * Add annotation to set.
 * If an annotation associated with this tag already exists, these
 * are combined. If not, a new annotation is added. Note that the
 * caller must not access any of the objects passed in to this method
 * after it has finished (objects may become deallocated during the
 * method).
 * @memberof ln_annot
 *
 * @param[in] as annotation set
 * @param[in] annot annotation to add
 *
 * @returns 0 on success, something else otherwise
 */
int ln_addAnnotToSet(ln_annotSet *as, ln_annot *annot);


/**
 * Allocates and initializes a new annotation.
 * The tag passed in identifies the new annotation. The caller
 * no longer owns the tag string after calling this method, so
 * it must not access the same copy when the method returns.
 * @memberof ln_annot
 *
 * @param[in] tag tag associated to annot (must not be NULL)
 * @return pointer to new node or NULL on error
 */
ln_annot* ln_newAnnot(es_str_t *tag);


/**
 * Free annotation and destruct all members.
 * @memberof ln_annot
 *
 * @param[in] tree pointer to annot to free
 */
void ln_deleteAnnot(ln_annot *annot);


/**
 * Add an operation to the annotation set.
 * The operation description will be added as entry.
 * @memberof ln_annot
 *
 * @param[in] annot pointer to annot to modify
 * @param[in] op operation
 * @param[in] name name of field, must NOT be re-used by caller
 * @param[in] value value of field, may be NULL (e.g. in remove operation),
 * 		    must NOT be re-used by caller
 * @returns 0 on success, something else otherwise
 */
int ln_addAnnotOp(ln_annot *anot, ln_annot_opcode opc, es_str_t *name, es_str_t *value);


/**
 * Annotate an event.
 * This adds annotations based on the event's tagbucket.
 * @memberof ln_annot
 *
 * @param[in] ctx current context
 * @param[in] event event to annotate (updated with anotations on exit)
 * @returns 0 on success, something else otherwise
 */
int ln_annotate(ln_ctx ctx, struct json_object *json, struct json_object *tags);

#endif /* #ifndef LOGNORM_ANNOT_H_INCLUDED */
