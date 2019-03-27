/* This file implements the liblognorm API.
 * See header file for descriptions.
 *
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2013-2015 by Rainer Gerhards and Adiscon GmbH.
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
#include "v1_liblognorm.h"
#include "v1_ptree.h"
#include "lognorm.h"
#include "annot.h"
#include "v1_samp.h"

#define ERR_ABORT {r = 1; goto done; }

#define CHECK_CTX \
	if(ctx->objID != LN_ObjID_CTX) { \
		r = -1; \
		goto done; \
	}


ln_ctx
ln_v1_inherittedCtx(ln_ctx parent)
{
	ln_ctx child = ln_initCtx();
	if (child != NULL) {
		child->opts = parent->opts;
		child->dbgCB = parent->dbgCB;
		child->dbgCookie = parent->dbgCookie;
		child->version = parent->version;
		child->ptree = ln_newPTree(child, NULL);
	}

	return child;
}


int
ln_v1_loadSample(ln_ctx ctx, const char *buf)
{
	// Something bad happened - no new sample
	if (ln_v1_processSamp(ctx, buf, strlen(buf)) == NULL) {
		return 1;
	}
	return 0;
}


int
ln_v1_loadSamples(ln_ctx ctx, const char *file)
{
	int r = 0;
	FILE *repo;
	struct ln_v1_samp *samp;
	int isEof = 0;

	char *fn_to_free = NULL;
	CHECK_CTX;

	ctx->conf_file = fn_to_free = strdup(file);
	ctx->conf_ln_nbr = 0;

	if(file == NULL) ERR_ABORT;
	if((repo = fopen(file, "r")) == NULL) {
		ln_errprintf(ctx, errno, "cannot open file %s", file);
		ERR_ABORT;
	}
	while(!isEof) {
		if((samp = ln_v1_sampRead(ctx, repo, &isEof)) == NULL) {
			/* TODO: what exactly to do? */
		}
	}
	fclose(repo);

	ctx->conf_file = NULL;

done:
	free((void*)fn_to_free);
	return r;
}

