#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.61)
AC_INIT([librelp], [1.2.16], [rgerhards@adiscon.com])
AM_INIT_AUTOMAKE
AM_INIT_AUTOMAKE
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_CONFIG_SRCDIR([src/relp.c])
AC_CONFIG_HEADER([config.h])
AC_CONFIG_MACRO_DIR([m4])

echo HOST: ${host}
case "${host}" in
  *-*-linux*)
    AC_DEFINE([OS_LINUX], [1], [Indicator for a Linux OS])
    os_type="linux"
  ;;
  *-*-*darwin*|*-*-dragonfly*|*-*-freebsd*|*-*-netbsd*|*-*-openbsd*)
    AC_DEFINE([OS_BSD], [1], [Indicator for a BSD OS])
    os_type="bsd"
  ;;
  *-apple-*)
    AC_DEFINE([OS_APPLE], [1], [Indicator for APPLE OS])
    os_type="apple"
  ;;
  *-*-kfreebsd*)
    # kernel is FreeBSD, but userspace is glibc - i.e. like linux
    # do not DEFINE OS_BSD
    os_type="bsd"
  ;;
  *-*-solaris*)
    os_type="solaris"
    AC_DEFINE([OS_SOLARIS], [1], [Indicator for a Solaris OS])
    AC_DEFINE([_POSIX_PTHREAD_SEMANTICS], [1], [Use POSIX pthread semantics])
    AC_DEFINE([_XOPEN_SOURCE], [600], [Use X/Open CAE Specification])
    CPPFLAGS="-std=c99 $CPPFLAGS"
    AM_CFLAGS="-std=c99 $CFLAGS"
    SOL_LIBS="-lsocket -lnsl"
    # Solaris libuuid does not ship with a pkgconfig file so override the appropriate
    # variables (but only if they have not been set by the user).
    LIBUUID_CFLAGS=${LIBUUID_CFLAGS:= }
    LIBUUID_LIBS=${LIBUUID_LIBS:=-luuid}
    AC_SUBST(SOL_LIBS)
  ;;
  *-*-aix*)
    os_type="aix"
    AC_DEFINE([OS_AIX], [1], [Indicator for a AIX OS])
    AM_CFLAGS="$CFLAGS -D_LINUX_SOURCE_COMPAT"
    LDFLAGS="$LDFLAGS -brtl"
  ;;
esac
AM_CONDITIONAL(OS_APPLE, test x$os_type == xapple)
AM_CONDITIONAL(xOS_LINUX, test x$os_type == xlinux)
AM_CONDITIONAL(OS_LINUX, test x$os_type == xlinux)
AM_CONDITIONAL(OS_SOLARIS, test x$os_type == xsolaris)
AM_CONDITIONAL(OS_AIX, test "x$os_type" = "xaix")

# Checks for programs.
AC_PROG_CC
AC_PROG_CC_C99
AM_PROG_CC_C_O
if test "$GCC" = "yes"
then AM_CFLAGS="$CFLAGS -W -Wall -Wformat-security -Wshadow -Wcast-align -Wpointer-arith -Wmissing-format-attribute -g"
fi

AC_PROG_LIBTOOL

if test "$GCC" = "yes"
then
	m4_ifdef([AX_IS_RELEASE], [
		AX_IS_RELEASE([git-directory])
		m4_ifdef([AX_COMPILER_FLAGS], [
			AX_COMPILER_FLAGS(,,,,[-pedantic -Wunused-parameter -Wmissing-field-initializers])
			# unfortunately, AX_COMPILER_FLAGS does not provide a way to override
			# the default -Wno-error=warning" flags. So we do this via sed below.
			# Note: we *really* want to have this error out during CI testing!
			# -Wdeclaration-after-statement in gcc always generates a warning,
			# even in c99 mode. So we need to unset it.
			# rgerhards, 2018-05-09
			WARN_CFLAGS="$(echo "$WARN_CFLAGS" | sed s/-Wno-error=/-W/g | sed s/-W.*declaration-after-statement//g)"
		], [
			AM_CFLAGS="$CFLAGS -W -Wall -Wformat-security -Wshadow -Wcast-align -Wpointer-arith -Wmissing-format-attribute -g"
			AC_MSG_WARN([missing AX_COMPILER_FLAGS macro, not using it])
		])
	], [
		AM_CFLAGS="$CFLAGS -W -Wall -Wformat-security -Wshadow -Wcast-align -Wpointer-arith -Wmissing-format-attribute -g"
		AC_MSG_WARN([missing AX_IS_RELEASE macro, not using AX_COMPILER_FLAGS macro because of this])
	])
