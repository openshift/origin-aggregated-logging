/**********************************************************************

  time.c -

  $Author$
  created at: Tue Dec 28 14:31:59 JST 1993

  Copyright (C) 1993-2007 Yukihiro Matsumoto

**********************************************************************/

#include "ruby.h"

#include <time.h>
#if defined(HAVE_SYS_TIME_H)
#include <sys/time.h>
#endif

/* rbtime_timespec_new */
typedef uint64_t WIDEVALUE;
typedef WIDEVALUE wideval_t;

#ifndef HAVE_RB_TIME_TIMESPEC_NEW
# if defined(PACKED_STRUCT_UNALIGNED) /* 2.2 */
PACKED_STRUCT_UNALIGNED(struct vtm {
    VALUE year;	/* 2000 for example.  Integer. */
    VALUE subsecx;     /* 0 <= subsecx < TIME_SCALE.  possibly Rational. */
    VALUE utc_offset;  /* -3600 as -01:00 for example.  possibly Rational. */
    const char *zone;  /* "JST", "EST", "EDT", etc. */
    uint16_t yday : 9; /* 1..366 */
    uint8_t mon : 4;   /* 1..12 */
    uint8_t mday : 5;  /* 1..31 */
    uint8_t hour : 5;  /* 0..23 */
    uint8_t min : 6;   /* 0..59 */
    uint8_t sec : 6;   /* 0..60 */
    uint8_t wday : 3;  /* 0:Sunday, 1:Monday, ..., 6:Saturday 7:init */
    uint8_t isdst : 2; /* 0:StandardTime 1:DayLightSavingTime 3:init */
});
PACKED_STRUCT_UNALIGNED(struct time_object {
    wideval_t timew; /* time_t value * TIME_SCALE.  possibly Rational. */
    struct vtm vtm;
    uint8_t gmt : 3; /* 0:utc 1:localtime 2:fixoff 3:init */
    uint8_t tm_got : 1;
});
# else /* 2.0.0~2.1 */
struct vtm {
    VALUE year; /* 2000 for example.  Integer. */
    int mon; /* 1..12 */
    int mday; /* 1..31 */
    int hour; /* 0..23 */
    int min; /* 0..59 */
    int sec; /* 0..60 */
    VALUE subsecx; /* 0 <= subsecx < TIME_SCALE.  possibly Rational. */
    VALUE utc_offset; /* -3600 as -01:00 for example.  possibly Rational. */
    int wday; /* 0:Sunday, 1:Monday, ..., 6:Saturday */
    int yday; /* 1..366 */
    int isdst; /* 0:StandardTime 1:DayLightSavingTime */
    const char *zone; /* "JST", "EST", "EDT", etc. */
};
struct time_object {
    wideval_t timew; /* time_t value * TIME_SCALE.  possibly Rational. */
    struct vtm vtm;
    int gmt; /* 0:localtime 1:utc 2:fixoff */
    int tm_got;
};
# endif

VALUE
rb_time_timespec_new(const struct timespec *ts, int offset)
{
    VALUE obj = rb_time_nano_new(ts->tv_sec, ts->tv_nsec);
    if (-86400 < offset && offset <  86400) { /* fixoff */
	struct time_object *tobj;
	tobj = DATA_PTR(obj);
	tobj->tm_got = 0;
	tobj->gmt = 2;
	tobj->vtm.utc_offset = INT2FIX(offset);
	tobj->vtm.zone = NULL;
    }
    else if (offset == INT_MAX) { /* localtime */
    }
    else if (offset == INT_MAX-1) { /* UTC */
	struct time_object *tobj;
	tobj = DATA_PTR(obj);
	tobj->tm_got = 0;
	tobj->gmt = 1;
    }
    else {
	rb_raise(rb_eArgError, "utc_offset out of range");
    }

    return obj;
}
#endif

