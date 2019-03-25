/*
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010-2018 by Rainer Gerhards and Adiscon GmbH.
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
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>
#include <sys/types.h>
#include <string.h>
#include <strings.h>
#include <errno.h>
#include <inttypes.h>
#include <time.h>

#include "liblognorm.h"
#include "lognorm.h"
#include "internal.h"
#include "parser.h"
#include "samp.h"
#include "helpers.h"

#ifdef FEATURE_REGEXP
#include <pcre.h>
#include <errno.h>
#endif


/* how should output values be formatted? */
enum FMT_MODE {
	FMT_AS_STRING = 0,
	FMT_AS_NUMBER = 1,
	FMT_AS_TIMESTAMP_UX = 2,
	FMT_AS_TIMESTAMP_UX_MS = 3
	};

/* some helpers */
static inline int
hParseInt(const unsigned char **buf, size_t *lenBuf)
{
	const unsigned char *p = *buf;
	size_t len = *lenBuf;
	int i = 0;

	while(len > 0 && myisdigit(*p)) {
		i = i * 10 + *p - '0';
		++p;
		--len;
	}

	*buf = p;
	*lenBuf = len;
	return i;
}

/* parser _parse interface
 *
 * All parsers receive
 *
 * @param[in] npb->str the to-be-parsed string
 * @param[in] npb->strLen length of the to-be-parsed string
 * @param[in] offs an offset into the string
 * @param[in] pointer to parser data block
 * @param[out] parsed bytes
 * @param[out] value ptr to json object containing parsed data
 *             (can be unused, but if used *value MUST be NULL on entry)
 *
 * They will try to parse out "their" object from the string. If they
 * succeed, they:
 *
 * return 0 on success and LN_WRONGPARSER if this parser could
 *           not successfully parse (but all went well otherwise) and something
 *           else in case of an error.
 */
#define PARSER_Parse(ParserName) \
int ln_v2_parse##ParserName( \
	npb_t *const npb, \
	size_t *const offs,       \
	__attribute__((unused)) void *const pdata, \
	size_t *parsed,                                      \
	struct json_object **value) \
{ \
	int r = LN_WRONGPARSER; \
	*parsed = 0;

#define FAILParser \
	goto parserdone; /* suppress warnings */ \
parserdone: \
	r = 0; \
	goto done; /* suppress warnings */ \
done:

#define ENDFailParser \
	return r; \
}


/* Return printable representation of parser content for
 * display purposes. This must not be 100% exact, but provide
 * a good indication of what it contains for a human.
 * @param[data] data parser data block
 * @return pointer to c string, NOT to be freed
 */
#define PARSER_DataForDisplay(ParserName) \
const char * ln_DataForDisplay##ParserName(__attribute__((unused)) ln_ctx ctx, void *const pdata)


/* Return JSON parser config. This is primarily for comparison
 * of parser equalness.
 * @param[data] data parser data block
 * @return pointer to c string, NOT to be freed
 */
#define PARSER_JsonConf(ParserName) \
const char * ln_JsonConf##ParserName(__attribute__((unused)) ln_ctx ctx, void *const pdata)


/* parser constructor
 * @param[in] json config json items
 * @param[out] data parser data block (to be allocated)
 * At minimum, *data must be set to NULL
 * @return error status (0 == OK)
 */
#define PARSER_Construct(ParserName) \
int ln_construct##ParserName( \
	__attribute__((unused)) ln_ctx ctx, \
	__attribute__((unused)) json_object *const json, \
	void **pdata)

/* parser destructor
 * @param[data] data parser data block (to be de-allocated)
 */
#define PARSER_Destruct(ParserName) \
void ln_destruct##ParserName(__attribute__((unused)) ln_ctx ctx, void *const pdata)


/* the following table saves us from computing an additional date to get
 * the ordinal day of the year - at least from 1967-2099
 * Note: non-2038+ compliant systems (Solaris) will generate compiler
 * warnings on the post 2038-rollover years.
 */
static const int yearInSec_startYear = 1967;
/* for x in $(seq 1967 2099) ; do
 *   printf %s', ' $(date --date="Dec 31 ${x} UTC 23:59:59" +%s)
 * done |fold -w 70 -s */
static const time_t yearInSecs[] = {
	-63158401, -31536001, -1, 31535999, 63071999, 94694399, 126230399,
	157766399, 189302399, 220924799, 252460799, 283996799, 315532799,
	347155199, 378691199, 410227199, 441763199, 473385599, 504921599,
	536457599, 567993599, 599615999, 631151999, 662687999, 694223999,
	725846399, 757382399, 788918399, 820454399, 852076799, 883612799,
	915148799, 946684799, 978307199, 1009843199, 1041379199, 1072915199,
	1104537599, 1136073599, 1167609599, 1199145599, 1230767999,
	1262303999, 1293839999, 1325375999, 1356998399, 1388534399,
	1420070399, 1451606399, 1483228799, 1514764799, 1546300799,
	1577836799, 1609459199, 1640995199, 1672531199, 1704067199,
	1735689599, 1767225599, 1798761599, 1830297599, 1861919999,
	1893455999, 1924991999, 1956527999, 1988150399, 2019686399,
	2051222399, 2082758399, 2114380799, 2145916799, 2177452799,
	2208988799, 2240611199, 2272147199, 2303683199, 2335219199,
	2366841599, 2398377599, 2429913599, 2461449599, 2493071999,
	2524607999, 2556143999, 2587679999, 2619302399, 2650838399,
	2682374399, 2713910399, 2745532799, 2777068799, 2808604799,
	2840140799, 2871763199, 2903299199, 2934835199, 2966371199,
	2997993599, 3029529599, 3061065599, 3092601599, 3124223999,
	3155759999, 3187295999, 3218831999, 3250454399, 3281990399,
	3313526399, 3345062399, 3376684799, 3408220799, 3439756799,
	3471292799, 3502915199, 3534451199, 3565987199, 3597523199,
	3629145599, 3660681599, 3692217599, 3723753599, 3755375999,
	3786911999, 3818447999, 3849983999, 3881606399, 3913142399,
	3944678399, 3976214399, 4007836799, 4039372799, 4070908799,
	4102444799};

/**
 * convert syslog timestamp to time_t
 * Note: it would be better to use something similar to mktime() here.
 * Unfortunately, mktime() semantics are problematic: first of all, it
 * works on local time, on the machine's time zone. In syslog, we have
 * to deal with multiple time zones at once, so we cannot plainly rely
 * on the local zone, and so we cannot rely on mktime(). One solution would
 * be to refactor all time-related functions so that they are all guarded
 * by a mutex to ensure TZ consistency (which would also enable us to
 * change the TZ at will for specific function calls). But that would
 * potentially mean a lot of overhead.
 * Also, mktime() has some side effects, at least setting of tzname. With
 * a refactoring as described above that should probably not be a problem,
 * but would also need more work. For some more thoughts on this topic,
 * have a look here:
 * http://stackoverflow.com/questions/18355101/is-standard-c-mktime-thread-safe-on-linux
 * In conclusion, we keep our own code for generating the unix timestamp.
 * rgerhards, 2016-03-02 (taken from rsyslog sources)
 */
static time_t
syslogTime2time_t(const int year, const int month, const int day,
	const int hour, const int minute, const int second,
	const int OffsetHour, const int OffsetMinute, const char OffsetMode)
{
	long MonthInDays, NumberOfYears, NumberOfDays;
	int utcOffset;
	time_t TimeInUnixFormat;

	if(year < 1970 || year > 2100) {
		TimeInUnixFormat = 0;
		goto done;
	}

	/* Counting how many Days have passed since the 01.01 of the
	 * selected Year (Month level), according to the selected Month*/

	switch(month)
	{
		case 1:
			MonthInDays = 0;         //until 01 of January
			break;
		case 2:
			MonthInDays = 31;        //until 01 of February - leap year handling down below!
			break;
		case 3:
			MonthInDays = 59;        //until 01 of March
			break;
		case 4:
			MonthInDays = 90;        //until 01 of April
			break;
		case 5:
			MonthInDays = 120;       //until 01 of Mai
			break;
		case 6:
			MonthInDays = 151;       //until 01 of June
			break;
		case 7:
			MonthInDays = 181;       //until 01 of July
			break;
		case 8:
			MonthInDays = 212;       //until 01 of August
			break;
		case 9:
			MonthInDays = 243;       //until 01 of September
			break;
		case 10:
			MonthInDays = 273;       //until 01 of Oktober
			break;
		case 11:
			MonthInDays = 304;       //until 01 of November
			break;
		case 12:
			MonthInDays = 334;       //until 01 of December
			break;
		default: /* this cannot happen (and would be a program error)
		          * but we need the code to keep the compiler silent.
			  */
			MonthInDays = 0;	/* any value fits ;) */
			break;
	}
	/* adjust for leap years */
	if((year % 100 != 0 && year % 4 == 0) || (year == 2000)) {
		if(month > 2)
			MonthInDays++;
	}


	/*	1) Counting how many Years have passed since 1970
		2) Counting how many Days have passed since the 01.01 of the selected Year
			(Day level) according to the Selected Month and Day. Last day doesn't count,
			it should be until last day
		3) Calculating this period (NumberOfDays) in seconds*/

	NumberOfYears = year - yearInSec_startYear - 1;
	NumberOfDays = MonthInDays + day - 1;
	TimeInUnixFormat = (yearInSecs[NumberOfYears] + 1) + NumberOfDays * 86400;

	/*Add Hours, minutes and seconds */
	TimeInUnixFormat += hour*60*60;
	TimeInUnixFormat += minute*60;
	TimeInUnixFormat += second;
	/* do UTC offset */
	utcOffset = OffsetHour*3600 + OffsetMinute*60;
	if(OffsetMode == '+')
		utcOffset *= -1; /* if timestamp is ahead, we need to "go back" to UTC */
	TimeInUnixFormat += utcOffset;
done:
	return TimeInUnixFormat;
}


struct data_RFC5424Date {
	enum FMT_MODE fmt_mode;
};
/**
 * Parse a TIMESTAMP as specified in RFC5424 (subset of RFC3339).
 */
PARSER_Parse(RFC5424Date)
	const unsigned char *pszTS;
	struct data_RFC5424Date *const data = (struct data_RFC5424Date*) pdata;
	/* variables to temporarily hold time information while we parse */
	int year;
	int month;
	int day;
	int hour; /* 24 hour clock */
	int minute;
	int second;
	int secfrac;	/* fractional seconds (must be 32 bit!) */
	int secfracPrecision;
	int OffsetHour;		/* UTC offset in hours */
	int OffsetMinute;	/* UTC offset in minutes */
	char OffsetMode;
	size_t len;
	size_t orglen;
	/* end variables to temporarily hold time information while we parse */

	pszTS = (unsigned char*) npb->str + *offs;
	len = orglen = npb->strLen - *offs;

	year = hParseInt(&pszTS, &len);

	/* We take the liberty to accept slightly malformed timestamps e.g. in
	 * the format of 2003-9-1T1:0:0.  */
	if(len == 0 || *pszTS++ != '-') goto done;
	--len;
	month = hParseInt(&pszTS, &len);
	if(month < 1 || month > 12) goto done;

	if(len == 0 || *pszTS++ != '-')
		goto done;
	--len;
	day = hParseInt(&pszTS, &len);
	if(day < 1 || day > 31) goto done;

	if(len == 0 || *pszTS++ != 'T') goto done;
	--len;

	hour = hParseInt(&pszTS, &len);
	if(hour < 0 || hour > 23) goto done;

	if(len == 0 || *pszTS++ != ':')
		goto done;
	--len;
	minute = hParseInt(&pszTS, &len);
	if(minute < 0 || minute > 59) goto done;

	if(len == 0 || *pszTS++ != ':') goto done;
	--len;
	second = hParseInt(&pszTS, &len);
	if(second < 0 || second > 60) goto done;

	/* Now let's see if we have secfrac */
	if(len > 0 && *pszTS == '.') {
		--len;
		const unsigned char *pszStart = ++pszTS;
		secfrac = hParseInt(&pszTS, &len);
		secfracPrecision = (int) (pszTS - pszStart);
	} else {
		secfracPrecision = 0;
		secfrac = 0;
	}

	/* check the timezone */
	if(len == 0) goto done;

	if(*pszTS == 'Z') {
		OffsetHour = 0;
		OffsetMinute = 0;
		OffsetMode = '+';
		--len;
		pszTS++; /* eat Z */
	} else if((*pszTS == '+') || (*pszTS == '-')) {
		OffsetMode = *pszTS;
		--len;
		pszTS++;

		OffsetHour = hParseInt(&pszTS, &len);
		if(OffsetHour < 0 || OffsetHour > 23)
			goto done;

		if(len == 0 || *pszTS++ != ':')
			goto done;
		--len;
		OffsetMinute = hParseInt(&pszTS, &len);
		if(OffsetMinute < 0 || OffsetMinute > 59)
			goto done;
	} else {
		/* there MUST be TZ information */
		goto done;
	}

	if(len > 0) {
		if(*pszTS != ' ') /* if it is not a space, it can not be a "good" time */
			goto done;
	}

	/* we had success, so update parse pointer */
	*parsed = orglen - len;

	if(value != NULL) {
		if(data->fmt_mode == FMT_AS_STRING) {
			*value = json_object_new_string_len(npb->str+(*offs), *parsed);
		} else {
			int64_t timestamp = syslogTime2time_t(year, month, day,
				hour, minute, second, OffsetHour, OffsetMinute, OffsetMode);
			if(data->fmt_mode == FMT_AS_TIMESTAMP_UX_MS) {
				timestamp *= 1000;
				/* simulate pow(), do not use math lib! */
				int div = 1;
				if(secfracPrecision == 1) {
					secfrac *= 100;
				} else if(secfracPrecision == 2) {
					secfrac *= 10;
				} else if(secfracPrecision > 3) {
					for(int i = 0 ; i < (secfracPrecision - 3) ; ++i)
						div *= 10;
				}
				timestamp += secfrac / div;
			}
			*value = json_object_new_int64(timestamp);
		}
	}

	r = 0; /* success */
