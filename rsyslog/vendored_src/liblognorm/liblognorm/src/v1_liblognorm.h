/**
 * @file liblognorm.h
 * @brief The public liblognorm API.
 *
 * <b>Functions other than those defined here MUST not be called by
 * a liblognorm "user" application.</b>
 *
 * This file is meant to be included by applications using liblognorm.
 * For lognorm library files themselves, include "lognorm.h".
 *//**
 * @mainpage
 * Liblognorm is an easy to use and fast samples-based log normalization
 * library.
 *
 * It can be passed a stream of arbitrary log messages, one at a time, and for
 * each message it will output well-defined name-value pairs and a set of
 * tags describing the message.
 *
 * For further details, see it's initial announcement available at
 *    http://blog.gerhards.net/2010/10/introducing-liblognorm.html
 *
 * The public interface of this library is describe in liblognorm.h.
 *
 * Liblognorm fully supports Unicode. Like most Linux tools, it operates
 * on UTF-8 natively, called "passive mode". This was decided because we
 * so can keep the size of data structures small while still supporting
 * all of the world's languages (actually more than when we did UCS-2).
 *
 * At the  technical level, we can handle UTF-8 multibyte sequences transparently.
 * Liblognorm needs to look at a few US-ASCII characters to do the
 * sample base parsing (things to indicate fields), so this is no
 * issue. Inside the parse tree, a multibyte sequence can simple be processed
 * as if it were a sequence of different characters that make up a their
 * own symbol each. In fact, this even allows for somewhat greater parsing
 * speed.
 *//*
 *
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2013 by Rainer Gerhards and Adiscon GmbH.
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
#ifndef V1_LIBLOGNORM_H_INCLUDED
#define V1_LIBLOGNORM_H_INCLUDED
#include "liblognorm.h"

/**
 * Inherit control attributes from a library context.
 *
 * This does not copy the parse-tree, but does copy
 * behaviour-controling attributes such as enableRegex.
 *
 * Just as with ln_initCtx, ln_exitCtx() must be called on a library
 * context that is no longer needed.
 *
 * @return new library context or NULL if an error occured
 */
ln_ctx ln_v1_inherittedCtx(ln_ctx parent);


/**
 * Reads a sample stored in buffer buf and creates a new ln_samp object
 * out of it.
 *
 * @note
 * It is the caller's responsibility to delete the newly
 * created ln_samp object if it is no longer needed.
 *
 * @param[ctx] ctx current library context
 * @param[buf] NULL terminated cstr containing the contents of the sample
 * @return Returns zero on success, something else otherwise.
 */
int
ln_v1_loadSample(ln_ctx ctx, const char *buf);

/**
 * Load a (log) sample file.
 *
 * The file must contain log samples in syntactically correct format. Samples are added
 * to set already loaded in the current context. If there is a sample with duplicate
 * semantics, this sample will be ignored. Most importantly, this can \b not be used
 * to change tag assignments for a given sample.
 *
 * @param[in] ctx The library context to apply callback to.
 * @param[in] file Name of file to be loaded.
 *
 * @return Returns zero on success, something else otherwise.
 */
int ln_v1_loadSamples(ln_ctx ctx, const char *file);

/**
 * Normalize a message.
 *
 * This is the main library entry point. It is called with a message
 * to normalize and will return a normalized in-memory representation
 * of it.
 *
 * If an error occurs, the function returns -1. In that case, an
 * in-memory event representation has been generated if event is
 * non-NULL. In that case, the event contains further error details in
 * normalized form.
 *
 * @note
 * This function works on byte-counted strings and as such is able to
 * process NUL bytes if they occur inside the message. On the other hand,
 * this means the the correct messages size, \b excluding the NUL byte,
 * must be provided.
 *
 * @param[in] ctx The library context to use.
 * @param[in] str The message string (see note above).
 * @param[in] strLen The length of the message in bytes.
 * @param[out] json_p A new event record or NULL if an error occured. <b>Must be
 *                   destructed if no longer needed.</b>
 *
 * @return Returns zero on success, something else otherwise.
 */
int ln_v1_normalize(ln_ctx ctx, const char *str, size_t strLen, struct json_object **json_p);


/**
 * create a single sample.
 */
struct ln_v1_samp* ln_v1_sampCreate(ln_ctx __attribute__((unused)) ctx);

/* here we add some stuff from the compatibility layer. A separate include
 * would be cleaner, but would potentially require changes all over the
 * place. So doing it here is better. The respective replacement
 * functions should usually be found under ./compat -- rgerhards, 2015-05-20
 */

#endif /* #ifndef LOGNORM_H_INCLUDED */
