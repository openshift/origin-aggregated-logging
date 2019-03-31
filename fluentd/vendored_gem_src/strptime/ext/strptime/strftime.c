#include "../strptime/strptime.h"
#include "ruby/encoding.h"
#include <time.h>

VALUE rb_cStrftime;
#ifndef HAVE_RB_TIME_UTC_OFFSET
static ID id_gmtoff;
#endif

#define GetStrftimeval(obj, tobj) ((tobj) = get_strftimeval(obj))
#define GetNewStrftimeval(obj, tobj) ((tobj) = get_new_strftimeval(obj))
#define StrfTIME_INIT_P(tobj) ((tobj)->isns)

#define LIKELY(x) (__builtin_expect((x), 1))
#define UNLIKELY(x) (__builtin_expect((x), 0))

#define REG_PC (pc)
#define GET_PC() REG_PC
#define SET_PC(x) (REG_PC = (x))
#define GET_CURRENT_INSN() (*GET_PC())
#define GET_OPERAND(n) (GET_PC()[(n)])
#define ADD_PC(n) (SET_PC(REG_PC + (n)))

#define JUMP(dst) (REG_PC += (dst))

#define LABEL(x) INSN_LABEL_##x
#define ELABEL(x) INSN_ELABEL_##x
#define LABEL_PTR(x) &&LABEL(x)

#define INSN_ENTRY(insn) LABEL(insn) :

#define TC_DISPATCH(insn)                                                      \
    goto *(void const *)GET_CURRENT_INSN();                                    \
    ;
#define END_INSN(insn) TC_DISPATCH(insn);

#define INSN_DISPATCH()                                                        \
    TC_DISPATCH(__START__)                                                     \
    {

#define END_INSNS_DISPATCH()                                                   \
    rb_bug("strptime: unknown insn: %p", GET_CURRENT_INSN());                  \
    } /* end of while loop */

#define NEXT_INSN() TC_DISPATCH(__NEXT_INSN__)

static const char *month_names[] = {
    "January", "February", "March",     "April",   "May",      "June",
    "July",    "August",   "September", "October", "November", "December"};