else
	AC_MSG_WARN([compiler is not GCC or close compatible, not using ax_compiler_flags because of this (CC=$CC)])
fi

# Checks for libraries.
save_LIBS=$LIBS
LIBS=
AC_SEARCH_LIBS(clock_gettime, rt)
rt_libs=$LIBS
LIBS=$save_LIBS

AC_SUBST(rt_libs)

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([sys/epoll.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T
#AC_HEADER_TIME
#AC_STRUCT_TM

AC_CHECK_MEMBERS([struct sockaddr.sa_len],,,[$sa_includes])

# Checks for library functions.
AC_FUNC_SELECT_ARGTYPES
AC_FUNC_STRERROR_R
AC_TYPE_SIGNAL
AC_CHECK_FUNCS([strerror_r strdup epoll_create epoll_create1])

# enable TLS (may not be possible on platforms with too-old GnuTLS)
AC_ARG_ENABLE(tls,
        [AS_HELP_STRING([--enable-tls],[Enable TLS support @<:@default=yes@:>@])],
        [case "${enableval}" in
         yes) enable_tls="yes" ;;
          no) enable_tls="no" ;;
           *) AC_MSG_ERROR(bad value ${enableval} for --enable-tls) ;;
         esac],
        [enable_tls="yes"]
)
if test "$enable_tls" = "yes"; then
	PKG_CHECK_MODULES(GNUTLS, gnutls >= 2.0.0)
        AC_DEFINE(ENABLE_TLS, 1, [Defined if TLS support is enabled])
	# Check if we have support for proper cert validation
	AC_MSG_CHECKING(if we have gnutls_certificate_set_verify_function)
	save_CFLAGS="$CFLAGS"
	CFLAGS="$CFLAGS $GNUTLS_CFLAGS"
	save_LIBS="$LIBS"
	LIBS="$LIBS $GNUTLS_LIBS"
	AC_TRY_LINK(
		[
		#include <gnutls/gnutls.h>
		#include <gnutls/x509.h>
		], [
		gnutls_certificate_set_verify_function(NULL, NULL);
		],[
		AC_MSG_RESULT(yes)
		AC_DEFINE(HAVE_GNUTLS_CERTIFICATE_SET_VERIFY_FUNCTION, 1, [do we have gnutls_certificate_set_verify_function])
		have_gnutls_certificate_set_verify_function=yes
		],[
		AC_MSG_RESULT(no; authentication disabled)
		have_gnutls_certificate_set_verify_function=no
		]
	)
	CFLAGS="$save_CFLAGS"
	LIBS="$save_LIBS"
fi


# debug mode settings
AC_ARG_ENABLE(debug,
        [AS_HELP_STRING([--enable-debug],[Enable debug mode @<:@default=no@:>@])],
        [case "${enableval}" in
         yes) enable_debug="yes" ;;
          no) enable_debug="no" ;;
           *) AC_MSG_ERROR(bad value ${enableval} for --enable-debug) ;;
         esac],
        [enable_debug="no"]
)
if test "$enable_debug" = "yes"; then
        AC_DEFINE(DEBUG, 1, [Defined if debug mode is enabled (it's easier to check in the code).])
fi
if test "$enable_debug" = "no"; then
        AC_DEFINE(NDEBUG, 1, [Defined if debug mode is disabled.])
fi

# valgrind
AC_ARG_ENABLE(valgrind,
        [AS_HELP_STRING([--enable-valgrind],[Enable valgrind tests@<:@default=yes@:>@])],
        [case "${enableval}" in
         yes) enable_valgrind="yes" ;;
          no) enable_valgrind="no" ;;
           *) AC_MSG_ERROR(bad value ${enableval} for --enable-valgrind) ;;
         esac],
        [enable_valgrind="yes"]
)
if test "$enable_valgrind" = "yes"; then
        AC_CHECK_PROG(VALGRIND, [valgrind], [valgrind], [no])
fi
AM_CONDITIONAL([HAVE_VALGRIND], test "$enable_valgrind" == "yes")



AC_CONFIG_FILES([Makefile \
		relp.pc \
		doc/Makefile \
		tests/Makefile \
		src/Makefile])
AC_OUTPUT


echo "*****************************************************"
echo "librelp will be compiled with the following settings:"
echo
echo "run valgrind in testbench:     $enable_valgrind"
echo "Debug mode enabled:            $enable_debug"
echo "TLS enabled:                   $enable_tls"
echo "TLS authentication supported:  $have_gnutls_certificate_set_verify_function"

