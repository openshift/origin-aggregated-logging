# Uncomment for debugging
DEBUG = -g
PTHREADS_CFLAGS = -pthread

#CFLAGS += $(DEBUG)

# we need to clean the normalizer up once we have reached a decent
# milestone (latest at initial release!)
bin_PROGRAMS = lognormalizer
lognormalizer_SOURCES = lognormalizer.c
lognormalizer_CPPFLAGS =  -I$(top_srcdir) $(WARN_CFLAGS) $(JSON_C_CFLAGS) $(LIBESTR_CFLAGS)
lognormalizer_LDADD = $(JSON_C_LIBS) $(LIBLOGNORM_LIBS) $(LIBESTR_LIBS) ../compat/compat.la 
lognormalizer_DEPENDENCIES = liblognorm.la

check_PROGRAMS = ln_test
ln_test_SOURCES = $(lognormalizer_SOURCES)
ln_test_CPPFLAGS = $(lognormalizer_CPPFLAGS)
ln_test_LDADD = $(lognormalizer_LDADD)
ln_test_DEPENDENCIES = $(lognormalizer_DEPENDENCIES)
ln_test_LDFLAGS = -no-install

lib_LTLIBRARIES = liblognorm.la

liblognorm_la_SOURCES = \
	liblognorm.c \
	pdag.c \
	annot.c \
	samp.c \
	lognorm.c \
	parser.c \
	enc_syslog.c \
	enc_csv.c \
	enc_xml.c

# Users violently requested that v2 shall be able to understand v1
# rulebases. As both are very very different, we now include the
# full v1 engine for this purpose. This here is what does this.
# see also: https://github.com/rsyslog/liblognorm/issues/103
liblognorm_la_SOURCES += \
	v1_liblognorm.c \
	v1_parser.c \
	v1_ptree.c \
	v1_samp.c

liblognorm_la_CPPFLAGS = $(JSON_C_CFLAGS) $(WARN_CFLAGS) $(LIBESTR_CFLAGS) $(PCRE_CFLAGS)
liblognorm_la_LIBADD = $(rt_libs) $(JSON_C_LIBS) $(LIBESTR_LIBS) $(PCRE_LIBS) -lestr
# info on version-info:
# http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
# Note: v2 now starts at version 5, as v1 previously also had 4
liblognorm_la_LDFLAGS = -version-info 6:0:1

EXTRA_DIST = \
	internal.h \
	liblognorm.h \
	lognorm.h \
	pdag.h \
	annot.h \
	samp.h \
	enc.h \
	parser.h \
	helpers.h

# and now the old cruft:
EXTRA_DIST += \
	v1_liblognorm.h \
	v1_parser.h \
	v1_samp.h \
	v1_ptree.h

include_HEADERS = liblognorm.h samp.h lognorm.h pdag.h annot.h enc.h parser.h lognorm-features.h