static VALUE
strftime_exec0(void **pc, VALUE fmt, struct timespec *tsp, int gmtoff, size_t result_length)
{
    VALUE result;
    struct tm tm;
    char *p;
    if (UNLIKELY(tsp == NULL)) {
	static const void *const insns_address_table[] = {
	    NULL, NULL, NULL, NULL,
	    NULL, NULL, NULL, LABEL_PTR(H),
	    NULL, NULL, NULL, LABEL_PTR(L),
	    LABEL_PTR(M), LABEL_PTR(N), NULL, NULL,
	    NULL, NULL, LABEL_PTR(S), NULL,
	    NULL, NULL, NULL, NULL,
	    LABEL_PTR(Y), NULL, NULL, NULL,
	    NULL, NULL, LABEL_PTR(_5f), LABEL_PTR(_60),
	    NULL, LABEL_PTR(b), NULL, LABEL_PTR(d),
	    LABEL_PTR(d), NULL, NULL, NULL,
	    NULL, NULL, NULL, NULL,
	    LABEL_PTR(m), NULL, NULL, NULL,
	    NULL, NULL, NULL, NULL,
	    NULL, NULL, NULL, NULL,
	    LABEL_PTR(y), LABEL_PTR(z),
	};
	*pc = (void *)insns_address_table;
	return Qnil;
    }

    result = rb_enc_str_new(NULL, result_length, rb_enc_get(fmt));
    p = RSTRING_PTR(result);

    tsp->tv_sec += gmtoff;
    rb_gmtime_r(&tsp->tv_sec, &tm);

    INSN_DISPATCH();
    INSN_ENTRY(H)
    {
	*p++ = '0' + (tm.tm_hour / 10);
	*p++ = '0' + (tm.tm_hour % 10);
	ADD_PC(1);
	END_INSN(H)
    }
    INSN_ENTRY(L)
    {
	int msec = tsp->tv_nsec / 1000000;
	p[2] = '0' + (msec % 10);
	msec /= 10;
	p[1] = '0' + (msec % 10);
	p[0] = '0' + (msec / 10);
	p += 3;
	ADD_PC(1);
	END_INSN(L)
    }
    INSN_ENTRY(M)
    {
	*p++ = '0' + (tm.tm_min / 10);
	*p++ = '0' + (tm.tm_min % 10);
	ADD_PC(1);
	END_INSN(M)
    }
    INSN_ENTRY(N)
    {
	int len = 9;
	int i;
	int base = 1;
	int subsec = tsp->tv_nsec;
	for (i=0; i < 9-len; i++) {
	    base *= 10;
	}
	subsec /= base;
	for (i=0; i < len; i++) {
	    p[len-i-1] = '0' + subsec % 10;
	    subsec /= 10;
	}
	p += len;
	ADD_PC(1);
	END_INSN(N)
    }
    INSN_ENTRY(S)
    {
	*p++ = '0' + (tm.tm_sec / 10);
	*p++ = '0' + (tm.tm_sec % 10);
	ADD_PC(1);
	END_INSN(S)
    }
    INSN_ENTRY(Y)
    {
	// TODO: Y10K
	int i, y = tm.tm_year;
	y += y < 69 ? 2000 : 1900;
	for (i = 0; i < 4; i++) {
	    p[3-i] = '0' + y % 10;
	    y /= 10;
	}
	p += 4;
	ADD_PC(1);
	END_INSN(Y)
    }
    INSN_ENTRY(d)
    {
	*p++ = '0' + (tm.tm_mday / 10);
	*p++ = '0' + (tm.tm_mday % 10);
	ADD_PC(1);
	END_INSN(d)
    }
    INSN_ENTRY(b)
    {
	const char *mon = month_names[tm.tm_mon];
	memcpy(p, mon, 3);
	p += 3;
	ADD_PC(1);
	END_INSN(b)
    }
    INSN_ENTRY(m)
    {
	int mon = tm.tm_mon + 1;
	*p++ = '0' + (mon / 10);
	*p++ = '0' + (mon % 10);
	ADD_PC(1);
	END_INSN(m)
    }
    INSN_ENTRY(y)
    {
	int y = tm.tm_year % 100;
	*p++ = '0' + (y / 10);
	*p++ = '0' + (y % 10);
	ADD_PC(1);
	END_INSN(y)
    }
    INSN_ENTRY(z)
    {
	int h, m, tmp=gmtoff;
	if (gmtoff >= 0) {
	    *p++ = '+';
	} else {
	    *p++ = '-';
	    tmp = -tmp;
	}
	tmp /= 60;
	h = (tmp / 60)&15; /* ignore too large offset */
	m = tmp % 60;
	*p++ = '0' + (h / 10);
	*p++ = '0' + (h % 10);
	*p++ = '0' + (m / 10);
	*p++ = '0' + (m % 10);
	ADD_PC(1);
	END_INSN(y)
    }
    INSN_ENTRY(_60)
    {
	size_t v = (size_t)GET_OPERAND(1);
	size_t off = v & 0xFFFF;
	size_t len = v >> 16;
	memcpy(p, RSTRING_PTR(fmt) + off, len);
	p += len;
	pc += 2;
	END_INSN(_60)
    }
    INSN_ENTRY(_5f)
    {
	return result;
	END_INSN(_5f)
    }
    END_INSNS_DISPATCH();

    /* unreachable */
    rb_bug("strftime_exec0: unreachable");
    UNREACHABLE;
}

