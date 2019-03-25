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
 * Copyright 2010-2017 by Rainer Gerhards and Adiscon GmbH.
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
#ifndef LIBLOGNORM_H_INCLUDED
#define LIBLOGNORM_H_INCLUDED
#include <stdlib.h>	/* we need size_t */
#include <json.h>

/* error codes */
#define LN_NOMEM -1
#define LN_INVLDFDESCR -1
#define LN_BADCONFIG -250
#define LN_BADPARSERSTATE -500
#define LN_WRONGPARSER -1000

#define LN_RB_LINE_TOO_LONG -1001
#define LN_OVER_SIZE_LIMIT -1002

/**
 * The library context descriptor.
 * This is used to permit multiple independent instances of the
 * library to be called within a single program. This is most
 * useful for plugin-based architectures.
 */
typedef struct ln_ctx_s* ln_ctx;

/* API */
/**
 * Return library version string.
 *
 * Returns the version of the currently used library.
 *
 * @return Zero-Terminated library version string.
 */
/* Note: this MUST NOT be inline to make sure the actual library
 * has the right version, not just what was used to compile!
 */
const char *ln_version(void);

/**
 * Return if library is build with advanced statistics
 * activated.
 *
 * @return 1 if advanced stats are active, 0 if not
 */
int ln_hasAdvancedStats(void);

/**
 * Initialize a library context.
 *
 * To prevent memory leaks, ln_exitCtx() must be called on a library
 * context that is no longer needed.
 *
 * @return new library context or NULL if an error occured
 */
ln_ctx ln_initCtx(void);

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
ln_ctx ln_inherittedCtx(ln_ctx parent);

/**
 * Discard a library context.
 *
 * Free's the ressources associated with the given library context. It
 * MUST NOT be accessed after calling this function.
 *
 * @param ctx The context to be discarded.
 *
 * @return Returns zero on success, something else otherwise.
 */
int ln_exitCtx(ln_ctx ctx);


/* binary values, so that we can "or" them together */
#define LN_CTXOPT_ALLOW_REGEX		0x01 /**< permit regex matching */
#define LN_CTXOPT_ADD_EXEC_PATH		0x02 /**< add exec_path attribute (time-consuming!) */
#define LN_CTXOPT_ADD_ORIGINALMSG	0x04 /**< always add original message to output
					          (not just in error case) */
#define LN_CTXOPT_ADD_RULE		0x08 /**< add mockup rule */
#define LN_CTXOPT_ADD_RULE_LOCATION	0x10 /**< add rule location (file, lineno) to metadata */
/**
 * Set options on ctx.
 *
 * @param ctx The context to be modified.
 * @param opts a potentially or-ed list of options, see LN_CTXOPT_*
 */
void
ln_setCtxOpts(ln_ctx ctx, unsigned opts);


/**
 * Set a debug message handler (callback).
 *
 * Liblognorm can provide helpful information for debugging
 * - it's internal processing
 * - the way a log message is being normalized
 *
 * It does so by emiting "interesting" information about its processing
 * at various stages. A caller can obtain this information by registering
 * an entry point. When done so, liblognorm will call the entry point
 * whenever it has something to emit. Note that debugging can be rather
 * verbose.
 *
 * The callback will be called with the following three parameters in that order:
 * - the caller-provided cookie
 * - a zero-terminated string buffer
 * - the length of the string buffer, without the trailing NUL byte
 *
 * @note
 * The provided callback function <b>must not</b> call any liblognorm
 * APIs except when specifically flagged as safe for calling by a debug
 * callback handler.
 *
 * @param[in] ctx The library context to apply callback to.
 * @param[in] cb The function to be called for debugging
 * @param[in] cookie Opaque cookie to be passed down to debug handler. Can be
 *                   used for some state tracking by the caller. This is defined as
 *                   void* to support pointers. To play it safe, a pointer should be
 *                   passed (but advantorous folks may also use an unsigned).
 *
 * @return Returns zero on success, something else otherwise.
 */
int ln_setDebugCB(ln_ctx ctx, void (*cb)(void*, const char*, size_t), void *cookie);

/**
 * Set a error message handler (callback).
 *
 * If set, this is used to emit error messages of interest to the user, e.g.
 * on failures during rulebase load. It is suggested that a caller uses this
 * feedback to aid its users in resolving issues.
 * Its semantics are otherwise exactly the same like ln_setDebugCB().
 */
int ln_setErrMsgCB(ln_ctx ctx, void (*cb)(void*, const char*, size_t), void *cookie);


/**
 * enable or disable debug mode.
 *
 * @param[in] ctx context
 * @param[in] b boolean 0 - disable debug mode, 1 - enable debug mode
 */
void ln_enableDebug(ln_ctx ctx, int i);


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
int ln_loadSamples(ln_ctx ctx, const char *file);

/**
 * Load a rulebase via a string.
 *
 * Note: this can only load v2 samples, v1 is NOT supported.
 *
 * @param[in] ctx The library context to apply callback to.
 * @param[in] string The string with the actual rulebase.
 *
 * @return Returns zero on success, something else otherwise.
 */
int ln_loadSamplesFromString(ln_ctx ctx, const char *string);

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
int ln_normalize(ln_ctx ctx, const char *str, const size_t strLen, struct json_object **json_p);

#endif /* #ifndef LOGNORM_H_INCLUDED */
