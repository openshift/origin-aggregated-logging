require "mkmf"

have_func('rb_timespec_now')
have_func('rb_time_timespec_new')
have_func('rb_time_utc_offset')

create_makefile("strptime/strptime")