done:
	return r;
}
PARSER_Construct(RFC5424Date)
{
	int r = 0;
	struct data_RFC5424Date *data =
		(struct data_RFC5424Date*) calloc(1, sizeof(struct data_RFC5424Date));
	data->fmt_mode = FMT_AS_STRING;

	if(json == NULL)
		goto done;

	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcmp(key, "format")) {
			const char *fmtmode = json_object_get_string(val);
			if(!strcmp(fmtmode, "timestamp-unix")) {
				data->fmt_mode = FMT_AS_TIMESTAMP_UX;
			} else if(!strcmp(fmtmode, "timestamp-unix-ms")) {
				data->fmt_mode = FMT_AS_TIMESTAMP_UX_MS;
			} else if(!strcmp(fmtmode, "string")) {
				data->fmt_mode = FMT_AS_STRING;
			} else {
				ln_errprintf(ctx, 0, "invalid value for date-rfc5424:format %s",
					fmtmode);
			}
		} else {
			ln_errprintf(ctx, 0, "invalid param for date-rfc5424 %s", key);
		}
		json_object_iter_next(&it);
	}

done:
	*pdata = data;
	return r;
}
PARSER_Destruct(RFC5424Date)
{
	free(pdata);
}


struct data_RFC3164Date {
	enum FMT_MODE fmt_mode;
};
/**
 * Parse a RFC3164 Date.
 */
PARSER_Parse(RFC3164Date)
	const unsigned char *p;
	size_t len, orglen;
	struct data_RFC3164Date *const data = (struct data_RFC3164Date*) pdata;
	/* variables to temporarily hold time information while we parse */
	int year;
	int month;
	int day;
	int hour; /* 24 hour clock */
	int minute;
	int second;

	p = (unsigned char*) npb->str + *offs;
	orglen = len = npb->strLen - *offs;
	/* If we look at the month (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec),
	 * we may see the following character sequences occur:
	 *
	 * J(an/u(n/l)), Feb, Ma(r/y), A(pr/ug), Sep, Oct, Nov, Dec
	 *
	 * We will use this for parsing, as it probably is the
	 * fastest way to parse it.
	 */
	if(len < 3)
		goto done;

	switch(*p++)
	{
	case 'j':
	case 'J':
		if(*p == 'a' || *p == 'A') {
			++p;
			if(*p == 'n' || *p == 'N') {
				++p;
				month = 1;
			} else
				goto done;
		} else if(*p == 'u' || *p == 'U') {
			++p;
			if(*p == 'n' || *p == 'N') {
				++p;
				month = 6;
			} else if(*p == 'l' || *p == 'L') {
				++p;
				month = 7;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'f':
	case 'F':
		if(*p == 'e' || *p == 'E') {
			++p;
			if(*p == 'b' || *p == 'B') {
				++p;
				month = 2;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'm':
	case 'M':
		if(*p == 'a' || *p == 'A') {
			++p;
			if(*p == 'r' || *p == 'R') {
				++p;
				month = 3;
			} else if(*p == 'y' || *p == 'Y') {
				++p;
				month = 5;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'a':
	case 'A':
		if(*p == 'p' || *p == 'P') {
			++p;
			if(*p == 'r' || *p == 'R') {
				++p;
				month = 4;
			} else
				goto done;
		} else if(*p == 'u' || *p == 'U') {
			++p;
			if(*p == 'g' || *p == 'G') {
				++p;
				month = 8;
			} else
				goto done;
		} else
			goto done;
		break;
	case 's':
	case 'S':
		if(*p == 'e' || *p == 'E') {
			++p;
			if(*p == 'p' || *p == 'P') {
				++p;
				month = 9;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'o':
	case 'O':
		if(*p == 'c' || *p == 'C') {
			++p;
			if(*p == 't' || *p == 'T') {
				++p;
				month = 10;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'n':
	case 'N':
		if(*p == 'o' || *p == 'O') {

			++p;
			if(*p == 'v' || *p == 'V') {
				++p;
				month = 11;
			} else
				goto done;
		} else
			goto done;
		break;
	case 'd':
	case 'D':
		if(*p == 'e' || *p == 'E') {
			++p;
			if(*p == 'c' || *p == 'C') {
				++p;
				month = 12;
			} else
				goto done;
		} else
			goto done;
		break;
	default:
		goto done;
	}

	len -= 3;
	
	/* done month */

	if(len == 0 || *p++ != ' ')
		goto done;
	--len;

	/* we accept a slightly malformed timestamp with one-digit days. */
	if(*p == ' ') {
		--len;
		++p;
	}

	day = hParseInt(&p, &len);
	if(day < 1 || day > 31)
		goto done;

	if(len == 0 || *p++ != ' ')
		goto done;
	--len;

	/* time part */
	hour = hParseInt(&p, &len);
	if(hour > 1970 && hour < 2100) {
		/* if so, we assume this actually is a year. This is a format found
		 * e.g. in Cisco devices.
		 *
		year = hour;
		*/

		/* re-query the hour, this time it must be valid */
		if(len == 0 || *p++ != ' ')
			goto done;
		--len;
		hour = hParseInt(&p, &len);
	}

	if(hour < 0 || hour > 23)
		goto done;

	if(len == 0 || *p++ != ':')
		goto done;
	--len;
	minute = hParseInt(&p, &len);
	if(minute < 0 || minute > 59)
		goto done;

	if(len == 0 || *p++ != ':')
		goto done;
	--len;
	second = hParseInt(&p, &len);
	if(second < 0 || second > 60)
		goto done;

	/* we provide support for an extra ":" after the date. While this is an
	 * invalid format, it occurs frequently enough (e.g. with Cisco devices)
	 * to permit it as a valid case. -- rgerhards, 2008-09-12
	 */
	if(len > 0 && *p == ':') {
		++p; /* just skip past it */
		--len;
	}

	/* we had success, so update parse pointer */
	*parsed = orglen - len;
	if(value != NULL) {
		if(data->fmt_mode == FMT_AS_STRING) {
			*value = json_object_new_string_len(npb->str+(*offs), *parsed);
		} else {
			/* we assume year == current year, so let's obtain current year */
			struct tm tm;
			const time_t curr = time(NULL);
			gmtime_r(&curr, &tm);
			year = tm.tm_year + 1900;
			int64_t timestamp = syslogTime2time_t(year, month, day,
				hour, minute, second, 0, 0, '+');
			if(data->fmt_mode == FMT_AS_TIMESTAMP_UX_MS) {
				/* we do not have more precise info, just bring
				 * into common format!
				 */
				timestamp *= 1000;
			}
			*value = json_object_new_int64(timestamp);
		}
	}
	r = 0; /* success */
done:
	return r;
}
PARSER_Construct(RFC3164Date)
{
	int r = 0;
	struct data_RFC3164Date *data = (struct data_RFC3164Date*) calloc(1, sizeof(struct data_RFC3164Date));
	data->fmt_mode = FMT_AS_STRING;

	if(json == NULL)
		goto done;

	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcmp(key, "format")) {
			const char *fmtmode = json_object_get_string(val);
			if(!strcmp(fmtmode, "timestamp-unix")) {
				data->fmt_mode = FMT_AS_TIMESTAMP_UX;
			} else if(!strcmp(fmtmode, "timestamp-unix-ms")) {
				data->fmt_mode = FMT_AS_TIMESTAMP_UX_MS;
			} else if(!strcmp(fmtmode, "string")) {
				data->fmt_mode = FMT_AS_STRING;
			} else {
				ln_errprintf(ctx, 0, "invalid value for date-rfc3164:format %s",
					fmtmode);
			}
		} else {
			ln_errprintf(ctx, 0, "invalid param for date-rfc3164 %s", key);
		}
		json_object_iter_next(&it);
	}

done:
	*pdata = data;
	return r;
}
PARSER_Destruct(RFC3164Date)
{
	free(pdata);
}


struct data_Number {
	int64_t maxval;
	enum FMT_MODE fmt_mode;
};
/**
 * Parse a Number.
 * Note that a number is an abstracted concept. We always represent it
 * as 64 bits (but may later change our mind if performance dictates so).
 */
PARSER_Parse(Number)
	const char *c;
	size_t i;
	int64_t val = 0;
	struct data_Number *const data = (struct data_Number*) pdata;

	enum FMT_MODE fmt_mode = FMT_AS_STRING;
	int64_t maxval = 0;
	if(data != NULL) {
		fmt_mode = data->fmt_mode;
		maxval = data->maxval;
	}

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;

	for (i = *offs; i < npb->strLen && myisdigit(c[i]); i++)
		val = val * 10 + c[i] - '0';

	if(maxval > 0 && val > maxval) {
		LN_DBGPRINTF(npb->ctx, "number parser: val too large (max %" PRIu64
			     ", actual %" PRIu64 ")",
			     maxval, val);
		goto done;
	}

	if (i == *offs)
		goto done;
	
	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		if(fmt_mode == FMT_AS_STRING) {
			*value = json_object_new_string_len(npb->str+(*offs), *parsed);
		} else {
			*value = json_object_new_int64(val);
		}
	}
	r = 0; /* success */
done:
	return r;
}

PARSER_Construct(Number)
{
	int r = 0;
	struct data_Number *data = (struct data_Number*) calloc(1, sizeof(struct data_Number));
	data->fmt_mode = FMT_AS_STRING;

	if(json == NULL)
		goto done;

	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcmp(key, "maxval")) {
			errno = 0;
			data->maxval = json_object_get_int64(val);
			if(errno != 0) {
				ln_errprintf(ctx, errno, "param 'maxval' must be integer but is: %s",
					 json_object_to_json_string(val));
			}
		} else if(!strcmp(key, "format")) {
			const char *fmtmode = json_object_get_string(val);
			if(!strcmp(fmtmode, "number")) {
				data->fmt_mode = FMT_AS_NUMBER;
			} else if(!strcmp(fmtmode, "string")) {
				data->fmt_mode = FMT_AS_STRING;
			} else {
				ln_errprintf(ctx, 0, "invalid value for number:format %s",
					fmtmode);
			}
		} else {
			ln_errprintf(ctx, 0, "invalid param for number: %s", key);
		}
		json_object_iter_next(&it);
	}

done:
	*pdata = data;
	return r;
}
PARSER_Destruct(Number)
{
	free(pdata);
}

struct data_Float {
	enum FMT_MODE fmt_mode;
};
/**
 * Parse a Real-number in floating-pt form.
 */
PARSER_Parse(Float)
	const char *c;
	size_t i;
	const struct data_Float *const data = (struct data_Float*) pdata;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;

	int isNeg = 0;
	double val = 0;
	int seen_point = 0;
	double frac = 10;

	i = *offs;

	if (c[i] == '-') {
		isNeg = 1;
		i++;
	}

	for (; i < npb->strLen; i++) {
		if (c[i] == '.') {
			if (seen_point != 0)
				break;
			seen_point = 1;
		} else if (myisdigit(c[i])) {
			if(seen_point) {
				val += (c[i] - '0') / frac;
				frac *= 10;
			} else {
				val = val * 10 + c[i] - '0';
			}
		} else {
			break;
		}
	}
	if (i == *offs)
		goto done;

	if(isNeg)
		val *= -1;

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		if(data->fmt_mode == FMT_AS_STRING) {
			*value = json_object_new_string_len(npb->str+(*offs), *parsed);
		} else {
			char *serialized = strndup(npb->str+(*offs), *parsed);
			*value = json_object_new_double_s(val, serialized);
			free(serialized);
		}
	}
	r = 0; /* success */
done:
	return r;
}
PARSER_Construct(Float)
{
	int r = 0;
	struct data_Float *data = (struct data_Float*) calloc(1, sizeof(struct data_Float));
	data->fmt_mode = FMT_AS_STRING;

	if(json == NULL)
		goto done;

	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcmp(key, "format")) {
			const char *fmtmode = json_object_get_string(val);
			if(!strcmp(fmtmode, "number")) {
				data->fmt_mode = FMT_AS_NUMBER;
			} else if(!strcmp(fmtmode, "string")) {
				data->fmt_mode = FMT_AS_STRING;
			} else {
				ln_errprintf(ctx, 0, "invalid value for float:format %s",
					fmtmode);
			}
		} else {
			ln_errprintf(ctx, 0, "invalid param for float: %s", key);
		}
		json_object_iter_next(&it);
	}