#ifndef RB_TIMESPEC_NOW
void
rb_timespec_now(struct timespec *ts)
{
#ifdef HAVE_CLOCK_GETTIME
    if (clock_gettime(CLOCK_REALTIME, ts) == -1) {
	rb_sys_fail("clock_gettime");
    }
#else
    {
	struct timeval tv;
	if (gettimeofday(&tv, 0) < 0) {
	    rb_sys_fail("gettimeofday");
	}
	ts->tv_sec = tv.tv_sec;
	ts->tv_nsec = tv.tv_usec * 1000;
    }
#endif
}
#endif

static struct tm *
rb_localtime_r(const time_t *t, struct tm *result)
{
#if defined __APPLE__ && defined __LP64__
    if (*t != (time_t)(int)*t) return NULL;
#endif
#ifdef HAVE_GMTIME_R
    result = localtime_r(t, result);
#else
    {
	struct tm *tmp = localtime(t);
	if (tmp) *result = *tmp;
    }
#endif
#if defined(HAVE_MKTIME) && defined(LOCALTIME_OVERFLOW_PROBLEM)
    if (result) {
        long gmtoff1 = 0;
        long gmtoff2 = 0;
        struct tm tmp = *result;
        time_t t2;
        t2 = mktime(&tmp);
#  if defined(HAVE_STRUCT_TM_TM_GMTOFF)
        gmtoff1 = result->tm_gmtoff;
        gmtoff2 = tmp.tm_gmtoff;
#  endif
        if (*t + gmtoff1 != t2 + gmtoff2)
            result = NULL;
    }
#endif
    return result;
}
#define LOCALTIME(tm, result) (tzset(),rb_localtime_r((tm), &(result)))

struct tm *
rb_gmtime_r(const time_t *t, struct tm *result)
{
#ifdef HAVE_GMTIME_R
    result = gmtime_r(t, result);
#else
    struct tm *tmp = gmtime(t);
    if (tmp) *result = *tmp;
#endif
#if defined(HAVE_TIMEGM) && defined(LOCALTIME_OVERFLOW_PROBLEM)
    if (result && *t != timegm(result)) {
	return NULL;
    }
#endif
    return result;
}
#define GMTIME(tm, result) rb_gmtime_r((tm), &(result))

struct tm *
localtime_with_gmtoff_zone(const time_t *t, struct tm *result, long *gmtoff,
			   const char **zone)
{
    struct tm tm;

    if (LOCALTIME(t, tm)) {
#if defined(HAVE_STRUCT_TM_TM_GMTOFF)
	*gmtoff = tm.tm_gmtoff;
#else
	struct tm *u, *l;
	long off;
	struct tm tmbuf;
	l = &tm;
	u = GMTIME(t, tmbuf);
	if (!u) return NULL;
	if (l->tm_year != u->tm_year)
	    off = l->tm_year < u->tm_year ? -1 : 1;
	else if (l->tm_mon != u->tm_mon)
	    off = l->tm_mon < u->tm_mon ? -1 : 1;
	else if (l->tm_mday != u->tm_mday)
	    off = l->tm_mday < u->tm_mday ? -1 : 1;
	else
	    off = 0;
	off = off * 24 + l->tm_hour - u->tm_hour;
	off = off * 60 + l->tm_min - u->tm_min;
	off = off * 60 + l->tm_sec - u->tm_sec;
	*gmtoff = off;
#endif

	*result = tm;
	return result;
    }
    return NULL;
}

#define NDIV(x,y) (-(-((x)+1)/(y))-1)
#define NMOD(x,y) ((y)-(-((x)+1)%(y))-1)
#define DIV(n,d) ((n)<0 ? NDIV((n),(d)) : (n)/(d))
#define MOD(n,d) ((n)<0 ? NMOD((n),(d)) : (n)%(d))

static int
leap_year_p(int y)
{
    return ((y % 4 == 0) && (y % 100 != 0)) || (y % 400 == 0);
}