static void **
strftime_compile(const char *fmt, size_t flen, size_t *rlenp)
{
    size_t fi = 0, rlen = 0;
    char c;
    void **isns0, **isns;
    void **insns_address_table;
    void *tmp;
    strftime_exec0((void **)&insns_address_table, Qnil, NULL, 0, 0);

    if (flen > 65535) {
	rb_raise(rb_eArgError, "too long format string (>65335)");
    }
    isns0 = ALLOC_N(void *, flen + 2);
    isns = isns0;

    while (fi < flen) {
	switch (fmt[fi]) {
	case '%':
	    fi++;
	    c = fmt[fi];
	    switch (c) {
	    case 'H':
	      rlen += 2;
	      goto accept_format;
	    case 'L':
	      rlen += 3;
	      goto accept_format;
	    case 'M':
	      rlen += 2;
	      goto accept_format;
	    case 'N':
	      rlen += 9;
	      goto accept_format;
	    case 'S':
	      rlen += 2;
	      goto accept_format;
	    case 'Y':
	      rlen += 4;
	      goto accept_format;
	    case 'd':
	      rlen += 2;
	      goto accept_format;
            case 'b':
              rlen += 3;
              goto accept_format;
	    case 'm':
	      rlen += 2;
	      goto accept_format;
	    case 'y':
	      rlen += 2;
	      goto accept_format;
	    case 'z':
	      rlen += 5;
	      goto accept_format;
accept_format:
		tmp = insns_address_table[c - 'A'];
		if (tmp) {
		    *isns++ = tmp;
		    fi++;
		    continue;
		}
	    default:
		xfree(isns0);
		rb_raise(rb_eArgError, "invalid format");
		break;
	    }
	default: {
	    const char *p0 = fmt + fi, *p = p0, *pe = fmt + flen;
	    size_t v = fi;
	    while (p < pe && *p != '%')
		p++;
	    v += (p - p0) << 16;
	    fi += p - p0;
	    rlen += p - p0;
	    *isns++ = insns_address_table['`' - 'A'];
	    *isns++ = (void *)v;
	} break;
	}
    }
    *isns++ = insns_address_table['_' - 'A'];
    REALLOC_N(isns0, void *, isns - isns0);
    *rlenp = rlen;
    return isns0;
}

struct strftime_object {
    void **isns;
    size_t result_length;
    VALUE fmt;
};

static void
strftime_mark(void *ptr)
{
    struct strftime_object *tobj = ptr;
    rb_gc_mark(tobj->fmt);
}

static void
strftime_free(void *ptr)
{
    struct strftime_object *tobj = ptr;
    if (tobj->isns) ruby_xfree(tobj->isns);
}

static size_t
strftime_memsize(const void *tobj)
{
    return sizeof(struct strftime_object);
}

static const rb_data_type_t strftime_data_type = {
    "strftime",
    {
	strftime_mark, strftime_free, strftime_memsize,
    },
#ifdef RUBY_TYPED_FREE_IMMEDIATELY
    0,
    0,
    RUBY_TYPED_FREE_IMMEDIATELY
#endif
};

static VALUE
strftime_s_alloc(VALUE klass)
{
    VALUE obj;
    struct strftime_object *tobj;

    obj = TypedData_Make_Struct(klass, struct strftime_object,
				&strftime_data_type, tobj);

    return obj;
}

static struct strftime_object *
get_strftimeval(VALUE obj)
{
    struct strftime_object *tobj;
    TypedData_Get_Struct(obj, struct strftime_object, &strftime_data_type,
			 tobj);
    if (!StrfTIME_INIT_P(tobj)) {
	rb_raise(rb_eTypeError, "uninitialized %" PRIsVALUE, rb_obj_class(obj));
    }
    return tobj;
}

static struct strftime_object *
get_new_strftimeval(VALUE obj)
{
    struct strftime_object *tobj;
    TypedData_Get_Struct(obj, struct strftime_object, &strftime_data_type,
			 tobj);
    if (StrfTIME_INIT_P(tobj)) {
	rb_raise(rb_eTypeError, "already initialized %" PRIsVALUE,
		 rb_obj_class(obj));
    }
    return tobj;
}

/*
 * @overload new(format)
 *   @param format [String] strftime(3) style format string.
 *
 * returns generator object
 */