done:
	*pdata = data;
	return r;
}
PARSER_Destruct(Float)
{
	free(pdata);
}


struct data_HexNumber {
	uint64_t maxval;
	enum FMT_MODE fmt_mode;
};
/**
 * Parse a hex Number.
 * A hex number begins with 0x and contains only hex digits until the terminating
 * whitespace. Note that if a non-hex character is deteced inside the number string,
 * this is NOT considered to be a number.
 */
PARSER_Parse(HexNumber)
	const char *c;
	size_t i = *offs;
	struct data_HexNumber *const data = (struct data_HexNumber*) pdata;
	uint64_t maxval = data->maxval;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;

	if(c[i] != '0' || c[i+1] != 'x')
		goto done;

	uint64_t val = 0;
	for (i += 2 ; i < npb->strLen && isxdigit(c[i]); i++) {
		const char digit = tolower(c[i]);
		val *= 16;
		if(digit >= 'a' && digit <= 'f')
			val += digit - 'a' + 10;
		else
			val += digit - '0';
	}
	if (i == *offs || !isspace(c[i]))
		goto done;
	if(maxval > 0 && val > maxval) {
		LN_DBGPRINTF(npb->ctx, "hexnumber parser: val too large (max %" PRIu64
			     ", actual %" PRIu64 ")",
			     maxval, val);
		goto done;
	}
	
	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		if(data->fmt_mode == FMT_AS_STRING) {
			*value = json_object_new_string_len(npb->str+(*offs), *parsed);
		} else {
			*value = json_object_new_int64((int64_t) val);
		}
	}
	r = 0; /* success */
done:
	return r;
}
PARSER_Construct(HexNumber)
{
	int r = 0;
	struct data_HexNumber *data = (struct data_HexNumber*) calloc(1, sizeof(struct data_HexNumber));
	data->fmt_mode = FMT_AS_STRING;

	if(json == NULL)
		goto done;

	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcmp(key, "maxval")) {
			errno = 0;
			data->maxval = json_object_get_int64(val);
			if(errno != 0) {
				ln_errprintf(ctx, errno, "param 'maxval' must be integer but is: %s",
					 json_object_to_json_string(val));
			}
		} else if(!strcmp(key, "format")) {
			const char *fmtmode = json_object_get_string(val);
			if(!strcmp(fmtmode, "number")) {
				data->fmt_mode = FMT_AS_NUMBER;
			} else if(!strcmp(fmtmode, "string")) {
				data->fmt_mode = FMT_AS_STRING;
			} else {
				ln_errprintf(ctx, 0, "invalid value for hexnumber:format %s",
					fmtmode);
			}
		} else {
			ln_errprintf(ctx, 0, "invalid param for hexnumber: %s", key);
		}
		json_object_iter_next(&it);
	}

done:
	*pdata = data;
	return r;
}
PARSER_Destruct(HexNumber)
{
	free(pdata);
}


/**
 * Parse a kernel timestamp.
 * This is a fixed format, see
 * https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/kernel/printk/printk.c?id=refs/tags/v4.0#n1011
 * This is the code that generates it:
 * sprintf(buf, "[%5lu.%06lu] ",  (unsigned long)ts, rem_nsec / 1000);
 * We accept up to 12 digits for ts, everything above that for sure is
 * no timestamp.
 */
#define LEN_KERNEL_TIMESTAMP 14
PARSER_Parse(KernelTimestamp)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;

	i = *offs;
	if(c[i] != '[' || i+LEN_KERNEL_TIMESTAMP > npb->strLen
	   || !myisdigit(c[i+1])
	   || !myisdigit(c[i+2])
	   || !myisdigit(c[i+3])
	   || !myisdigit(c[i+4])
	   || !myisdigit(c[i+5])
	   )
		goto done;
	i += 6;
	for(int j = 0 ; j < 7 && i < npb->strLen && myisdigit(c[i]) ; )
		++i, ++j;	/* just scan */

	if(i >= npb->strLen || c[i] != '.')
		goto done;

	++i; /* skip over '.' */

	if( i+7 > npb->strLen
	   || !myisdigit(c[i+0])
	   || !myisdigit(c[i+1])
	   || !myisdigit(c[i+2])
	   || !myisdigit(c[i+3])
	   || !myisdigit(c[i+4])
	   || !myisdigit(c[i+5])
	   || c[i+6] != ']'
	   )
		goto done;
	i += 7;

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}

/**
 * Parse whitespace.
 * This parses all whitespace until the first non-whitespace character
 * is found. This is primarily a tool to skip to the next "word" if
 * the exact number of whitspace characters (and type of whitespace)
 * is not known. The current parsing position MUST be on a whitspace,
 * else the parser does not match.
 * This parser is also a forward-compatibility tool for the upcoming
 * slsa (simple log structure analyser) tool.
 */
PARSER_Parse(Whitespace)
	const char *c;
	size_t i = *offs;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;

	if(!isspace(c[i]))
		goto done;

	for (i++ ; i < npb->strLen && isspace(c[i]); i++);
	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}


/**
 * Parse a word.
 * A word is a SP-delimited entity. The parser always works, except if
 * the offset is position on a space upon entry.
 */
PARSER_Parse(Word)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	/* search end of word */
	while(i < npb->strLen && c[i] != ' ')
		i++;

	if(i == *offs)
		goto done;

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}


struct data_StringTo {
	const char *toFind;
	size_t len;
};
/**
 * Parse everything up to a specific string.
 * swisskid, 2015-01-21
 */
PARSER_Parse(StringTo)
	const char *c;
	size_t i, j, m;
	int chkstr;
	struct data_StringTo *const data = (struct data_StringTo*) pdata;
	const char *const toFind = data->toFind;
	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;
	chkstr = 0;

	/* Total hunt for letter */
	while(chkstr == 0 && i < npb->strLen ) {
	    i++;
	    if(c[i] == toFind[0]) {
		/* Found the first letter, now find the rest of the string */
		j = 1;
		m = i+1;
		while(m < npb->strLen && j < data->len ) {
			if(c[m] != toFind[j])
				break;
			if(j == data->len - 1) { /* full match? */
				chkstr = 1;
				break;
			}
			j++;
			m++;
		}
	    }
	}
	if(i == *offs || i == npb->strLen || chkstr != 1)
		goto done;

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}

PARSER_Construct(StringTo)
{
	int r = 0;
	struct data_StringTo *data = (struct data_StringTo*) calloc(1, sizeof(struct data_StringTo));
	struct json_object *ed;

	if(json_object_object_get_ex(json, "extradata", &ed) == 0) {
		ln_errprintf(ctx, 0, "string-to type needs 'extradata' parameter");
		r = LN_BADCONFIG ;
		goto done;
	}
	data->toFind = strdup(json_object_get_string(ed));
	data->len = strlen(data->toFind);

	*pdata = data;
done:
	if(r != 0)
		free(data);
	return r;
}
PARSER_Destruct(StringTo)
{
	struct data_StringTo *data = (struct data_StringTo*) pdata;
	free((void*)data->toFind);
	free(pdata);
}

/**
 * Parse a alphabetic word.
 * A alpha word is composed of characters for which isalpha returns true.
 * The parser dones if there is no alpha character at all.
 */
PARSER_Parse(Alpha)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	/* search end of word */
	while(i < npb->strLen && isalpha(c[i]))
		i++;

	if(i == *offs) {
		goto done;
	}

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}


struct data_CharTo {
	char *term_chars;
	size_t n_term_chars;
	char *data_for_display;
};
/**
 * Parse everything up to a specific character.
 * The character must be the only char inside extra data passed to the parser.
 * It is considered a format error if
 * a) the to-be-parsed buffer is already positioned on the terminator character
 * b) there is no terminator until the end of the buffer
 * In those cases, the parsers declares itself as not being successful, in all
 * other cases a string is extracted.
 */
PARSER_Parse(CharTo)
	size_t i;
	struct data_CharTo *const data = (struct data_CharTo*) pdata;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	i = *offs;

	/* search end of word */
	int found = 0;
	while(i < npb->strLen && !found) {
		for(size_t j = 0 ; j < data->n_term_chars ; ++j) {
			if(npb->str[i] == data->term_chars[j]) {
				found = 1;
				break;
			}
		}
		if(!found)
			++i;
	}

	if(i == *offs || i == npb->strLen || !found)
		goto done;

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0;
done:
	return r;
}
PARSER_Construct(CharTo)
{
	int r = 0;
	LN_DBGPRINTF(ctx, "in parser_construct charTo");
	struct data_CharTo *data = (struct data_CharTo*) calloc(1, sizeof(struct data_CharTo));
	struct json_object *ed;

	if(json_object_object_get_ex(json, "extradata", &ed) == 0) {
		ln_errprintf(ctx, 0, "char-to type needs 'extradata' parameter");
		r = LN_BADCONFIG ;
		goto done;
	}
	data->term_chars = strdup(json_object_get_string(ed));
	data->n_term_chars = strlen(data->term_chars);
	*pdata = data;
done:
	if(r != 0)
		free(data);
	return r;
}
PARSER_DataForDisplay(CharTo)
{
	struct data_CharTo *data = (struct data_CharTo*) pdata;
	if(data->data_for_display == NULL) {
		data->data_for_display = malloc(8+data->n_term_chars+2);
		if(data->data_for_display != NULL) {
			memcpy(data->data_for_display, "char-to{", 8);
			size_t i, j;
			for(j = 0, i = 8 ; j < data->n_term_chars ; ++j, ++i) {
				data->data_for_display[i] = data->term_chars[j];
			}
			data->data_for_display[i++] = '}';
			data->data_for_display[i] = '\0';
		}
	}
	return (data->data_for_display == NULL ) ? "malloc error" : data->data_for_display;
}
PARSER_Destruct(CharTo)
{
	struct data_CharTo *const data = (struct data_CharTo*) pdata;
	free(data->data_for_display);
	free(data->term_chars);
	free(pdata);
}



struct data_Literal {
	const char *lit;
	const char *json_conf;
};
/**
 * Parse a specific literal.
 */
