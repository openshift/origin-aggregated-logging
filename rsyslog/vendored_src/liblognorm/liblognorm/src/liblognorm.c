/* This file implements the liblognorm API.
 * See header file for descriptions.
 *
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2013 by Rainer Gerhards and Adiscon GmbH.
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
#include <string.h>
#include <errno.h>

#include "liblognorm.h"
#include "lognorm.h"
#include "annot.h"
#include "samp.h"
#include "v1_liblognorm.h"
#include "v1_ptree.h"

#define CHECK_CTX \
	if(ctx->objID != LN_ObjID_CTX) { \
		r = -1; \
		goto done; \
	}

const char *
ln_version(void)
{
	return VERSION;
}

int
ln_hasAdvancedStats(void)
{
#ifdef	ADVANCED_STATS
	return 1;
#else
	return 0;
#endif
}

ln_ctx
ln_initCtx(void)
{
	ln_ctx ctx;
	if((ctx = calloc(1, sizeof(struct ln_ctx_s))) == NULL)
		goto done;

#ifdef HAVE_JSON_GLOBAL_SET_STRING_HASH
	json_global_set_string_hash(JSON_C_STR_HASH_PERLLIKE);
#endif
#ifdef HAVE_JSON_GLOBAL_SET_PRINTBUF_INITIAL_SIZE
	json_global_set_printbuf_initial_size(2048);
#endif
	ctx->objID = LN_ObjID_CTX;
	ctx->dbgCB = NULL;
	ctx->opts = 0;

	/* we add an root for the empty word, this simplifies parse
	 * dag handling.
	 */
	if((ctx->pdag = ln_newPDAG(ctx)) == NULL) {
		free(ctx);
		ctx = NULL;
		goto done;
	}
	/* same for annotation set */
	if((ctx->pas = ln_newAnnotSet(ctx)) == NULL) {
		ln_pdagDelete(ctx->pdag);
		free(ctx);
		ctx = NULL;
		goto done;
	}

done:
	return ctx;
}

void
ln_setCtxOpts(ln_ctx ctx, const unsigned opts) {
	ctx->opts |= opts;
}


int
ln_exitCtx(ln_ctx ctx)
{
	int r = 0;

	CHECK_CTX;

	ln_dbgprintf(ctx, "exitCtx %p", ctx);
	ctx->objID = LN_ObjID_None; /* prevent double free */
	/* support for old cruft */
	if(ctx->ptree != NULL)
		ln_deletePTree(ctx->ptree);
	/* end support for old cruft */
	if(ctx->pdag != NULL)
		ln_pdagDelete(ctx->pdag);
	for(int i = 0 ; i < ctx->nTypes ; ++i) {
		free((void*)ctx->type_pdags[i].name);
		ln_pdagDelete(ctx->type_pdags[i].pdag);
	}
	free(ctx->type_pdags);
	if(ctx->rulePrefix != NULL)
		es_deleteStr(ctx->rulePrefix);
	if(ctx->pas != NULL)
		ln_deleteAnnotSet(ctx->pas);
	free(ctx);
done:
	return r;
}


int
ln_setDebugCB(ln_ctx ctx, void (*cb)(void*, const char*, size_t), void *cookie)
{
	int r = 0;

	CHECK_CTX;
	ctx->dbgCB = cb;
	ctx->dbgCookie = cookie;
done:
	return r;
}


int
ln_setErrMsgCB(ln_ctx ctx, void (*cb)(void*, const char*, size_t), void *cookie)
{
	int r = 0;

	CHECK_CTX;
	ctx->errmsgCB = cb;
	ctx->errmsgCookie = cookie;
done:
	return r;
}

int
ln_loadSamples(ln_ctx ctx, const char *file)
{
	int r = 0;
	const char *tofree;
	CHECK_CTX;
	ctx->conf_file = tofree = strdup(file);
	ctx->conf_ln_nbr = 0;
	++ctx->include_level;
	r = ln_sampLoad(ctx, file);
	--ctx->include_level;
	free((void*)tofree);
	ctx->conf_file = NULL;
done:
	return r;
}

int
ln_loadSamplesFromString(ln_ctx ctx, const char *string)
{
	int r = 0;
	const char *tofree;
	CHECK_CTX;
	ctx->conf_file = tofree = strdup("--NO-FILE--");
	ctx->conf_ln_nbr = 0;
	++ctx->include_level;
	r = ln_sampLoadFromString(ctx, string);
	--ctx->include_level;
	free((void*)tofree);
	ctx->conf_file = NULL;
done:
	return r;
}