static const int common_year_yday_offset[] = {
    -1,
    -1 + 31,
    -1 + 31 + 28,
    -1 + 31 + 28 + 31,
    -1 + 31 + 28 + 31 + 30,
    -1 + 31 + 28 + 31 + 30 + 31,
    -1 + 31 + 28 + 31 + 30 + 31 + 30,
    -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31,
    -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
    -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
    -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
    -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30
      /* 1    2    3    4    5    6    7    8    9    10   11 */
};
static const int leap_year_yday_offset[] = {
    -1,
    -1 + 31,
    -1 + 31 + 29,
    -1 + 31 + 29 + 31,
    -1 + 31 + 29 + 31 + 30,
    -1 + 31 + 29 + 31 + 30 + 31,
    -1 + 31 + 29 + 31 + 30 + 31 + 30,
    -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31,
    -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31,
    -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
    -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
    -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30
      /* 1    2    3    4    5    6    7    8    9    10   11 */
};

static const int common_year_days_in_month[] = {
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};
static const int leap_year_days_in_month[] = {
    31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

static int
calc_tm_yday(long tm_year, int tm_mon, int tm_mday)
{
    int tm_year_mod400 = (int)MOD(tm_year, 400);
    int tm_yday = tm_mday;

    if (leap_year_p(tm_year_mod400 + 1900))
        tm_yday += leap_year_yday_offset[tm_mon];
    else
        tm_yday += common_year_yday_offset[tm_mon];

    return tm_yday;
}

time_t
timegm_noleapsecond(struct tm *tm)
{
    long tm_year = tm->tm_year;
    int tm_yday = tm->tm_mday;
    if (leap_year_p(tm_year + 1900))
	tm_yday += leap_year_yday_offset[tm->tm_mon];
    else
	tm_yday += common_year_yday_offset[tm->tm_mon];

    /*
     *  `Seconds Since the Epoch' in SUSv3:
     *  tm_sec + tm_min*60 + tm_hour*3600 + tm_yday*86400 +
     *  (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 -
     *  ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400
     */
    return tm->tm_sec + tm->tm_min*60 + tm->tm_hour*3600 +
	   (time_t)(tm_yday +
		    (tm_year-70)*365 +
		    DIV(tm_year-69,4) -
		    DIV(tm_year-1,100) +
		    DIV(tm_year+299,400))*86400;
}

/* assume time_t is signed */
#define SIGNED_INTEGER_MAX(sint_type) \
  (sint_type) \
  ((((sint_type)1) << (sizeof(sint_type) * CHAR_BIT - 2)) | \
  ((((sint_type)1) << (sizeof(sint_type) * CHAR_BIT - 2)) - 1))
#define SIGNED_INTEGER_MIN(sint_type) (-SIGNED_INTEGER_MAX(sint_type)-1)
# define TIMET_MAX SIGNED_INTEGER_MAX(time_t)
# define TIMET_MIN SIGNED_INTEGER_MIN(time_t)
# define DEBUG_FIND_TIME_NUMGUESS_INC
# define DEBUG_REPORT_GUESSRANGE

static int
tmcmp(struct tm *a, struct tm *b)
{
    if (a->tm_year != b->tm_year)
        return a->tm_year < b->tm_year ? -1 : 1;
    else if (a->tm_mon != b->tm_mon)
        return a->tm_mon < b->tm_mon ? -1 : 1;
    else if (a->tm_mday != b->tm_mday)
        return a->tm_mday < b->tm_mday ? -1 : 1;
    else if (a->tm_hour != b->tm_hour)
        return a->tm_hour < b->tm_hour ? -1 : 1;
    else if (a->tm_min != b->tm_min)
        return a->tm_min < b->tm_min ? -1 : 1;
    else if (a->tm_sec != b->tm_sec)
        return a->tm_sec < b->tm_sec ? -1 : 1;
    else
        return 0;
}

const char *
find_time_t(struct tm *tptr, int utc_p, time_t *tp)
{
    time_t guess, guess0, guess_lo, guess_hi;
    struct tm *tm, tm0, tm_lo, tm_hi;
    int d;
    int find_dst;
    struct tm result;
    int status;
    int tptr_tm_yday;

#define GUESS(p) (DEBUG_FIND_TIME_NUMGUESS_INC (utc_p ? rb_gmtime_r((p), &result) : LOCALTIME((p), result)))

    guess_lo = TIMET_MIN;
    guess_hi = TIMET_MAX;

    find_dst = 0 < tptr->tm_isdst;

#if defined(HAVE_MKTIME)
    tm0 = *tptr;
    if (!utc_p && (guess = mktime(&tm0)) != -1) {
        tm = GUESS(&guess);
        if (tm && tmcmp(tptr, tm) == 0) {
            goto found;
        }
    }
#endif

    tm0 = *tptr;
    if (tm0.tm_mon < 0) {
	tm0.tm_mon = 0;
	tm0.tm_mday = 1;
	tm0.tm_hour = 0;
	tm0.tm_min = 0;
	tm0.tm_sec = 0;
    }
    else if (11 < tm0.tm_mon) {
	tm0.tm_mon = 11;
	tm0.tm_mday = 31;
	tm0.tm_hour = 23;
	tm0.tm_min = 59;
	tm0.tm_sec = 60;
    }
    else if (tm0.tm_mday < 1) {
	tm0.tm_mday = 1;
	tm0.tm_hour = 0;
	tm0.tm_min = 0;
	tm0.tm_sec = 0;
    }
    else if ((d = (leap_year_p(1900 + tm0.tm_year) ?
                   leap_year_days_in_month :
		   common_year_days_in_month)[tm0.tm_mon]) < tm0.tm_mday) {
	tm0.tm_mday = d;
	tm0.tm_hour = 23;
	tm0.tm_min = 59;
	tm0.tm_sec = 60;
    }
    else if (tm0.tm_hour < 0) {
	tm0.tm_hour = 0;
	tm0.tm_min = 0;
	tm0.tm_sec = 0;
    }
    else if (23 < tm0.tm_hour) {
	tm0.tm_hour = 23;
	tm0.tm_min = 59;
	tm0.tm_sec = 60;
    }
    else if (tm0.tm_min < 0) {
	tm0.tm_min = 0;
	tm0.tm_sec = 0;
    }
    else if (59 < tm0.tm_min) {
	tm0.tm_min = 59;
	tm0.tm_sec = 60;
    }
    else if (tm0.tm_sec < 0) {
	tm0.tm_sec = 0;
    }
    else if (60 < tm0.tm_sec) {
	tm0.tm_sec = 60;
    }

    DEBUG_REPORT_GUESSRANGE;
    guess0 = guess = timegm_noleapsecond(&tm0);
    tm = GUESS(&guess);
    if (tm) {
	d = tmcmp(tptr, tm);
	if (d == 0) { goto found; }
	if (d < 0) {
	    guess_hi = guess;
	    guess -= 24 * 60 * 60;
	}
	else {
	    guess_lo = guess;
	    guess += 24 * 60 * 60;
	}
        DEBUG_REPORT_GUESSRANGE;
	if (guess_lo < guess && guess < guess_hi && (tm = GUESS(&guess)) != NULL) {
	    d = tmcmp(tptr, tm);
	    if (d == 0) { goto found; }
	    if (d < 0)
		guess_hi = guess;
	    else
		guess_lo = guess;
            DEBUG_REPORT_GUESSRANGE;
	}
    }

    tm = GUESS(&guess_lo);
    if (!tm) goto error;
    d = tmcmp(tptr, tm);
    if (d < 0) goto out_of_range;
    if (d == 0) { guess = guess_lo; goto found; }
    tm_lo = *tm;

    tm = GUESS(&guess_hi);
    if (!tm) goto error;
    d = tmcmp(tptr, tm);
    if (d > 0) goto out_of_range;
    if (d == 0) { guess = guess_hi; goto found; }
    tm_hi = *tm;

    DEBUG_REPORT_GUESSRANGE;

    status = 1;

    while (guess_lo + 1 < guess_hi) {
        if (status == 0) {
          binsearch:
            guess = guess_lo / 2 + guess_hi / 2;
            if (guess <= guess_lo)
                guess = guess_lo + 1;
            else if (guess >= guess_hi)
                guess = guess_hi - 1;
            status = 1;
        }
        else {
            if (status == 1) {
                time_t guess0_hi = timegm_noleapsecond(&tm_hi);
                guess = guess_hi - (guess0_hi - guess0);
                if (guess == guess_hi) /* hh:mm:60 tends to cause this condition. */
                    guess--;
                status = 2;
            }
            else if (status == 2) {
                time_t guess0_lo = timegm_noleapsecond(&tm_lo);
                guess = guess_lo + (guess0 - guess0_lo);
                if (guess == guess_lo)
                    guess++;
                status = 0;
            }
            if (guess <= guess_lo || guess_hi <= guess) {
                /* Precious guess is invalid. try binary search. */
#ifdef DEBUG_GUESSRANGE
                if (guess <= guess_lo) fprintf(stderr, "too small guess: %ld <= %ld\n", guess, guess_lo);
                if (guess_hi <= guess) fprintf(stderr, "too big guess: %ld <= %ld\n", guess_hi, guess);
#endif
                goto binsearch;
            }
        }

	tm = GUESS(&guess);
	if (!tm) goto error;

	d = tmcmp(tptr, tm);

        if (d < 0) {
            guess_hi = guess;
            tm_hi = *tm;
            DEBUG_REPORT_GUESSRANGE;
        }
        else if (d > 0) {
            guess_lo = guess;
            tm_lo = *tm;
            DEBUG_REPORT_GUESSRANGE;
        }
        else {
          found:
	    if (!utc_p) {
		/* If localtime is nonmonotonic, another result may exist. */
		time_t guess2;
		if (find_dst) {
		    guess2 = guess - 2 * 60 * 60;
		    tm = LOCALTIME(&guess2, result);
		    if (tm) {
			if (tptr->tm_hour != (tm->tm_hour + 2) % 24 ||
			    tptr->tm_min != tm->tm_min ||
			    tptr->tm_sec != tm->tm_sec) {
			    guess2 -= (tm->tm_hour - tptr->tm_hour) * 60 * 60 +
				      (tm->tm_min - tptr->tm_min) * 60 +
				      (tm->tm_sec - tptr->tm_sec);
			    if (tptr->tm_mday != tm->tm_mday)
				guess2 += 24 * 60 * 60;
			    if (guess != guess2) {
				tm = LOCALTIME(&guess2, result);
				if (tm && tmcmp(tptr, tm) == 0) {
				    if (guess < guess2)
					*tp = guess;
				    else
					*tp = guess2;
                                    return NULL;
				}
			    }
			}
		    }
		}
		else {
		    guess2 = guess + 2 * 60 * 60;
		    tm = LOCALTIME(&guess2, result);
		    if (tm) {
			if ((tptr->tm_hour + 2) % 24 != tm->tm_hour ||
			    tptr->tm_min != tm->tm_min ||
			    tptr->tm_sec != tm->tm_sec) {
			    guess2 -= (tm->tm_hour - tptr->tm_hour) * 60 * 60 +
				      (tm->tm_min - tptr->tm_min) * 60 +
				      (tm->tm_sec - tptr->tm_sec);
			    if (tptr->tm_mday != tm->tm_mday)
				guess2 -= 24 * 60 * 60;
			    if (guess != guess2) {
				tm = LOCALTIME(&guess2, result);
				if (tm && tmcmp(tptr, tm) == 0) {
				    if (guess < guess2)
					*tp = guess2;
				    else
					*tp = guess;
                                    return NULL;
				}
			    }
			}
		    }
		}
	    }
            *tp = guess;
            return NULL;
	}
    }

    /* Given argument has no corresponding time_t. Let's extrapolate. */
    /*
     *  `Seconds Since the Epoch' in SUSv3:
     *  tm_sec + tm_min*60 + tm_hour*3600 + tm_yday*86400 +
     *  (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 -
     *  ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400
     */

    tptr_tm_yday = calc_tm_yday(tptr->tm_year, tptr->tm_mon, tptr->tm_mday);

    *tp = guess_lo +
          ((tptr->tm_year - tm_lo.tm_year) * 365 +
           ((tptr->tm_year-69)/4) -
           ((tptr->tm_year-1)/100) +
           ((tptr->tm_year+299)/400) -
           ((tm_lo.tm_year-69)/4) +
           ((tm_lo.tm_year-1)/100) -
           ((tm_lo.tm_year+299)/400) +
           tptr_tm_yday -
           tm_lo.tm_yday) * 86400 +
          (tptr->tm_hour - tm_lo.tm_hour) * 3600 +
          (tptr->tm_min - tm_lo.tm_min) * 60 +
          (tptr->tm_sec - (tm_lo.tm_sec == 60 ? 59 : tm_lo.tm_sec));

    return NULL;

  out_of_range:
    return "time out of range";

  error:
    return "gmtime/localtime error";
}

void
tm_add_offset(struct tm *tm, long diff)
{
    int sign, tsec, tmin, thour, tday;

    if (diff < 0) {
	sign = -1;
	diff = -diff;
    }
    else {
	sign = 1;
    }
    tsec = diff % 60;
    diff = diff / 60;
    tmin = diff % 60;
    diff = diff / 60;
    thour = diff % 24;
    diff = diff / 24;

    if (sign < 0) {
	tsec = -tsec;
	tmin = -tmin;
	thour = -thour;
    }

    tday = 0;

    if (tsec) {
	tsec += tm->tm_sec;
	if (tsec < 0) {
	    tsec += 60;
	    tmin -= 1;
	}
	if (60 <= tsec) {
	    tsec -= 60;
	    tmin += 1;
	}
	tm->tm_sec = tsec;
    }

    if (tmin) {
	tmin += tm->tm_min;
	if (tmin < 0) {
	    tmin += 60;
	    thour -= 1;
	}
	if (60 <= tmin) {
	    tmin -= 60;
	    thour += 1;
	}
	tm->tm_min = tmin;
    }

    if (thour) {
	thour += tm->tm_hour;
	if (thour < 0) {
	    thour += 24;
	    tday = -1;
	}
	if (24 <= thour) {
	    thour -= 24;
	    tday = 1;
	}
	tm->tm_hour = thour;
    }

    if (tday) {
	if (tday < 0) {
	    if (tm->tm_mon == 1 && tm->tm_mday == 1) {
		tm->tm_mday = 31;
		tm->tm_mon = 12; /* December */
		tm->tm_year = tm->tm_year - 1;
	    }
	    else if (tm->tm_mday == 1) {
		const int *days_in_month = leap_year_p(tm->tm_year)
					       ? leap_year_days_in_month
					       : common_year_days_in_month;
		tm->tm_mon--;
		tm->tm_mday = days_in_month[tm->tm_mon - 1];
	    }
	    else {
		tm->tm_mday--;
	    }
	}
	else {
	    int leap = leap_year_p(tm->tm_year);
	    if (tm->tm_mon == 12 && tm->tm_mday == 31) {
		tm->tm_year = tm->tm_year + 1;
		tm->tm_mon = 1; /* January */
		tm->tm_mday = 1;
	    }
	    else if (tm->tm_mday ==
		     (leap ? leap_year_days_in_month
			   : common_year_days_in_month)[tm->tm_mon - 1]) {
		tm->tm_mon++;
		tm->tm_mday = 1;
	    }
	    else {
		tm->tm_mday++;
	    }
	}
    }
}