PARSER_Parse(Literal)
	struct data_Literal *const data = (struct data_Literal*) pdata;
	const char *const lit = data->lit;
	size_t i = *offs;
	size_t j;

	for(j = 0 ; i < npb->strLen ; ++j) {
		if(lit[j] != npb->str[i])
			break;
		++i;
	}

	*parsed = j; /* we must always return how far we parsed! */
	if(lit[j] == '\0') {
		if(value != NULL) {
			*value = json_object_new_string_len(npb->str+(*offs), *parsed);
		}
		r = 0;
	}
	return r;
}
PARSER_DataForDisplay(Literal)
{
	struct data_Literal *data = (struct data_Literal*) pdata;
	return data->lit;
}
PARSER_JsonConf(Literal)
{
	struct data_Literal *data = (struct data_Literal*) pdata;
	return data->json_conf;
}
PARSER_Construct(Literal)
{
	int r = 0;
	struct data_Literal *data = (struct data_Literal*) calloc(1, sizeof(struct data_Literal));
	struct json_object *text;

	if(json_object_object_get_ex(json, "text", &text) == 0) {
		ln_errprintf(ctx, 0, "literal type needs 'text' parameter");
		r = LN_BADCONFIG ;
		goto done;
	}
	data->lit = strdup(json_object_get_string(text));
	data->json_conf = strdup(json_object_to_json_string(json));

	*pdata = data;
done:
	if(r != 0)
		free(data);
	return r;
}
PARSER_Destruct(Literal)
{
	struct data_Literal *data = (struct data_Literal*) pdata;
	free((void*)data->lit);
	free((void*)data->json_conf);
	free(pdata);
}
/* for path compaction, we need a special handler to combine two
 * literal data elements.
 */
int
ln_combineData_Literal(void *const porg, void *const padd)
{
	struct data_Literal *const __restrict__ org = porg;
	struct data_Literal *const __restrict__ add = padd;
	int r = 0;
	const size_t len = strlen(org->lit);
	const size_t add_len = strlen(add->lit);
	char *const newlit = (char*)realloc((void*)org->lit, len+add_len+1);
	CHKN(newlit);
	org->lit = newlit;
	memcpy((char*)org->lit+len, add->lit, add_len+1);
done:	return r;
}


struct data_CharSeparated {
	char *term_chars;
	size_t n_term_chars;
};
/**
 * Parse everything up to a specific character, or up to the end of string.
 * The character must be the only char inside extra data passed to the parser.
 * This parser always returns success.
 * By nature of the parser, it is required that end of string or the separator
 * follows this field in rule.
 */
PARSER_Parse(CharSeparated)
	struct data_CharSeparated *const data = (struct data_CharSeparated*) pdata;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	i = *offs;

	/* search end of word */
	int found = 0;
	while(i < npb->strLen && !found) {
		for(size_t j = 0 ; j < data->n_term_chars ; ++j) {
			if(npb->str[i] == data->term_chars[j]) {
				found = 1;
				break;
			}
		}
		if(!found)
			++i;
	}

	/* success, persist */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
	return r;
}
PARSER_Construct(CharSeparated)
{
	int r = 0;
	struct data_CharSeparated *data = (struct data_CharSeparated*) calloc(1, sizeof(struct data_CharSeparated));
	struct json_object *ed;

	if(json_object_object_get_ex(json, "extradata", &ed) == 0) {
		ln_errprintf(ctx, 0, "char-separated type needs 'extradata' parameter");
		r = LN_BADCONFIG ;
		goto done;
	}

	data->term_chars = strdup(json_object_get_string(ed));
	data->n_term_chars = strlen(data->term_chars);
	*pdata = data;
done:
	if(r != 0)
		free(data);
	return r;
}
PARSER_Destruct(CharSeparated)
{
	struct data_CharSeparated *const data = (struct data_CharSeparated*) pdata;
	free(data->term_chars);
	free(pdata);
}


/**
 * Just get everything till the end of string.
 */
PARSER_Parse(Rest)
	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);

	/* silence the warning about unused variable */
	(void)npb->str;
	/* success, persist */
	*parsed = npb->strLen - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0;
	return r;
}

/**
 * Parse a possibly quoted string. In this initial implementation, escaping of the quote
 * char is not supported. A quoted string is one start starts with a double quote,
 * has some text (not containing double quotes) and ends with the first double
 * quote character seen. The extracted string does NOT include the quote characters.
 * swisskid, 2015-01-21
 */
PARSER_Parse(OpQuotedString)
	const char *c;
	size_t i;
	char *cstr = NULL;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	if(c[i] != '"') {
		while(i < npb->strLen && c[i] != ' ')
			i++;

		if(i == *offs)
			goto done;

		/* success, persist */
		*parsed = i - *offs;
		/* create JSON value to save quoted string contents */
		CHKN(cstr = strndup((char*)c + *offs, *parsed));
	} else {
	    ++i;

	    /* search end of string */
	    while(i < npb->strLen && c[i] != '"')
		    i++;

	    if(i == npb->strLen || c[i] != '"')
		    goto done;
	    /* success, persist */
	    *parsed = i + 1 - *offs; /* "eat" terminal double quote */
	    /* create JSON value to save quoted string contents */
	    CHKN(cstr = strndup((char*)c + *offs + 1, *parsed - 2));
	}
	CHKN(*value = json_object_new_string(cstr));

	r = 0; /* success */
done:
	free(cstr);
	return r;
}


/**
 * Parse a quoted string. In this initial implementation, escaping of the quote
 * char is not supported. A quoted string is one start starts with a double quote,
 * has some text (not containing double quotes) and ends with the first double
 * quote character seen. The extracted string does NOT include the quote characters.
 * rgerhards, 2011-01-14
 */
PARSER_Parse(QuotedString)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;
	if(i + 2 > npb->strLen)
		goto done;	/* needs at least 2 characters */

	if(c[i] != '"')
		goto done;
	++i;

	/* search end of string */
	while(i < npb->strLen && c[i] != '"')
		i++;

	if(i == npb->strLen || c[i] != '"')
		goto done;

	/* success, persist */
	*parsed = i + 1 - *offs; /* "eat" terminal double quote */
	/* create JSON value to save quoted string contents */
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}


/**
 * Parse an ISO date, that is YYYY-MM-DD (exactly this format).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 * rgerhards, 2011-01-14
 */
PARSER_Parse(ISODate)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	if(*offs+10 > npb->strLen)
		goto done;	/* if it is not 10 chars, it can't be an ISO date */

	/* year */
	if(!myisdigit(c[i])) goto done;
	if(!myisdigit(c[i+1])) goto done;
	if(!myisdigit(c[i+2])) goto done;
	if(!myisdigit(c[i+3])) goto done;
	if(c[i+4] != '-') goto done;
	/* month */
	if(c[i+5] == '0') {
		if(c[i+6] < '1' || c[i+6] > '9') goto done;
	} else if(c[i+5] == '1') {
		if(c[i+6] < '0' || c[i+6] > '2') goto done;
	} else {
		goto done;
	}
	if(c[i+7] != '-') goto done;
	/* day */
	if(c[i+8] == '0') {
		if(c[i+9] < '1' || c[i+9] > '9') goto done;
	} else if(c[i+8] == '1' || c[i+8] == '2') {
		if(!myisdigit(c[i+9])) goto done;
	} else if(c[i+8] == '3') {
		if(c[i+9] != '0' && c[i+9] != '1') goto done;
	} else {
		goto done;
	}

	/* success, persist */
	*parsed = 10;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a Cisco interface spec. Sample for such a spec are:
 *   outside:192.168.52.102/50349
 *   inside:192.168.1.15/56543 (192.168.1.112/54543)
 *   outside:192.168.1.13/50179 (192.168.1.13/50179)(LOCAL\some.user)
 *   outside:192.168.1.25/41850(LOCAL\RG-867G8-DEL88D879BBFFC8)
 *   inside:192.168.1.25/53 (192.168.1.25/53) (some.user)
 *   192.168.1.15/0(LOCAL\RG-867G8-DEL88D879BBFFC8)
 * From this, we conclude the format is:
 *   [interface:]ip/port [SP (ip2/port2)] [[SP](username)]
 * In order to match, this syntax must start on a non-whitespace char
 * other than colon.
 */
