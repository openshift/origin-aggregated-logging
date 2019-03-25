/**
 * @file lognorm.h
 * @brief Private data structures used by the liblognorm API.
 *//*
 *
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010 by Rainer Gerhards and Adiscon GmbH.
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
#ifndef LIBLOGNORM_LOGNORM_HINCLUDED
#define	LIBLOGNORM_LOGNORM_HINCLUDED
#include <stdlib.h>	/* we need size_t */
#include "liblognorm.h"
#include "pdag.h"
#include "annot.h"

/* some limits */
#define MAX_FIELDNAME_LEN 1024
#define MAX_TYPENAME_LEN  1024

#define LN_ObjID_None 0xFEFE0001
#define LN_ObjID_CTX 0xFEFE0001

struct ln_type_pdag {
	const char *name;
	ln_pdag *pdag;
};

struct ln_ctx_s {
	unsigned objID;	/**< a magic number to prevent some memory addressing errors */
	void (*dbgCB)(void *cookie, const char *msg, size_t lenMsg);
		/**< user-provided debug output callback */
	void *dbgCookie; /**< cookie to be passed to debug callback */
	void (*errmsgCB)(void *cookie, const char *msg, size_t lenMsg);
		/**< user-provided error message callback */
	void *errmsgCookie; /**< cookie to be passed to error message callback */
	ln_pdag *pdag; /**< parse dag being used by this context */
	ln_annotSet *pas; /**< associated set of annotations */
	unsigned nNodes; /**< number of nodes in our parse tree */
	unsigned char debug; /**< boolean: are we in debug mode? */
	es_str_t *rulePrefix; /**< work variable for loading rule bases
			       * this is the prefix string that will be prepended
			       * to all rules before they are submitted to tree
			       * building.
			       */
	unsigned opts; /**< specific options, see LN_CTXOPTS_* defines */
	struct ln_type_pdag *type_pdags; /**< array of our type pdags */
	int nTypes;		 /**< number of type pdags */
	int version;		/**< 1 or 2, depending on rulebase/algo version */

	/* here follows stuff for the v1 subsystem -- do NOT make any changes
	 * down here. This is strictly read-only. May also be removed some time in
	 * the future.
	 */
	struct ln_ptree *ptree;
	/* end old cruft */
	/* things for config processing / error message during it */
	int include_level;		/**< 1 for main rulebase file, higher for include levels */
	const char *conf_file;		/**< currently open config file or NULL, if none */
	unsigned int conf_ln_nbr;	/**< current config file line number */
};

void ln_dbgprintf(ln_ctx ctx, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
void ln_errprintf(ln_ctx ctx, const int eno, const char *fmt, ...) __attribute__((format(printf, 3, 4)));

#define LN_DBGPRINTF(ctx, ...) if(ctx->dbgCB != NULL) { ln_dbgprintf(ctx, __VA_ARGS__); }
//#define LN_DBGPRINTF(ctx, ...)
#endif /* #ifndef LIBLOGNORM_LOGNORM_HINCLUDED */
