/**
 * @file samples.h
 * @brief Object to process log samples.
 * @author Rainer Gerhards
 *
 * This object handles log samples, and in actual log sample files.
 * It co-operates with the ptree object to build the actual parser tree.
 *//*
 *
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2015 by Rainer Gerhards and Adiscon GmbH.
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
 * Lesser General PublicCH License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * A copy of the LGPL v2.1 can be found in the file "COPYING" in this distribution.
 */
#ifndef LIBLOGNORM_SAMPLES_H_INCLUDED
#define	LIBLOGNORM_SAMPLES_H_INCLUDED
#include <stdio.h>	/* we need es_size_t */
#include <libestr.h>


/**
 * A single log sample.
 */
struct ln_samp {
	es_str_t *msg;
};

void ln_sampFree(ln_ctx ctx, struct ln_samp *samp);
int ln_sampLoad(ln_ctx ctx, const char *file);
int ln_sampLoadFromString(ln_ctx ctx, const char *string);

/* dual-use funtions for v1 engine */
void ln_sampSkipCommentLine(ln_ctx ctx, FILE * const __restrict__ repo, const char **inpbuf);
int ln_sampChkRunawayRule(ln_ctx ctx, FILE *const __restrict__ repo, const char **inpbuf);

#endif /* #ifndef LIBLOGNORM_SAMPLES_H_INCLUDED */