PARSER_Parse(CiscoInterfaceSpec)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	if(c[i] == ':' || isspace(c[i])) goto done;

	/* first, check if we have an interface. We do this by trying
	 * to detect if we have an IP. If we have, obviously no interface
	 * is present. Otherwise, we check if we have a valid interface.
	 */
	int bHaveInterface = 0;
	size_t idxInterface = 0;
	size_t lenInterface = 0;
	int bHaveIP = 0;
	size_t lenIP;
	size_t idxIP = i;
	if(ln_v2_parseIPv4(npb, &i, NULL, &lenIP, NULL) == 0) {
		bHaveIP = 1;
		i += lenIP - 1; /* position on delimiter */
	} else {
		idxInterface = i;
		while(i < npb->strLen) {
			if(isspace(c[i])) goto done;
			if(c[i] == ':')
				break;
			++i;
		}
		lenInterface = i - idxInterface;
		bHaveInterface = 1;
	}
	if(i == npb->strLen) goto done;
	++i; /* skip over colon */

	/* we now utilize our other parser helpers */
	if(!bHaveIP) {
		idxIP = i;
		if(ln_v2_parseIPv4(npb, &i, NULL, &lenIP, NULL) != 0) goto done;
		i += lenIP;
	}
	if(i == npb->strLen || c[i] != '/') goto done;
	++i; /* skip slash */
	const size_t idxPort = i;
	size_t lenPort;
	if(ln_v2_parseNumber(npb, &i, NULL, &lenPort, NULL) != 0) goto done;
	i += lenPort;
	if(i == npb->strLen) goto success;

	/* check if optional second ip/port is present
	 * We assume we must at least have 5 chars [" (::1)"]
	 */
	int bHaveIP2 = 0;
	size_t idxIP2 = 0, lenIP2 = 0;
	size_t idxPort2 = 0, lenPort2 = 0;
	if(i+5 < npb->strLen && c[i] == ' ' && c[i+1] == '(') {
		size_t iTmp = i+2; /* skip over " (" */
		idxIP2 = iTmp;
		if(ln_v2_parseIPv4(npb, &iTmp, NULL, &lenIP2, NULL) == 0) {
			iTmp += lenIP2;
			if(i < npb->strLen || c[iTmp] == '/') {
				++iTmp; /* skip slash */
				idxPort2 = iTmp;
				if(ln_v2_parseNumber(npb, &iTmp, NULL, &lenPort2, NULL) == 0) {
					iTmp += lenPort2;
					if(iTmp < npb->strLen && c[iTmp] == ')') {
						i = iTmp + 1; /* match, so use new index */
						bHaveIP2 = 1;
					}
				}
			}
		}
	}

	/* check if optional username is present
	 * We assume we must at least have 3 chars ["(n)"]
	 */
	int bHaveUser = 0;
	size_t idxUser = 0;
	size_t lenUser = 0;
	if(   (i+2 < npb->strLen && c[i] == '(' && !isspace(c[i+1]) )
	   || (i+3 < npb->strLen && c[i] == ' ' && c[i+1] == '(' && !isspace(c[i+2])) ) {
		idxUser = i + ((c[i] == ' ') ? 2 : 1); /* skip [SP]'(' */
		size_t iTmp = idxUser;
		while(iTmp < npb->strLen && !isspace(c[iTmp]) && c[iTmp] != ')')
			++iTmp; /* just scan */
		if(iTmp < npb->strLen && c[iTmp] == ')') {
			i = iTmp + 1; /* we have a match, so use new index */
			bHaveUser = 1;
			lenUser = iTmp - idxUser;
		}
	}

	/* all done, save data */
	if(value == NULL)
		goto success;

	CHKN(*value = json_object_new_object());
	json_object *json;
	if(bHaveInterface) {
		CHKN(json = json_object_new_string_len(c+idxInterface, lenInterface));
		json_object_object_add_ex(*value, "interface", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	}
	CHKN(json = json_object_new_string_len(c+idxIP, lenIP));
	json_object_object_add_ex(*value, "ip", json, JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	CHKN(json = json_object_new_string_len(c+idxPort, lenPort));
	json_object_object_add_ex(*value, "port", json, JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	if(bHaveIP2) {
		CHKN(json = json_object_new_string_len(c+idxIP2, lenIP2));
		json_object_object_add_ex(*value, "ip2", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
		CHKN(json = json_object_new_string_len(c+idxPort2, lenPort2));
		json_object_object_add_ex(*value, "port2", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	}
	if(bHaveUser) {
		CHKN(json = json_object_new_string_len(c+idxUser, lenUser));
		json_object_object_add_ex(*value, "user", json,
			JSON_C_OBJECT_ADD_KEY_IS_NEW|JSON_C_OBJECT_KEY_IS_CONSTANT);
	}

success: /* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */
done:
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		*value = NULL; /* to be on the save side */
	}
	return r;
}

/**
 * Parse a duration. A duration is similar to a timestamp, except that
 * it tells about time elapsed. As such, hours can be larger than 23
 * and hours may also be specified by a single digit (this, for example,
 * is commonly done in Cisco software).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 */
PARSER_Parse(Duration)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	/* hour is a bit tricky */
	if(!myisdigit(c[i])) goto done;
	++i;
	if(myisdigit(c[i]))
		++i;
	if(c[i] == ':')
		++i;
	else
		goto done;

	if(i+5 > npb->strLen)
		goto done;/* if it is not 5 chars from here, it can't be us */

	if(c[i] < '0' || c[i] > '5') goto done;
	if(!myisdigit(c[i+1])) goto done;
	if(c[i+2] != ':') goto done;
	if(c[i+3] < '0' || c[i+3] > '5') goto done;
	if(!myisdigit(c[i+4])) goto done;

	/* success, persist */
	*parsed = (i + 5) - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a timestamp in 24hr format (exactly HH:MM:SS).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 * rgerhards, 2011-01-14
 */
PARSER_Parse(Time24hr)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	if(*offs+8 > npb->strLen)
		goto done;	/* if it is not 8 chars, it can't be us */

	/* hour */
	if(c[i] == '0' || c[i] == '1') {
		if(!myisdigit(c[i+1])) goto done;
	} else if(c[i] == '2') {
		if(c[i+1] < '0' || c[i+1] > '3') goto done;
	} else {
		goto done;
	}
	/* TODO: the code below is a duplicate of 24hr parser - create common function */
	if(c[i+2] != ':') goto done;
	if(c[i+3] < '0' || c[i+3] > '5') goto done;
	if(!myisdigit(c[i+4])) goto done;
	if(c[i+5] != ':') goto done;
	if(c[i+6] < '0' || c[i+6] > '5') goto done;
	if(!myisdigit(c[i+7])) goto done;

	/* success, persist */
	*parsed = 8;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}

/**
 * Parse a timestamp in 12hr format (exactly HH:MM:SS).
 * Note: we do manual loop unrolling -- this is fast AND efficient.
 * TODO: the code below is a duplicate of 24hr parser - create common function?
 * rgerhards, 2011-01-14
 */
PARSER_Parse(Time12hr)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	c = npb->str;
	i = *offs;

	if(*offs+8 > npb->strLen)
		goto done;	/* if it is not 8 chars, it can't be us */

	/* hour */
	if(c[i] == '0') {
		if(!myisdigit(c[i+1])) goto done;
	} else if(c[i] == '1') {
		if(c[i+1] < '0' || c[i+1] > '2') goto done;
	} else {
		goto done;
	}
	if(c[i+2] != ':') goto done;
	if(c[i+3] < '0' || c[i+3] > '5') goto done;
	if(!myisdigit(c[i+4])) goto done;
	if(c[i+5] != ':') goto done;
	if(c[i+6] < '0' || c[i+6] > '5') goto done;
	if(!myisdigit(c[i+7])) goto done;

	/* success, persist */
	*parsed = 8;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}


/* helper to IPv4 address parser, checks the next set of numbers.
 * Syntax 1 to 3 digits, value together not larger than 255.
 * @param[in] npb->str parse buffer
 * @param[in/out] offs offset into buffer, updated if successful
 * @return 0 if OK, 1 otherwise
 */
static int
chkIPv4AddrByte(npb_t *const npb, size_t *offs)
{
	int val = 0;
	int r = 1;	/* default: done -- simplifies things */
	const char *c;
	size_t i = *offs;

	c = npb->str;
	if(i == npb->strLen || !myisdigit(c[i]))
		goto done;
	val = c[i++] - '0';
	if(i < npb->strLen && myisdigit(c[i])) {
		val = val * 10 + c[i++] - '0';
		if(i < npb->strLen && myisdigit(c[i]))
			val = val * 10 + c[i++] - '0';
	}
	if(val > 255)	/* cannot be a valid IP address byte! */
		goto done;

	*offs = i;
	r = 0;
done:
	return r;
}

/**
 * Parser for IPv4 addresses.
 */
PARSER_Parse(IPv4)
	const char *c;
	size_t i;

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	i = *offs;
	if(i + 7 > npb->strLen) {
		/* IPv4 addr requires at least 7 characters */
		goto done;
	}
	c = npb->str;

	/* byte 1*/
	if(chkIPv4AddrByte(npb, &i) != 0) goto done;
	if(i == npb->strLen || c[i++] != '.') goto done;
	/* byte 2*/
	if(chkIPv4AddrByte(npb, &i) != 0) goto done;
	if(i == npb->strLen || c[i++] != '.') goto done;
	/* byte 3*/
	if(chkIPv4AddrByte(npb, &i) != 0) goto done;
	if(i == npb->strLen || c[i++] != '.') goto done;
	/* byte 4 - we do NOT need any char behind it! */
	if(chkIPv4AddrByte(npb, &i) != 0) goto done;

	/* if we reach this point, we found a valid IP address */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}


/* skip past the IPv6 address block, parse pointer is set to
 * first char after the block. Returns an error if already at end
 * of string.
 * @param[in] npb->str parse buffer
 * @param[in/out] offs offset into buffer, updated if successful
 * @return 0 if OK, 1 otherwise
 */
static int
skipIPv6AddrBlock(npb_t *const npb,
	size_t *const __restrict__ offs)
{
	int j;
	if(*offs == npb->strLen)
		return 1;

	for(j = 0 ; j < 4  && *offs+j < npb->strLen && isxdigit(npb->str[*offs+j]) ; ++j)
		/*just skip*/ ;

	*offs += j;
	return 0;
}

/**
 * Parser for IPv6 addresses.
 * Bases on RFC4291 Section 2.2. The address must be followed
 * by whitespace or end-of-string, else it is not considered
 * a valid address. This prevents false positives.
 */
PARSER_Parse(IPv6)
	const char *c;
	size_t i;
	size_t beginBlock; /* last block begin in case we need IPv4 parsing */
	int hasIPv4 = 0;
	int nBlocks = 0; /* how many blocks did we already have? */
	int bHad0Abbrev = 0; /* :: already used? */

	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	i = *offs;
	if(i + 2 > npb->strLen) {
		/* IPv6 addr requires at least 2 characters ("::") */
		goto done;
	}
	c = npb->str;

	/* check that first block is non-empty */
	if(! ( isxdigit(c[i]) || (c[i] == ':' && c[i+1] == ':') ) )
		goto done;

	/* try for all potential blocks plus one more (so we see errors!) */
	for(int j = 0 ; j < 9 ; ++j) {
		beginBlock = i;
		if(skipIPv6AddrBlock(npb, &i) != 0) goto done;
		nBlocks++;
		if(i == npb->strLen) goto chk_ok;
		if(isspace(c[i])) goto chk_ok;
		if(c[i] == '.'){ /* IPv4 processing! */
			hasIPv4 = 1;
			break;
		}
		if(c[i] != ':') goto done;
		i++; /* "eat" ':' */
		if(i == npb->strLen) goto chk_ok;
		/* check for :: */
		if(bHad0Abbrev) {
			if(c[i] == ':') goto done;
		} else {
			if(c[i] == ':') {
				bHad0Abbrev = 1;
				++i;
				if(i == npb->strLen) goto chk_ok;
			}
		}
	}

	if(hasIPv4) {
		size_t ipv4_parsed;
		--nBlocks;
		/* prevent pure IPv4 address to be recognized */
		if(beginBlock == *offs) goto done;
		i = beginBlock;
		if(ln_v2_parseIPv4(npb, &i, NULL, &ipv4_parsed, NULL) != 0)
			goto done;
		i += ipv4_parsed;
	}

chk_ok:	/* we are finished parsing, check if things are ok */
	if(nBlocks > 8) goto done;
	if(bHad0Abbrev && nBlocks >= 8) goto done;
	/* now check if trailing block is missing. Note that i is already
	 * on next character, so we need to go two back. Two are always
	 * present, else we would not reach this code here.
	 */
	if(c[i-1] == ':' && c[i-2] != ':') goto done;

	/* if we reach this point, we found a valid IP address */
	*parsed = i - *offs;
	if(value != NULL) {
		*value = json_object_new_string_len(npb->str+(*offs), *parsed);
	}
	r = 0; /* success */
done:
	return r;
}

/* check if a char is valid inside a name of the iptables motif.
 * We try to keep the set as slim as possible, because the iptables
 * parser may otherwise create a very broad match (especially the
 * inclusion of simple words like "DF" cause grief here).
 * Note: we have taken the permitted set from iptables log samples.
 * Report bugs if we missed some additional rules.
 */
static inline int
isValidIPTablesNameChar(const char c)
{
	/* right now, upper case only is valid */
	return ('A' <= c && c <= 'Z') ? 1 : 0;
}

/* helper to iptables parser, parses out a a single name=value pair
 */
static int
parseIPTablesNameValue(npb_t *const npb,
	size_t *const __restrict__ offs,
	struct json_object *const __restrict__ valroot)
{
	int r = LN_WRONGPARSER;
	size_t i = *offs;
	char *name = NULL;

	const size_t iName = i;
	while(i < npb->strLen && isValidIPTablesNameChar(npb->str[i]))
		++i;
	if(i == iName || (i < npb->strLen && npb->str[i] != '=' && npb->str[i] != ' '))
		goto done; /* no name at all! */

	const ssize_t lenName = i - iName;

	ssize_t iVal = -1;
	size_t lenVal = i - iVal;
	if(i < npb->strLen && npb->str[i] != ' ') {
		/* we have a real value (not just a flag name like "DF") */
		++i; /* skip '=' */
		iVal = i;
		while(i < npb->strLen && !isspace(npb->str[i]))
			++i;
		lenVal = i - iVal;
	}

	/* parsing OK */
	*offs = i;
	r = 0;

	if(valroot == NULL)
		goto done;

	CHKN(name = malloc(lenName+1));
	memcpy(name, npb->str+iName, lenName);
	name[lenName] = '\0';
	json_object *json;
	if(iVal == -1) {
		json = NULL;
	} else {
		CHKN(json = json_object_new_string_len(npb->str+iVal, lenVal));
	}
	json_object_object_add(valroot, name, json);
done:
	free(name);
	return r;
}

/**
 * Parser for iptables logs (the structured part).
 * This parser is named "v2-iptables" because of a traditional
 * parser named "iptables", which we do not want to replace, at
 * least right now (we may re-think this before the first release).
 * For performance reasons, this works in two stages. In the first
 * stage, we only detect if the motif is correct. The second stage is
 * only called when we know it is. In it, we go once again over the
 * message again and actually extract the data. This is done because
 * data extraction is relatively expensive and in most cases we will
 * have much more frequent mismatches than matches.
 * Note that this motif must have at least one field, otherwise it
 * could detect things that are not iptables to be it. Further limits
 * may be imposed in the future as we see additional need.
 * added 2015-04-30 rgerhards
 */
PARSER_Parse(v2IPTables)
	size_t i = *offs;
	int nfields = 0;

	/* stage one */
	while(i < npb->strLen) {
		CHKR(parseIPTablesNameValue(npb, &i, NULL));
		++nfields;
		/* exactly one SP is permitted between fields */
		if(i < npb->strLen && npb->str[i] == ' ')
			++i;
	}

	if(nfields < 2) {
		FAIL(LN_WRONGPARSER);
	}

	/* success, persist */
	*parsed = i - *offs;
	r = 0;

	/* stage two */
	if(value == NULL)
		goto done;

	i = *offs;
	CHKN(*value = json_object_new_object());
	while(i < npb->strLen) {
		CHKR(parseIPTablesNameValue(npb, &i, *value));
		while(i < npb->strLen && isspace(npb->str[i]))
			++i;
	}

done:
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		*value = NULL;
	}
	return r;
}

