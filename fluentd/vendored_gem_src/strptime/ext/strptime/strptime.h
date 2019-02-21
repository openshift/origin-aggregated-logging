#ifndef STRPTIME_H
#define STRPTIME_H 1

#include "ruby.h"
# ifndef HAVE_RB_TIME_TIMESPEC_NEW
VALUE rb_time_timespec_new(const struct timespec *ts, int offset);
# endif
struct tm * localtime_with_gmtoff_zone(const time_t *t, struct tm *result, long *gmtoff, const char **zone);
# ifndef HAVE_RB_TIMESPEC_NOW
void rb_timespec_now(struct timespec *ts);
# endif
time_t timegm_noleapsecond(struct tm *tm);
const char *find_time_t(struct tm *tptr, int utc_p, time_t *tp);
void tm_add_offset(struct tm *tm, long diff);
struct tm *rb_gmtime_r(const time_t *t, struct tm *result);
void Init_strftime(void);

#ifndef RB_INTEGER_TYPE_P
#define RB_INTEGER_TYPE_P(obj) rb_integer_type_p(obj)
static inline int
rb_integer_type_p(VALUE obj)
{
    return (FIXNUM_P(obj) ||
	    (!SPECIAL_CONST_P(obj) &&
	     BUILTIN_TYPE(obj) == RUBY_T_BIGNUM));
}
#endif

#endif /* STRPTIME_H */