static VALUE
strftime_init(VALUE self, VALUE fmt)
{
    struct strftime_object *tobj;
    void **isns;
    size_t rlen;
    StringValueCStr(fmt);
    TypedData_Get_Struct(self, struct strftime_object, &strftime_data_type,
			 tobj);
    isns = strftime_compile(RSTRING_PTR(fmt), RSTRING_LEN(fmt), &rlen);
    tobj->isns = isns;
    tobj->fmt = rb_str_new_frozen(fmt);
    tobj->result_length = rlen;
    return self;
}

/* @api private
 * For Ruby VM internal.
 */
static VALUE
strftime_init_copy(VALUE copy, VALUE self)
{
    struct strftime_object *tobj, *tcopy;

    if (!OBJ_INIT_COPY(copy, self)) return copy;
    GetStrftimeval(self, tobj);
    GetNewStrftimeval(copy, tcopy);
    MEMCPY(tcopy, tobj, struct strftime_object, 1);

    return copy;
}

/*
 * @overload exec(str)
 *   @param str [String] string to parse
 * @return [Time] the time object given string means
 *
 * Return a formatted datetime string
 *
 */
static VALUE
strftime_exec(VALUE self, VALUE time)
{
    struct strftime_object *sobj;
    struct timespec ts = rb_time_timespec(time);
#ifdef HAVE_RB_TIME_UTC_OFFSET
    int gmtoff = FIX2INT(rb_time_utc_offset(time));
#else
    int gmtoff = NUM2INT(rb_funcall(time, id_gmtoff, 0));
#endif
    GetStrftimeval(self, sobj);

    return strftime_exec0(sobj->isns, sobj->fmt, &ts, gmtoff, sobj->result_length);
}

/*
 * @overload execi(epoch)
 *   @param epoch [Integer] Unix epoch
 * @return [String] the formatted datetime string
 *
 * Return a formatted datetime string
 *
 */
static VALUE
strftime_execi(VALUE self, VALUE epoch)
{
    struct strftime_object *tobj;
    struct timespec ts;
    GetStrftimeval(self, tobj);

    if (RB_INTEGER_TYPE_P(epoch)) {
	ts.tv_sec = NUM2TIMET(epoch);
	ts.tv_nsec = 0;
    } else if (RB_FLOAT_TYPE_P(epoch)) {
	double d = NUM2DBL(epoch);
	ts.tv_sec = (time_t)d;
	ts.tv_nsec = (int)((int64_t)(d * 1000000000) % 1000000000);
    } else if (RB_TYPE_P(epoch, T_RATIONAL)) {
	ts.tv_sec = NUM2TIMET(epoch);
	ts.tv_nsec = NUM2INT(rb_funcall(rb_funcall(epoch, '*', 1, INT2FIX(1000000000)), '%', 1, INT2FIX(1000000000)));
    }

    return strftime_exec0(tobj->isns, tobj->fmt, &ts, 0, tobj->result_length);
}

/*
 * @overload source
 * @return [String] source format string
 */
static VALUE
strftime_source(VALUE self)
{
    struct strftime_object *tobj;
    GetStrftimeval(self, tobj);

    return tobj->fmt;
}


/*
 * Document-class: Strftime
 *
 * Strftime is a faster way to format time string like strftime(3).
 *
 * @example
 *    generator = Strftime.new('%Y-%m-%dT%H:%M:%S%z')
 *    generator.source #=> "%Y-%m-%dT%H:%M:%S%z"
 *    generator.exec(Time.now) #=> 2017-12-25T12:34:56+09:00
 */
void
Init_strftime(void)
{
    rb_cStrftime = rb_define_class("Strftime", rb_cObject);
    rb_define_alloc_func(rb_cStrftime, strftime_s_alloc);
    rb_define_method(rb_cStrftime, "initialize", strftime_init, 1);
    rb_define_method(rb_cStrftime, "initialize_copy", strftime_init_copy, 1);
    rb_define_method(rb_cStrftime, "exec", strftime_exec, 1);
    rb_define_method(rb_cStrftime, "execi", strftime_execi, 1);
    rb_define_method(rb_cStrftime, "source", strftime_source, 0);
#ifndef HAVE_RB_TIME_UTC_OFFSET
    id_gmtoff = rb_intern("gmtoff");
#endif
}