/**
 * Parse JSON. This parser tries to find JSON data inside a message.
 * If it finds valid JSON, it will extract it. Extra data after the
 * JSON is permitted.
 * Note: the json-c JSON parser treats whitespace after the actual
 * json to be part of the json. So in essence, any whitespace is
 * processed by this parser. We use the same semantics to keep things
 * neatly in sync. If json-c changes for some reason or we switch to
 * an alternate json lib, we probably need to be sure to keep that
 * behaviour, and probably emulate it.
 * added 2015-04-28 by rgerhards, v1.1.2
 */
PARSER_Parse(JSON)
	const size_t i = *offs;
	struct json_tokener *tokener = NULL;

	if(npb->str[i] != '{' && npb->str[i] != ']') {
		/* this can't be json, see RFC4627, Sect. 2
		 * see this bug in json-c:
		 * https://github.com/json-c/json-c/issues/181
		 * In any case, it's better to do this quick check,
		 * even if json-c did not have the bug because this
		 * check here is much faster than calling the parser.
		 */
		goto done;
	}

	if((tokener = json_tokener_new()) == NULL)
		goto done;

	struct json_object *const json
		= json_tokener_parse_ex(tokener, npb->str+i, (int) (npb->strLen - i));

	if(json == NULL)
		goto done;

	/* success, persist */
	*parsed =  (i + tokener->char_offset) - *offs;
	r = 0; /* success */

	if(value == NULL) {
		json_object_put(json);
	} else {
		*value = json;
	}

done:
	if(tokener != NULL)
		json_tokener_free(tokener);
	return r;
}


/* check if a char is valid inside a name of a NameValue list
 * The set of valid characters may be extended if there is good
 * need to do so. We have selected the current set carefully, but
 * may have overlooked some cases.
 */
static inline int
isValidNameChar(const char c)
{
	return (isalnum(c)
		|| c == '.'
		|| c == '_'
		|| c == '-'
		) ? 1 : 0;
}
/* helper to NameValue parser, parses out a a single name=value pair
 *
 * name must be alphanumeric characters, value must be non-whitespace
 * characters, if quoted than with symmetric quotes. Supported formats
 * - name=value
 * - name="value"
 * - name='value'
 * Note "name=" is valid and means a field with empty value.
 * TODO: so far, quote characters are not permitted WITHIN quoted values.
 */
static int
parseNameValue(npb_t *const npb,
	size_t *const __restrict__ offs,
	struct json_object *const __restrict__ valroot)
{
	int r = LN_WRONGPARSER;
	size_t i = *offs;
	char *name = NULL;

	const size_t iName = i;
	while(i < npb->strLen && isValidNameChar(npb->str[i]))
		++i;
	if(i == iName || npb->str[i] != '=')
		goto done; /* no name at all! */

	const size_t lenName = i - iName;
	++i; /* skip '=' */

	const size_t iVal = i;
	while(i < npb->strLen && !isspace(npb->str[i]))
		++i;
	const size_t lenVal = i - iVal;

	/* parsing OK */
	*offs = i;
	r = 0;

	if(valroot == NULL)
		goto done;

	CHKN(name = malloc(lenName+1));
	memcpy(name, npb->str+iName, lenName);
	name[lenName] = '\0';
	json_object *json;
	CHKN(json = json_object_new_string_len(npb->str+iVal, lenVal));
	json_object_object_add(valroot, name, json);
done:
	free(name);
	return r;
}

/**
 * Parse CEE syslog.
 * This essentially is a JSON parser, with additional restrictions:
 * The message must start with "@cee:" and json must immediately follow (whitespace permitted).
 * after the JSON, there must be no other non-whitespace characters.
 * In other words: the message must consist of a single JSON object,
 * only.
 * added 2015-04-28 by rgerhards, v1.1.2
 */
PARSER_Parse(CEESyslog)
	size_t i = *offs;
	struct json_tokener *tokener = NULL;
	struct json_object *json = NULL;

	if(npb->strLen < i + 7  || /* "@cee:{}" is minimum text */
	   npb->str[i]   != '@' ||
	   npb->str[i+1] != 'c' ||
	   npb->str[i+2] != 'e' ||
	   npb->str[i+3] != 'e' ||
	   npb->str[i+4] != ':')
	   	goto done;
	
	/* skip whitespace */
	for(i += 5 ; i < npb->strLen && isspace(npb->str[i]) ; ++i)
		/* just skip */;

	if(i == npb->strLen || npb->str[i] != '{')
		goto done;
		/* note: we do not permit arrays in CEE mode */

	if((tokener = json_tokener_new()) == NULL)
		goto done;

	json = json_tokener_parse_ex(tokener, npb->str+i, (int) (npb->strLen - i));

	if(json == NULL)
		goto done;

	if(i + tokener->char_offset != npb->strLen)
		goto done;

	/* success, persist */
	*parsed =  npb->strLen;
	r = 0; /* success */

	if(value != NULL) {
		*value = json;
		json = NULL; /* do NOT free below! */
	}

done:
	if(tokener != NULL)
		json_tokener_free(tokener);
	if(json != NULL)
		json_object_put(json);
	return r;
}

/**
 * Parser for name/value pairs.
 * On entry must point to alnum char. All following chars must be
 * name/value pairs delimited by whitespace up until the end of string.
 * For performance reasons, this works in two stages. In the first
 * stage, we only detect if the motif is correct. The second stage is
 * only called when we know it is. In it, we go once again over the
 * message again and actually extract the data. This is done because
 * data extraction is relatively expensive and in most cases we will
 * have much more frequent mismatches than matches.
 * added 2015-04-25 rgerhards
 */
PARSER_Parse(NameValue)
	size_t i = *offs;

	/* stage one */
	while(i < npb->strLen) {
		CHKR(parseNameValue(npb, &i, NULL));
		while(i < npb->strLen && isspace(npb->str[i]))
			++i;
	}

	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */

	/* stage two */
	if(value == NULL)
		goto done;

	i = *offs;
	CHKN(*value = json_object_new_object());
	while(i < npb->strLen) {
		CHKR(parseNameValue(npb, &i, *value));
		while(i < npb->strLen && isspace(npb->str[i]))
			++i;
	}

	/* TODO: fix mem leak if alloc json fails */

done:
	return r;
}

/**
 * Parse a MAC layer address.
 * The standard (IEEE 802) format for printing MAC-48 addresses in
 * human-friendly form is six groups of two hexadecimal digits,
 * separated by hyphens (-) or colons (:), in transmission order
 * (e.g. 01-23-45-67-89-ab or 01:23:45:67:89:ab ).
 * This form is also commonly used for EUI-64.
 * from: http://en.wikipedia.org/wiki/MAC_address
 *
 * This parser must start on a hex digit.
 * added 2015-05-04 by rgerhards, v1.1.2
 */
PARSER_Parse(MAC48)
	size_t i = *offs;
	char delim;

	if(npb->strLen < i + 17 || /* this motif has exactly 17 characters */
	   !isxdigit(npb->str[i]) ||
	   !isxdigit(npb->str[i+1])
	   )
		FAIL(LN_WRONGPARSER);

	if(npb->str[i+2] == ':')
		delim = ':';
	else if(npb->str[i+2] == '-')
		delim = '-';
	else
		FAIL(LN_WRONGPARSER);

	/* first byte ok */
	if(!isxdigit(npb->str[i+3])  ||
	   !isxdigit(npb->str[i+4])  ||
	   npb->str[i+5] != delim    || /* 2nd byte ok */
	   !isxdigit(npb->str[i+6])  ||
	   !isxdigit(npb->str[i+7])  ||
	   npb->str[i+8] != delim    || /* 3rd byte ok */
	   !isxdigit(npb->str[i+9])  ||
	   !isxdigit(npb->str[i+10]) ||
	   npb->str[i+11] != delim   || /* 4th byte ok */
	   !isxdigit(npb->str[i+12]) ||
	   !isxdigit(npb->str[i+13]) ||
	   npb->str[i+14] != delim   || /* 5th byte ok */
	   !isxdigit(npb->str[i+15]) ||
	   !isxdigit(npb->str[i+16])    /* 6th byte ok */
	   )
		FAIL(LN_WRONGPARSER);

	/* success, persist */
	*parsed = 17;
	r = 0; /* success */

	if(value != NULL) {
		CHKN(*value = json_object_new_string_len(npb->str+i, 17));
	}

done:
	return r;
}


/* This parses the extension value and updates the index
 * to point to the end of it.
 */
static int
cefParseExtensionValue(npb_t *const npb,
	size_t *__restrict__ iEndVal)
{
	int r = 0;
	size_t i = *iEndVal;
	size_t iLastWordBegin;
	/* first find next unquoted equal sign and record begin of
	 * last word in front of it - this is the actual end of the
	 * current name/value pair and the begin of the next one.
	 */
	int hadSP = 0;
	int inEscape = 0;
	for(iLastWordBegin = 0 ; i < npb->strLen ; ++i) {
		if(inEscape) {
			if(npb->str[i] != '=' &&
			   npb->str[i] != '\\' &&
			   npb->str[i] != 'r' &&
			   npb->str[i] != 'n')
			FAIL(LN_WRONGPARSER);
			inEscape = 0;
		} else {
			if(npb->str[i] == '=') {
				break;
			} else if(npb->str[i] == '\\') {
				inEscape = 1;
			} else if(npb->str[i] == ' ') {
				hadSP = 1;
			} else {
				if(hadSP) {
					iLastWordBegin = i;
					hadSP = 0;
				}
			}
		}
	}

	/* Note: iLastWordBegin can never be at offset zero, because
	 * the CEF header starts there!
	 */
	if(i < npb->strLen) {
		*iEndVal = (iLastWordBegin == 0) ? i : iLastWordBegin - 1;
	} else {
		*iEndVal = i;
	}
done:
	return r;
}

/* must be positioned on first char of name, returns index
 * of end of name.
 * Note: ArcSight violates the CEF spec ifself: they generate
 * leading underscores in their extension names, which are
 * definetly not alphanumeric. We still accept them...
 * They also seem to use dots.
 */
static int
cefParseName(npb_t *const npb,
	size_t *const __restrict__ i)
{
	int r = 0;
	while(*i < npb->strLen && npb->str[*i] != '=') {
		if(!(isalnum(npb->str[*i]) || npb->str[*i] == '_' || npb->str[*i] == '.'))
			FAIL(LN_WRONGPARSER);
		++(*i);
	}
done:
	return r;
}

/* parse CEF extensions. They are basically name=value
 * pairs with the ugly exception that values may contain
 * spaces but need NOT to be quoted. Thankfully, at least
 * names are specified as being alphanumeric without spaces
 * in them. So we must add a lookahead parser to check if
 * a word is a name (and thus the begin of a new pair) or
 * not. This is done by subroutines.
 */
static int
cefParseExtensions(npb_t *const npb,
	size_t *const __restrict__ offs,
	json_object *const __restrict__ jroot)
{
	int r = 0;
	size_t i = *offs;
	size_t iName, lenName;
	size_t iValue, lenValue;
	char *name = NULL;
	char *value = NULL;

	while(i < npb->strLen) {
		while(i < npb->strLen && npb->str[i] == ' ')
			++i;
		iName = i;
		CHKR(cefParseName(npb, &i));
		if(i+1 >= npb->strLen || npb->str[i] != '=')
			FAIL(LN_WRONGPARSER);
		lenName = i - iName;
		++i; /* skip '=' */

		iValue = i;
		CHKR(cefParseExtensionValue(npb, &i));
		lenValue = i - iValue;

		++i; /* skip past value */

		if(jroot != NULL) {
			CHKN(name = malloc(sizeof(char) * (lenName + 1)));
			memcpy(name, npb->str+iName, lenName);
			name[lenName] = '\0';
			CHKN(value = malloc(sizeof(char) * (lenValue + 1)));
			/* copy value but escape it */
			size_t iDst = 0;
			for(size_t iSrc = 0 ; iSrc < lenValue ; ++iSrc) {
				if(npb->str[iValue+iSrc] == '\\') {
					++iSrc; /* we know the next char must exist! */
					switch(npb->str[iValue+iSrc]) {
					case '=':	value[iDst] = '=';
							break;
					case 'n':	value[iDst] = '\n';
							break;
					case 'r':	value[iDst] = '\r';
							break;
					case '\\':	value[iDst] = '\\';
							break;
					default:	break;
					}
				} else {
					value[iDst] = npb->str[iValue+iSrc];
				}
				++iDst;
			}
			value[iDst] = '\0';
			json_object *json;
			CHKN(json = json_object_new_string(value));
			json_object_object_add(jroot, name, json);
			free(name); name = NULL;
			free(value); value = NULL;
		}
	}

	*offs = npb->strLen; /* this parser consume everything or fails */

done:
	free(name);
	free(value);
	return r;
}

