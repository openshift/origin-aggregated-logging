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
#ifndef LIBLOGNORM_V1_SAMPLES_H_INCLUDED
#define	LIBLOGNORM_V1_SAMPLES_H_INCLUDED
#include <stdio.h>	/* we need es_size_t */
#include <libestr.h>


/**
 * A single log sample.
 */
struct ln_v1_samp {
	es_str_t *msg;
};

/**
 * Reads a sample stored in buffer buf and creates a new ln_v1_samp object
 * out of it.
 *
 * @note
 * It is the caller's responsibility to delete the newly
 * created ln_v1_samp object if it is no longer needed.
 *
 * @param[ctx] ctx current library context
 * @param[buf] cstr buffer containing the string contents of the sample
 * @param[lenBuf] length of the sample contained within buf
 * @return Newly create object or NULL if an error occured.
 */
struct ln_v1_samp *
ln_v1_processSamp(ln_ctx ctx, const char *buf, es_size_t lenBuf);


/**
 * Read a sample from repository (sequentially).
 *
 * Reads a sample starting with the current file position and
 * creates a new ln_v1_samp object out of it.
 *
 * @note
 * It is the caller's responsibility to delete the newly
 * created ln_v1_samp object if it is no longer needed.
 *
 * @param[in] ctx current library context
 * @param[in] repo repository descriptor
 * @param[out] isEof must be set to 0 on entry and is switched to 1 if EOF occured.
 * @return Newly create object or NULL if an error or EOF occured.
 */
struct ln_v1_samp *
ln_v1_sampRead(ln_ctx ctx, FILE *repo, int *isEof);


/**
 * Free ln_v1_samp object.
 */
void
ln_v1_sampFree(ln_ctx ctx, struct ln_v1_samp *samp);


/**
 * Parse a given sample
 *
 * @param[in] ctx current library context
 * @param[in] rule string (with prefix and suffix '%' markers)
 * @param[in] offset in rule-string to start at (it should be pointed to
 *  starting character: '%')
 * @param[in] temp string buffer(working space),
 *  externalized for efficiency reasons
 * @param[out] return code (0 means success)
 * @return newly created node, which can be added to sample tree.
 */
ln_fieldList_t*
ln_v1_parseFieldDescr(ln_ctx ctx, es_str_t *rule, es_size_t *bufOffs,
				   es_str_t **str, int* ret);

#endif /* #ifndef LIBLOGNORM_V1_SAMPLES_H_INCLUDED */
