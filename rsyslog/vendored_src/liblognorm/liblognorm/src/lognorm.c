/* liblognorm - a fast samples-based log normalization library
 * Copyright 2010 by Rainer Gerhards and Adiscon GmbH.
 *
 * This file is part of liblognorm.
 *
 * Released under ASL 2.0
 */
#include "config.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#include "liblognorm.h"
#include "lognorm.h"

/* Code taken from rsyslog ASL 2.0 code.
 * From varmojfekoj's mail on why he provided rs_strerror_r():
 * There are two problems with strerror_r():
 * I see you've rewritten some of the code which calls it to use only
 * the supplied buffer; unfortunately the GNU implementation sometimes
 * doesn't use the buffer at all and returns a pointer to some
 * immutable string instead, as noted in the man page.
 *
 * The other problem is that on some systems strerror_r() has a return
 * type of int.
 *
 * So I've written a wrapper function rs_strerror_r(), which should
 * take care of all this and be used instead.
 */
static char *
rs_strerror_r(const int errnum, char *const buf, const size_t buflen) {
#ifndef HAVE_STRERROR_R
	char *pszErr;
	pszErr = strerror(errnum);
	snprintf(buf, buflen, "%s", pszErr);
#else
#	ifdef STRERROR_R_CHAR_P
		char *p = strerror_r(errnum, buf, buflen);
		if (p != buf) {
			strncpy(buf, p, buflen);
			buf[buflen - 1] = '\0';
		}
#	else
		strerror_r(errnum, buf, buflen);
#	endif
#endif
	return buf;
}
/**
 * Generate some debug message and call the caller provided callback.
 *
 * Will first check if a user callback is registered. If not, returns
 * immediately.
 */
void
ln_dbgprintf(ln_ctx ctx, const char *fmt, ...)
{
	va_list ap;
	char buf[8*1024];
	size_t lenBuf;

	if(ctx->dbgCB == NULL)
		goto done;
	
	va_start(ap, fmt);
	lenBuf = vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	if(lenBuf >= sizeof(buf)) {
		/* prevent buffer overruns and garbagge display */
		buf[sizeof(buf) - 5] = '.';
		buf[sizeof(buf) - 4] = '.';
		buf[sizeof(buf) - 3] = '.';
		buf[sizeof(buf) - 2] = '\n';
		buf[sizeof(buf) - 1] = '\0';
		lenBuf = sizeof(buf) - 1;
	}

	ctx->dbgCB(ctx->dbgCookie, buf, lenBuf);
done:	return;
}

/**
 * Generate error message and call the caller provided callback.
 * eno is the OS errno. If non-zero, the OS error description
 * will be added after the user-provided string.
 *
 * Will first check if a user callback is registered. If not, returns
 * immediately.
 */
void
ln_errprintf(const ln_ctx ctx, const int eno, const char *fmt, ...)
{
	va_list ap;
	char buf[8*1024];
	char errbuf[1024];
	char finalbuf[9*1024];
	size_t lenBuf;
	char *msg;

	if(ctx->errmsgCB == NULL)
		goto done;
	
	va_start(ap, fmt);
	lenBuf = vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	if(lenBuf >= sizeof(buf)) {
		/* prevent buffer overrruns and garbagge display */
		buf[sizeof(buf) - 5] = '.';
		buf[sizeof(buf) - 4] = '.';
		buf[sizeof(buf) - 3] = '.';
		buf[sizeof(buf) - 2] = '\n';
		buf[sizeof(buf) - 1] = '\0';
		lenBuf = sizeof(buf) - 1;
	}

	if(eno != 0) {
		rs_strerror_r(eno, errbuf, sizeof(errbuf));
		lenBuf = snprintf(finalbuf, sizeof(finalbuf), "%s: %s", buf, errbuf);
		msg = finalbuf;
	} else {
		msg = buf;
	}

	if(ctx->conf_file != NULL) {
		/* error during config processing, add line info */
		const char *const m = strdup(msg);
		lenBuf = snprintf(finalbuf, sizeof(finalbuf), "rulebase file %s[%d]: %s",
			ctx->conf_file, ctx->conf_ln_nbr, m);
		msg = finalbuf;
		free((void*) m);
	}

	ctx->errmsgCB(ctx->dbgCookie, msg, lenBuf);
	ln_dbgprintf(ctx, "%s", msg);
done:	return;
}

void
ln_enableDebug(ln_ctx ctx, int i)
{
	ctx->debug = i & 0x01;
}