/* gets a CEF header field. Must be positioned on the
 * first char after the '|' in front of field.
 * Note that '|' may be escaped as "\|", which also means
 * we need to supprot "\\" (see CEF spec for details).
 * We return the string in *val, if val is non-null. In
 * that case we allocate memory that the caller must free.
 * This is necessary because there are potentially escape
 * sequences inside the string.
 */
static int
cefGetHdrField(npb_t *const npb,
	size_t *const __restrict__ offs,
	char **val)
{
	int r = 0;
	size_t i = *offs;
	assert(npb->str[i] != '|');
	while(i < npb->strLen && npb->str[i] != '|') {
		if(npb->str[i] == '\\') {
			++i; /* skip esc char */
			if(npb->str[i] != '\\' && npb->str[i] != '|')
				FAIL(LN_WRONGPARSER);
		}
		++i; /* scan to next delimiter */
	}

	if(npb->str[i] != '|')
		FAIL(LN_WRONGPARSER);

	const size_t iBegin = *offs;
	/* success, persist */
	*offs = i + 1;

	if(val == NULL) {
		r = 0;
		goto done;
	}
	
	const size_t len = i - iBegin;
	CHKN(*val = malloc(len + 1));
	size_t iDst = 0;
	for(size_t iSrc = 0 ; iSrc < len ; ++iSrc) {
		if(npb->str[iBegin+iSrc] == '\\')
			++iSrc; /* we already checked above that this is OK! */
		(*val)[iDst++] = npb->str[iBegin+iSrc];
	}
	(*val)[iDst] = 0;
	r = 0;
done:
	return r;
}

/**
 * Parser for ArcSight Common Event Format (CEF) version 0.
 * added 2015-05-05 by rgerhards, v1.1.2
 */
PARSER_Parse(CEF)
	size_t i = *offs;
	char *vendor = NULL;
	char *product = NULL;
	char *version = NULL;
	char *sigID = NULL;
	char *name = NULL;
	char *severity = NULL;

	/* minumum header: "CEF:0|x|x|x|x|x|x|" -->  17 chars */
	if(npb->strLen < i + 17 ||
	   npb->str[i]   != 'C' ||
	   npb->str[i+1] != 'E' ||
	   npb->str[i+2] != 'F' ||
	   npb->str[i+3] != ':' ||
	   npb->str[i+4] != '0' ||
	   npb->str[i+5] != '|'
	   )	FAIL(LN_WRONGPARSER);
	
	i += 6; /* position on '|' */

	CHKR(cefGetHdrField(npb, &i, (value == NULL) ? NULL : &vendor));
	CHKR(cefGetHdrField(npb, &i, (value == NULL) ? NULL : &product));
	CHKR(cefGetHdrField(npb, &i, (value == NULL) ? NULL : &version));
	CHKR(cefGetHdrField(npb, &i, (value == NULL) ? NULL : &sigID));
	CHKR(cefGetHdrField(npb, &i, (value == NULL) ? NULL : &name));
	CHKR(cefGetHdrField(npb, &i, (value == NULL) ? NULL : &severity));
	++i; /* skip over terminal '|' */

	/* OK, we now know we have a good header. Now, we need
	 * to process extensions.
	 * This time, we do NOT pre-process the extension, but rather
	 * persist them directly to JSON. This is contrary to other
	 * parsers, but as the CEF header is pretty unique, this time
	 * it is exteremely unlike we will get a no-match during
	 * extension processing. Even if so, nothing bad happens, as
	 * the extracted data is discarded. But the regular case saves
	 * us processing time and complexity. The only time when we
	 * cannot directly process it is when the caller asks us not
	 * to persist the data. So this must be handled differently.
	 */
	 size_t iBeginExtensions = i;
	 CHKR(cefParseExtensions(npb, &i, NULL));

	/* success, persist */
	*parsed = i - *offs;
	r = 0; /* success */

	if(value != NULL) {
		CHKN(*value = json_object_new_object());
		json_object *json;
		CHKN(json = json_object_new_string(vendor));
		json_object_object_add(*value, "DeviceVendor", json);
		CHKN(json = json_object_new_string(product));
		json_object_object_add(*value, "DeviceProduct", json);
		CHKN(json = json_object_new_string(version));
		json_object_object_add(*value, "DeviceVersion", json);
		CHKN(json = json_object_new_string(sigID));
		json_object_object_add(*value, "SignatureID", json);
		CHKN(json = json_object_new_string(name));
		json_object_object_add(*value, "Name", json);
		CHKN(json = json_object_new_string(severity));
		json_object_object_add(*value, "Severity", json);

		json_object *jext;
		CHKN(jext = json_object_new_object());
		json_object_object_add(*value, "Extensions", jext);

		i = iBeginExtensions;
		cefParseExtensions(npb, &i, jext);
	}

done:
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		value = NULL;
	}
	free(vendor);
	free(product);
	free(version);
	free(sigID);
	free(name);
	free(severity);
	return r;
}

/**
 * Parser for Checkpoint LEA on-disk format.
 * added 2015-06-18 by rgerhards, v1.1.2
 */
PARSER_Parse(CheckpointLEA)
	size_t i = *offs;
	size_t iName, lenName;
	size_t iValue, lenValue;
	int foundFields = 0;
	char *name = NULL;
	char *val = NULL;

	while(i < npb->strLen) {
		while(i < npb->strLen && npb->str[i] == ' ') /* skip leading SP */
			++i;
		if(i == npb->strLen) { /* OK if just trailing space */
			if(foundFields == 0)
				FAIL(LN_WRONGPARSER);
			break; /* we are done with the loop, all processed */
		} else {
			++foundFields;
		}
		iName = i;
		/* TODO: do a stricter check? ... but we don't have a spec */
		while(i < npb->strLen && npb->str[i] != ':') {
			++i;
		}
		if(i+1 >= npb->strLen || npb->str[i] != ':')
			FAIL(LN_WRONGPARSER);
		lenName = i - iName;
		++i; /* skip ':' */

		while(i < npb->strLen && npb->str[i] == ' ') /* skip leading SP */
			++i;
		iValue = i;
		while(i < npb->strLen && npb->str[i] != ';') {
			++i;
		}
		if(i+1 > npb->strLen || npb->str[i] != ';')
			FAIL(LN_WRONGPARSER);
		lenValue = i - iValue;
		++i; /* skip ';' */

		if(value != NULL) {
			CHKN(name = malloc(sizeof(char) * (lenName + 1)));
			memcpy(name, npb->str+iName, lenName);
			name[lenName] = '\0';
			CHKN(val = malloc(sizeof(char) * (lenValue + 1)));
			memcpy(val, npb->str+iValue, lenValue);
			val[lenValue] = '\0';
			if(*value == NULL)
				CHKN(*value = json_object_new_object());
			json_object *json;
			CHKN(json = json_object_new_string(val));
			json_object_object_add(*value, name, json);
			free(name); name = NULL;
			free(val); val = NULL;
		}
	}

	/* success, persist */
	*parsed =  i - *offs;
	r = 0; /* success */

done:
	free(name);
	free(val);
	if(r != 0 && value != NULL && *value != NULL) {
		json_object_put(*value);
		value = NULL;
	}
	return r;
}


/* helper to repeat parser constructor: checks that dot field name
 * is only present if there is one field inside the "parser" list.
 * returns 1 if ok, 0 otherwise.
 */
static int
chkNoDupeDotInParserDefs(ln_ctx ctx, struct json_object *parsers)
{
	int r = 1;
	int nParsers = 0;
	int nDots = 0;
	if(json_object_get_type(parsers) == json_type_array) {
		const int maxparsers = json_object_array_length(parsers);
		for(int i = 0 ; i < maxparsers ; ++i) {
			++nParsers;
			struct json_object *const parser
				= json_object_array_get_idx(parsers, i);
			struct json_object *fname;
			json_object_object_get_ex(parser, "name", &fname);
			if(fname != NULL) {
				if(!strcmp(json_object_get_string(fname), "."))
					++nDots;
			}
		}
	}
	if(nParsers > 1 && nDots > 0) {
		ln_errprintf(ctx, 0, "'repeat' parser supports dot name only "
			"if single parser is used in 'parser' part, invalid "
			"construct: %s", json_object_get_string(parsers));
			r = 0;
	}
	return r;
}

/**
 * "repeat" special parser.
 */
PARSER_Parse(Repeat)
	struct data_Repeat *const data = (struct data_Repeat*) pdata;
	struct ln_pdag *endNode = NULL;
	size_t strtoffs = *offs;
	size_t lastKnownGood = strtoffs;
	struct json_object *json_arr = NULL;
	const size_t parsedTo_save = npb->parsedTo;

	do {
		struct json_object *parsed_value = json_object_new_object();
		r = ln_normalizeRec(npb, data->parser, strtoffs, 1,
				    parsed_value, &endNode);
		strtoffs = npb->parsedTo;
		LN_DBGPRINTF(npb->ctx, "repeat parser returns %d, parsed %zu, json: %s",
			r, npb->parsedTo, json_object_to_json_string(parsed_value));

		if(r != 0) {
			json_object_put(parsed_value);
			if(data->permitMismatchInParser) {
				strtoffs = lastKnownGood; /* go back to final match */
				LN_DBGPRINTF(npb->ctx, "mismatch in repeat, "
					"parse ptr back to %zd", strtoffs);
				goto success;
			} else {
				goto done;
			}
		}

		if(json_arr == NULL) {
			json_arr = json_object_new_array();
		}

		/* check for name=".", which means we need to place the
		 * value only into to array. As we do not have direct
		 * access to the key, we loop over our result as a work-
		 * around.
		 */
		struct json_object *toAdd = parsed_value;
		struct json_object_iterator it = json_object_iter_begin(parsed_value);
		struct json_object_iterator itEnd = json_object_iter_end(parsed_value);
		while (!json_object_iter_equal(&it, &itEnd)) {
			const char *key = json_object_iter_peek_name(&it);
			struct json_object *const val = json_object_iter_peek_value(&it);
			if(key[0] == '.' && key[1] == '\0') {
				json_object_get(val); /* inc refcount! */
				toAdd = val;
			}
			json_object_iter_next(&it);
		}

		json_object_array_add(json_arr, toAdd);
		if(toAdd != parsed_value)
			json_object_put(parsed_value);
		LN_DBGPRINTF(npb->ctx, "arr: %s", json_object_to_json_string(json_arr));

		/* now check if we shall continue */
		npb->parsedTo = 0;
		lastKnownGood = strtoffs; /* record pos in case of fail in while */
		r = ln_normalizeRec(npb, data->while_cond, strtoffs, 1, NULL, &endNode);
		LN_DBGPRINTF(npb->ctx, "repeat while returns %d, parsed %zu",
			r, npb->parsedTo);
		if(r == 0)
			strtoffs = npb->parsedTo;
	} while(r == 0);

success:
	/* success, persist */
	*parsed = strtoffs - *offs;
	if(value == NULL) {
		json_object_put(json_arr);
	} else {
		*value = json_arr;
	}
	npb->parsedTo = parsedTo_save;
	r = 0; /* success */
