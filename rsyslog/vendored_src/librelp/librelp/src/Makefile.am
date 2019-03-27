if OS_SOLARIS
then
	PTHREADS_CFLAGS = -pthread
else
if OS_AIX
	PTHREADS_CFLAGS = -qthreaded
else
	PTHREADS_CFLAGS = -mt
endif
endif

DEBUG = -g
# Uncomment for debugging
#CFLAGS += $(DEBUG)

lib_LTLIBRARIES = librelp.la

EXTRA_DIST = librelp.h

librelp_la_SOURCES = \
	librelp.h \
	relp.c \
	relp.h \
	relpsess.c \
	relpsess.h \
	relpframe.c \
	relpframe.h \
	tcp.c \
	tcp.h \
	sendq.c \
	sendq.h \
	sendbuf.c \
	sendbuf.h \
	offers.c \
	offers.h \
	relpclt.c \
	relpclt.h \
	relpsrv.c \
	relpsrv.h \
	scsyslog.c \
	scrsp.c \
	copen.c \
	cclose.c \
	cserverclose.c \
	dbllinklist.h \
	cmdif.h
librelp_la_CPPFLAGS = $(AM_CLFAGS) $(PTHREADS_CFLAGS) $(GNUTLS_CFLAGS) $(WARN_CFLAGS)
librelp_la_LIBADD = $(rt_libs) $(GNUTLS_LIBS)
# info on version-info:
# http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
librelp_la_LDFLAGS = -version-info 4:0:4

include_HEADERS = librelp.h