done:
	if(r != 0 && json_arr != NULL) {
		json_object_put(json_arr);
	}
	return r;
}
PARSER_Construct(Repeat)
{
	int r = 0;
	struct data_Repeat *data = (struct data_Repeat*) calloc(1, sizeof(struct data_Repeat));
	struct ln_pdag *endnode; /* we need this fo ln_pdagAddParser, which updates its param! */

	if(json == NULL)
		goto done;

	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcmp(key, "parser")) {
			if(chkNoDupeDotInParserDefs(ctx, val) != 1) {
				r = LN_BADCONFIG;
				goto done;
			}
			endnode = data->parser = ln_newPDAG(ctx);
			json_object_get(val); /* prevent free in pdagAddParser */
			CHKR(ln_pdagAddParser(ctx, &endnode, val));
			endnode->flags.isTerminal = 1;
		} else if(!strcmp(key, "while")) {
			endnode = data->while_cond = ln_newPDAG(ctx);
			json_object_get(val); /* prevent free in pdagAddParser */
			CHKR(ln_pdagAddParser(ctx, &endnode, val));
			endnode->flags.isTerminal = 1;
		} else if(!strcasecmp(key, "option.permitMismatchInParser")) {
			data->permitMismatchInParser = json_object_get_boolean(val);
		} else {
			ln_errprintf(ctx, 0, "invalid param for hexnumber: %s",
				 json_object_to_json_string(val));
		}
		json_object_iter_next(&it);
	}

done:
	if(data->parser == NULL || data->while_cond == NULL) {
		ln_errprintf(ctx, 0, "repeat parser needs 'parser','while' parameters");
		ln_destructRepeat(ctx, data);
		r = LN_BADCONFIG;
	} else {
		*pdata = data;
	}
	return r;
}
PARSER_Destruct(Repeat)
{
	struct data_Repeat *const data = (struct data_Repeat*) pdata;
	if(data->parser != NULL)
		ln_pdagDelete(data->parser);
	if(data->while_cond != NULL)
		ln_pdagDelete(data->while_cond);
	free(pdata);
}


/* string escaping modes */
#define ST_ESC_NONE 0
#define ST_ESC_BACKSLASH 1
#define ST_ESC_DOUBLE 2
#define ST_ESC_BOTH 3
struct data_String {
	enum { ST_QUOTE_AUTO = 0, ST_QUOTE_NONE = 1, ST_QUOTE_REQD = 2 }
		quoteMode;
	struct {
		unsigned strip_quotes : 1;
		unsigned esc_md : 2;
	} flags;
	char qchar_begin;
	char qchar_end;
	char perm_chars[256]; // TODO: make this bit-wise, so we need  only 32 bytes
};
static inline void
stringSetPermittedChar(struct data_String *const data, char c, int val)
{
#if 0
	const int i = (unsigned) c / 8;
	const int shft = (unsigned) c % 8;
	const unsigned mask = ~(1 << shft);
	perm_arr[i] = (perm_arr[i] & (0xff
#endif
	data->perm_chars[(unsigned)c] = val;
}
static inline int
stringIsPermittedChar(struct data_String *const data, char c)
{
	return data->perm_chars[(unsigned)c];
}
static void
stringAddPermittedCharArr(struct data_String *const data,
	const char *const optval)
{
	const size_t nchars = strlen(optval);
	for(size_t i = 0 ; i < nchars ; ++i) {
		stringSetPermittedChar(data, optval[i], 1);
	}
}
static void
stringAddPermittedFromTo(struct data_String *const data,
	const unsigned char from,
	const unsigned char to)
{
	assert(from <= to);
	for(size_t i = from ; i <= to ; ++i) {
		stringSetPermittedChar(data, (char) i, 1);
	}
}
static inline void
stringAddPermittedChars(struct data_String *const data,
	struct json_object *const val)
{
	const char *const optval = json_object_get_string(val);
	if(optval == NULL)
		return;
	stringAddPermittedCharArr(data, optval);
}
static void
stringAddPermittedCharsViaArray(ln_ctx ctx, struct data_String *const data,
	struct json_object *const arr)
{
	const int nelem = json_object_array_length(arr);
	for(int i = 0 ; i < nelem ; ++i) {
		struct json_object *const elem
			= json_object_array_get_idx(arr, i);
		struct json_object_iterator it = json_object_iter_begin(elem);
		struct json_object_iterator itEnd = json_object_iter_end(elem);
		while (!json_object_iter_equal(&it, &itEnd)) {
			const char *key = json_object_iter_peek_name(&it);
			struct json_object *const val = json_object_iter_peek_value(&it);
			if(!strcasecmp(key, "chars")) {
				stringAddPermittedChars(data, val);
			} else if(!strcasecmp(key, "class")) {
				const char *const optval = json_object_get_string(val);
				if(!strcasecmp(optval, "digit")) {
					stringAddPermittedCharArr(data, "0123456789");
				} else if(!strcasecmp(optval, "hexdigit")) {
					stringAddPermittedCharArr(data, "0123456789aAbBcCdDeEfF");
				} else if(!strcasecmp(optval, "alpha")) {
					stringAddPermittedFromTo(data, 'a', 'z');
					stringAddPermittedFromTo(data, 'A', 'Z');
				} else if(!strcasecmp(optval, "alnum")) {
					stringAddPermittedCharArr(data, "0123456789");
					stringAddPermittedFromTo(data, 'a', 'z');
					stringAddPermittedFromTo(data, 'A', 'Z');
				} else {
					ln_errprintf(ctx, 0, "invalid character class '%s'",
						optval);
				}
			}
		json_object_iter_next(&it);
		}
	}
}
/**
 * generic string parser
 */
PARSER_Parse(String)
	assert(npb->str != NULL);
	assert(offs != NULL);
	assert(parsed != NULL);
	struct data_String *const data = (struct data_String*) pdata;
	size_t i = *offs;
	int bHaveQuotes = 0;
	int bHadEndQuote = 0;
	int bHadEscape = 0;

	if(i == npb->strLen) goto done;

	if((data->quoteMode == ST_QUOTE_AUTO) && (npb->str[i] == data->qchar_begin)) {
		bHaveQuotes = 1;
		++i;
	} else if(data->quoteMode == ST_QUOTE_REQD) {
		if(npb->str[i] == data->qchar_begin) {
			bHaveQuotes = 1;
			++i;
		} else {
			goto done;
		}
	}

	/* scan string */
	while(i < npb->strLen) {
		if(bHaveQuotes) {
			if(npb->str[i] == data->qchar_end) {
				if(data->flags.esc_md == ST_ESC_DOUBLE
				   || data->flags.esc_md == ST_ESC_BOTH) {
					/* may be escaped, need to check! */
					if(i+1 < npb->strLen
					   && npb->str[i+1] == data->qchar_end) {
						bHadEscape = 1;
					   	++i;
					} else { /* not escaped -> terminal */
						bHadEndQuote = 1;
						break;
					}
				} else {
					bHadEndQuote = 1;
					break;
				}
			}
		}

		if(   npb->str[i] == '\\'
		   && i+1 < npb->strLen
		   && (data->flags.esc_md == ST_ESC_BACKSLASH
		       || data->flags.esc_md == ST_ESC_BOTH) ) {
			bHadEscape = 1;
			i++; /* skip esc char */
		}

		/* terminating conditions */
		if(!bHaveQuotes && npb->str[i] == ' ')
			break;
		if(!stringIsPermittedChar(data, npb->str[i]))
			break;
		i++;
	}

	if(bHaveQuotes && !bHadEndQuote)
		goto done;

	if(i == *offs)
		goto done;

	const size_t trmChkIdx = (bHaveQuotes) ? i+1 : i;
	if(npb->str[trmChkIdx] != ' ' && trmChkIdx != npb->strLen)
		goto done;

	/* success, persist */
	*parsed = i - *offs;
	if(bHadEndQuote)
		++(*parsed); /* skip quote */
	if(value != NULL) {
		size_t strt;
		size_t len;
		if(bHaveQuotes && data->flags.strip_quotes) {
			strt = *offs + 1;
			len = *parsed - 2; /* del begin AND end quote! */
		} else {
			strt = *offs;
			len = *parsed;
		}
		char *const cstr = strndup(npb->str+strt, len);
		CHKN(cstr);
		if(bHadEscape) {
			/* need to post-process string... */
			for(size_t j = 0 ; cstr[j] != '\0' ; j++) {
				if( (
				        cstr[j] == data->qchar_end
				     && cstr[j+1] == data->qchar_end
				     && (data->flags.esc_md == ST_ESC_DOUBLE
				         || data->flags.esc_md == ST_ESC_BOTH)
				    )
				  ||
				    (
				        cstr[j] == '\\'
				     && (data->flags.esc_md == ST_ESC_BACKSLASH
				         || data->flags.esc_md == ST_ESC_BOTH)
				    ) ) {
					/* we need to remove the escape character */
					memmove(cstr+j, cstr+j+1, len-j);
				}
			}
		}
		*value = json_object_new_string(cstr);
		free(cstr);
	}
	r = 0; /* success */
done:
	return r;
}

PARSER_Construct(String)
{
	int r = 0;
	struct data_String *const data = (struct data_String*) calloc(1, sizeof(struct data_String));
	data->quoteMode = ST_QUOTE_AUTO;
	data->flags.strip_quotes = 1;
	data->flags.esc_md = ST_ESC_BOTH;
	data->qchar_begin = '"';
	data->qchar_end = '"';
	memset(data->perm_chars, 0xff, sizeof(data->perm_chars));
	
	struct json_object_iterator it = json_object_iter_begin(json);
	struct json_object_iterator itEnd = json_object_iter_end(json);
	while (!json_object_iter_equal(&it, &itEnd)) {
		const char *key = json_object_iter_peek_name(&it);
		struct json_object *const val = json_object_iter_peek_value(&it);
		if(!strcasecmp(key, "quoting.mode")) {
			const char *const optval = json_object_get_string(val);
			if(!strcasecmp(optval, "auto")) {
				data->quoteMode = ST_QUOTE_AUTO;
			} else if(!strcasecmp(optval, "none")) {
				data->quoteMode = ST_QUOTE_NONE;
			} else if(!strcasecmp(optval, "required")) {
				data->quoteMode = ST_QUOTE_REQD;
			} else {
				ln_errprintf(ctx, 0, "invalid quoting.mode for string parser: %s",
					optval);
				r = LN_BADCONFIG;
				goto done;
			}
		} else if(!strcasecmp(key, "quoting.escape.mode")) {
			const char *const optval = json_object_get_string(val);
			if(!strcasecmp(optval, "none")) {
				data->flags.esc_md = ST_ESC_NONE;
			} else if(!strcasecmp(optval, "backslash")) {
				data->flags.esc_md = ST_ESC_BACKSLASH;
			} else if(!strcasecmp(optval, "double")) {
				data->flags.esc_md = ST_ESC_DOUBLE;
			} else if(!strcasecmp(optval, "both")) {
				data->flags.esc_md = ST_ESC_BOTH;
			} else {
				ln_errprintf(ctx, 0, "invalid quoting.escape.mode for string "
					"parser: %s", optval);
				r = LN_BADCONFIG;
				goto done;
			}
		} else if(!strcasecmp(key, "quoting.char.begin")) {
			const char *const optval = json_object_get_string(val);
			if(strlen(optval) != 1) {
				ln_errprintf(ctx, 0, "quoting.char.begin must "
					"be exactly one character but is: '%s'", optval);
				r = LN_BADCONFIG;
				goto done;
			}
			data->qchar_begin = *optval;
		} else if(!strcasecmp(key, "quoting.char.end")) {
			const char *const optval = json_object_get_string(val);
			if(strlen(optval) != 1) {
				ln_errprintf(ctx, 0, "quoting.char.end must "
					"be exactly one character but is: '%s'", optval);
				r = LN_BADCONFIG;
				goto done;
			}
			data->qchar_end = *optval;
		} else if(!strcasecmp(key, "matching.permitted")) {
			memset(data->perm_chars, 0x00, sizeof(data->perm_chars));
			if(json_object_is_type(val, json_type_string)) {
				stringAddPermittedChars(data, val);
			} else if(json_object_is_type(val, json_type_array)) {
				stringAddPermittedCharsViaArray(ctx, data, val);
			} else {
				ln_errprintf(ctx, 0, "matching.permitted is invalid "
					"object type, given as '%s",
					 json_object_to_json_string(val));
			}
		} else {
			ln_errprintf(ctx, 0, "invalid param for hexnumber: %s",
				 json_object_to_json_string(val));
		}
		json_object_iter_next(&it);
	}

	if(data->quoteMode == ST_QUOTE_NONE)
		data->flags.esc_md = ST_ESC_NONE;
	*pdata = data;
done:
	if(r != 0) {
		free(data);
	}
	return r;
}
PARSER_Destruct(String)
{
	free(pdata);
}
