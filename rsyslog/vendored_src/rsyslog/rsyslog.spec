%define rsyslog_statedir %{_sharedstatedir}/%{name}
%define rsyslog_pkidir %{_sysconfdir}/pki/%{name}
%define rsyslog_docdir %{_docdir}/%{name}


Summary: Enhanced system logging and kernel message trapping daemon
Name: rsyslog
Version: 8.37.0
Release: 13%{?dist}
License: (GPLv3+ and ASL 2.0)
Group: System Environment/Daemons
ExcludeArch: i686
URL: http://www.rsyslog.com/
Source2: rsyslog.conf
Source3: rsyslog.sysconfig
Source4: rsyslog.log

BuildRequires: autoconf
BuildRequires: automake
BuildRequires: bison
BuildRequires: flex
BuildRequires: libcurl-devel
BuildRequires: libgcrypt-devel 
BuildRequires: libfastjson-devel >= 0.99.8
BuildRequires: libestr-devel >= 0.1.9
BuildRequires: libtool
BuildRequires: libuuid-devel
BuildRequires: pkgconfig
%if 0%{?rhel} > 7
BuildRequires: python3-docutils
%else
BuildRequires: python-docutils
%endif
# it depens on rhbz#1419228
BuildRequires: systemd-devel >= 219-39
BuildRequires: zlib-devel

Requires: logrotate >= 3.5.2
Requires: bash >= 2.0
Requires: libestr >= 0.1.9
Requires: libfastjson >= 0.99.8
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

Provides: syslog
Obsoletes: sysklogd < 1.5-11

%package crypto
Summary: Encryption support
Group: System Environment/Daemons
Requires: %name = %version-%release

%package doc
Summary: HTML Documentation for rsyslog
Group: Documentation
#no reason to have arched documentation
BuildArch: noarch

%package elasticsearch
Summary: ElasticSearch output module for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release

%package gnutls
Summary: TLS protocol support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
BuildRequires: gnutls-devel

%package gssapi
Summary: GSSAPI authentication and encryption support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
BuildRequires: krb5-devel

%package kafka
Summary: Provides kafka support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
BuildRequires: librdkafka-devel

%package mmaudit
Summary: Message modification module supporting Linux audit format
Group: System Environment/Daemons
Requires: %name = %version-%release

%package mmjsonparse
Summary: JSON enhanced logging support
Group: System Environment/Daemons
Requires: %name = %version-%release

%package mmkubernetes
Summary: Provides the mmkubernetes module
Group: System Environment/Daemons
Requires: %name = %version-%release

%package mmnormalize
Summary: Log normalization support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
BuildRequires: liblognorm-devel >= 2.0.5
Requires: liblognorm >= 2.0.5

%package mmsnmptrapd
Summary: Message modification module for snmptrapd generated messages
Group: System Environment/Daemons
Requires: %name = %version-%release

%package mysql
Summary: MySQL support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
%if 0%{?rhel} > 7
BuildRequires: mariadb-connector-c-devel
%else
BuildRequires: mariadb-devel
%endif

%package pgsql
Summary: PostgresSQL support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
BuildRequires: postgresql-devel

%package relp
Summary: RELP protocol support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
Requires: librelp >= 1.0.3
BuildRequires: librelp-devel >= 1.2.16

%package snmp
Summary: SNMP protocol support for rsyslog
Group: System Environment/Daemons
Requires: %name = %version-%release
BuildRequires: net-snmp-devel

%description
Rsyslog is an enhanced, multi-threaded syslog daemon. It supports MySQL,
syslog/TCP, RFC 3195, permitted sender lists, filtering on any message part,
and fine grain output format control. It is compatible with stock sysklogd
and can be used as a drop-in replacement. Rsyslog is simple to set up, with
advanced features suitable for enterprise-class, encryption-protected syslog
relay chains.

%description crypto
This package contains a module providing log file encryption and a
command line tool to process encrypted logs.

%description doc
This subpackage contains documentation for rsyslog.

%description elasticsearch
This module provides the capability for rsyslog to feed logs directly into
Elasticsearch.

%description gnutls
The rsyslog-gnutls package contains the rsyslog plugins that provide the
ability to receive syslog messages via upcoming syslog-transport-tls
IETF standard protocol.

%description gssapi
The rsyslog-gssapi package contains the rsyslog plugins which support GSSAPI
authentication and secure connections. GSSAPI is commonly used for Kerberos
authentication.

%description kafka
The rsyslog-kafka package provides modules for Apache Kafka input and output. 

%description mmaudit
This module provides message modification supporting Linux audit format
in various settings.

%description mmjsonparse
This module provides the capability to recognize and parse JSON enhanced
syslog messages.

%description mmkubernetes
The rsyslog-mmkubernetes package provides module for adding kubernetes
container metadata.

%description mmnormalize
This module provides the capability to normalize log messages via liblognorm.

%description mmsnmptrapd
This message modification module takes messages generated from snmptrapd and
modifies them so that they look like they originated from the read originator.

%description mysql
The rsyslog-mysql package contains a dynamic shared object that will add
MySQL database support to rsyslog.

%description pgsql
The rsyslog-pgsql package contains a dynamic shared object that will add
PostgreSQL database support to rsyslog.

%description relp
The rsyslog-relp package contains the rsyslog plugins that provide
the ability to receive syslog messages via the reliable RELP
protocol.

%description snmp
The rsyslog-snmp package contains the rsyslog plugin that provides the
ability to send syslog messages as SNMPv1 and SNMPv2c traps.

%prep
# set up rsyslog-doc sources
%setup -q -a 1 -T -c

#regenerate the docs

#mv build/searchindex.js searchindex_backup.js
#sphinx-build -b html source build
#clean up
#mv searchindex_backup.js build/searchindex.js

rm -r LICENSE README.md source build/objects.inv
mv build doc

# set up rsyslog sources
%setup -q -D

%patch0 -p1 -b .service
%patch1 -p1 -b .default-tag
%patch2 -p1 -b .imfile-symlink
%patch3 -p1 -b .mmkubernetes-404
%patch4 -p1 -b .endmsg-regex
%patch5 -p1 -b .rotation-detection
%patch6 -p1 -b .short-offmsg-crash
%patch7 -p1 -b .preservecase-option
%patch8 -p1 -b .imjournal-memleak
%patch9 -p1 -b .imjournal-err-flood
%patch10 -p1 -b .imrelp-old-syntax
%patch11 -p1 -b .tls-CC

%build
%ifarch sparc64
#sparc64 need big PIE
export CFLAGS="$RPM_OPT_FLAGS -fPIE"
%else
export CFLAGS="$RPM_OPT_FLAGS -fpie"
%endif
export LDFLAGS="-pie -Wl,-z,relro -Wl,-z,now"

sed -i 's/%{version}/%{version}-%{release}/g' configure.ac
autoreconf -if
%configure \
	--prefix=/usr \
	--disable-static \
	--disable-testbench \
	--enable-elasticsearch \
	--enable-generate-man-pages \
	--enable-gnutls \
	--enable-gssapi-krb5 \
	--enable-imdiag \
	--enable-imfile \
	--enable-imjournal \
	--enable-imkafka \
	--enable-impstats \
	--enable-imptcp \
	--enable-mail \
	--enable-mmanon \
	--enable-mmaudit \
	--enable-mmcount \
	--enable-mmjsonparse \
	--enable-mmkubernetes \
	--enable-mmnormalize \
	--enable-mmsnmptrapd \
	--enable-mmutf8fix \
	--enable-mysql \
	--enable-omjournal \
	--enable-omkafka \
	--enable-omprog \
	--enable-omstdout \
	--enable-omuxsock \
	--enable-pgsql \
	--enable-pmaixforwardedfrom \
	--enable-pmcisconames \
	--enable-pmlastmsg \
	--enable-pmsnare \
	--enable-relp \
	--enable-snmp \
	--enable-unlimited-select \
	--enable-usertools 

make

%install
make DESTDIR=%{buildroot} install

install -d -m 755 %{buildroot}%{_sysconfdir}/sysconfig
install -d -m 755 %{buildroot}%{_sysconfdir}/logrotate.d
install -d -m 755 %{buildroot}%{_sysconfdir}/rsyslog.d
install -d -m 700 %{buildroot}%{rsyslog_statedir}
install -d -m 700 %{buildroot}%{rsyslog_pkidir}
install -d -m 755 %{buildroot}%{rsyslog_docdir}/html

install -p -m 644 %{SOURCE2} %{buildroot}%{_sysconfdir}/rsyslog.conf
install -p -m 644 %{SOURCE3} %{buildroot}%{_sysconfdir}/sysconfig/rsyslog
install -p -m 644 %{SOURCE4} %{buildroot}%{_sysconfdir}/logrotate.d/syslog
install -p -m 644 plugins/ommysql/createDB.sql %{buildroot}%{rsyslog_docdir}/mysql-createDB.sql
install -p -m 644 plugins/ompgsql/createDB.sql %{buildroot}%{rsyslog_docdir}/pgsql-createDB.sql
install -p -m 644 contrib/mmkubernetes/*.rulebase %{buildroot}%{rsyslog_docdir}
# extract documentation
cp -r doc/* %{buildroot}%{rsyslog_docdir}/html
# get rid of libtool libraries
rm -f %{buildroot}%{_libdir}/rsyslog/*.la
# get rid of socket activation by default
sed -i '/^Alias/s/^/;/;/^Requires=syslog.socket/s/^/;/' %{buildroot}%{_unitdir}/rsyslog.service

# convert line endings from "\r\n" to "\n"
cat tools/recover_qi.pl | tr -d '\r' > %{buildroot}%{_bindir}/rsyslog-recover-qi.pl

%post
for n in /var/log/{messages,secure,maillog,spooler}
do
	[ -f $n ] && continue
	umask 066 && touch $n
done
%systemd_post rsyslog.service

%preun
%systemd_preun rsyslog.service

%postun
%systemd_postun_with_restart rsyslog.service

%files
%doc AUTHORS COPYING* ChangeLog
%exclude %{rsyslog_docdir}/html
%exclude %{rsyslog_docdir}/mysql-createDB.sql
%exclude %{rsyslog_docdir}/pgsql-createDB.sql
%dir %{_libdir}/rsyslog
%dir %{_sysconfdir}/rsyslog.d
%dir %{rsyslog_statedir}
%dir %{rsyslog_pkidir}
%{_sbindir}/rsyslogd
%attr(755,root,root) %{_bindir}/rsyslog-recover-qi.pl
%{_mandir}/man5/rsyslog.conf.5.gz
%{_mandir}/man8/rsyslogd.8.gz
%{_unitdir}/rsyslog.service
%config(noreplace) %{_sysconfdir}/rsyslog.conf
%config(noreplace) %{_sysconfdir}/sysconfig/rsyslog
%config(noreplace) %{_sysconfdir}/logrotate.d/syslog
# plugins
%{_libdir}/rsyslog/fmhash.so
%{_libdir}/rsyslog/fmhttp.so
%{_libdir}/rsyslog/imdiag.so
%{_libdir}/rsyslog/imfile.so
%{_libdir}/rsyslog/imjournal.so
%{_libdir}/rsyslog/imklog.so
%{_libdir}/rsyslog/immark.so
%{_libdir}/rsyslog/impstats.so
%{_libdir}/rsyslog/imptcp.so
%{_libdir}/rsyslog/imtcp.so
%{_libdir}/rsyslog/imudp.so
%{_libdir}/rsyslog/imuxsock.so
%{_libdir}/rsyslog/lmnet.so
%{_libdir}/rsyslog/lmnetstrms.so
%{_libdir}/rsyslog/lmnsd_ptcp.so
%{_libdir}/rsyslog/lmregexp.so
%{_libdir}/rsyslog/lmstrmsrv.so
%{_libdir}/rsyslog/lmtcpclt.so
%{_libdir}/rsyslog/lmtcpsrv.so
%{_libdir}/rsyslog/lmzlibw.so
%{_libdir}/rsyslog/mmanon.so
%{_libdir}/rsyslog/mmcount.so
%{_libdir}/rsyslog/mmexternal.so
%{_libdir}/rsyslog/mmutf8fix.so
%{_libdir}/rsyslog/omjournal.so
%{_libdir}/rsyslog/ommail.so
%{_libdir}/rsyslog/omprog.so
%{_libdir}/rsyslog/omstdout.so
%{_libdir}/rsyslog/omtesting.so
%{_libdir}/rsyslog/omuxsock.so
%{_libdir}/rsyslog/pmaixforwardedfrom.so
%{_libdir}/rsyslog/pmcisconames.so
%{_libdir}/rsyslog/pmlastmsg.so
%{_libdir}/rsyslog/pmsnare.so

%files crypto
%{_bindir}/rscryutil
%{_mandir}/man1/rscryutil.1.gz
%{_libdir}/rsyslog/lmcry_gcry.so

%files doc
%doc %{rsyslog_docdir}/html

%files elasticsearch
%{_libdir}/rsyslog/omelasticsearch.so

%files gssapi
%{_libdir}/rsyslog/lmgssutil.so
%{_libdir}/rsyslog/imgssapi.so
%{_libdir}/rsyslog/omgssapi.so

%files gnutls
%{_libdir}/rsyslog/lmnsd_gtls.so

%files kafka
%{_libdir}/rsyslog/imkafka.so
%{_libdir}/rsyslog/omkafka.so

%files mmaudit
%{_libdir}/rsyslog/mmaudit.so

%files mmjsonparse
%{_libdir}/rsyslog/mmjsonparse.so

%files mmkubernetes
%{_libdir}/rsyslog/mmkubernetes.so
%doc %{rsyslog_docdir}/k8s_filename.rulebase
%doc %{rsyslog_docdir}/k8s_container_name.rulebase

%files mmnormalize
%{_libdir}/rsyslog/mmnormalize.so

%files mmsnmptrapd
%{_libdir}/rsyslog/mmsnmptrapd.so

%files mysql
%doc %{rsyslog_docdir}/mysql-createDB.sql
%{_libdir}/rsyslog/ommysql.so

%files pgsql
%doc %{rsyslog_docdir}/pgsql-createDB.sql
%{_libdir}/rsyslog/ompgsql.so

%files relp
%{_libdir}/rsyslog/imrelp.so
%{_libdir}/rsyslog/omrelp.so

%files snmp
%{_libdir}/rsyslog/omsnmp.so


%changelog
* Fri Aug 30 2019 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-13
  RHEL 8.1.0 ERRATUM
- added patch enabling stricter TLS certs checking conforming to 
  common criteria requirements
  resolves: rhbz#1733244

* Mon Jul 22 2019 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-12
  RHEL 8.1.0 ERRATUM
- edited imjournal memleak patch to not cause double-free crash
  resolves: rhbz#1729995
- added patch calling journald API only when there are no
  preceeding errors
  resolves: rhbz#1722165
- added patch fixing imrelp module when invoked with old syntax
  resolves: rhbz#1724218

* Wed Jun 05 2019 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-11
  RHEL 8.1.0 ERRATUM
- fixed memory leak in imjournal by proper cursor releasing
  resolves: rhbz#1716867

* Fri May 10 2019 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-10
  RHEL 8.1.0 ERRATUM
- added option for imfile endmsg.regex
  resolves: rhbz#1627941
- added patch enhancing imfile rotation detection
  resolves: rhbz#1674471
- added patch fixing msgOffset datatype preventing crash on
  message with too long other fields
  resolves: rhbz#1677037
- added patch introducing "preservecase" option for imudp/imtcp
  resolves: rhbz#1614181

* Mon Dec 17 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-9
  RHEL 8.0.0 ERRATUM
- added back legacy option for imjournal default tag
  resolves: rhbz#1659898

* Fri Dec 14 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-8
  RHEL 8.0.0 ERRATUM
- fixes mmkubenetes handling 404 and 429 errors
  resolves: rhbz#1622768

* Fri Oct 19 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-7
- removed version from docdir macro
  resolves: rhbz#1638023

* Mon Aug 27 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-6
- updated patch for enhanced imfile symlink support
  resolves: rhbz#1614179

* Fri Aug 10 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-5
- rebuild for rebased dependencies
- dependency cleanup and sorted sub-packages in spec
  resolves: rhbz#1613880

* Fri Aug 10 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-4
- enabled mmkubernetes module
  resolves: rhbz#1614432
  resolves: rhbz#1614441

* Thu Aug 09 2018 Josef Ridky <jridky@redhat.com> - 8.37.0-3
- Rebuild for Net-SNMP

* Thu Aug 09 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-2
- added patch for enhanced imfile symlink support
  resolves: rhbz#1614179

* Wed Aug 08 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.37.0-1
- rebase to 8.37.0
  resolves: rhbz#1613880
  resolves: rhbz#1564054
  resolves: rhbz#1598218
  - dropped invalid statefile patch - upstreamed
  - dropped imjournal duplicates patch - upstreamed
  resolves: rhbz#1544394
- renumbered default tag patch and fitted onto rebased version

* Fri Aug 03 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.36.0-4
- removed dependency on libee
  resolves: rhbz#1612032

* Wed Aug 01 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.36.0-3
- dropped json_nonoverwrite patch as there is no reason for
  keeping it
- renumbered rest of patches
- added release number to AC_INIT to have it in package error logs

* Mon Jul 16 2018 Charalampos Stratakis <cstratak@redhat.com> - 8.36.0-2
- Depend on python3-docutils

* Mon Jul 02 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.36.0-1
- changed PID file name to follow upstream
- removed config option to disable stdlog as it is now 
  disabled by default

* Thu Jun 28 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.36.0-1
- rebase to 8.36
- removed hiredis module
- removed omudpspoof module
  resolves: rhbz#1593762
- finished converting config to new-style syntax

* Mon May 21 2018 Jiri Vymazal <jvymazal@redhat.com> - 8.35.0-1
- spec file cleanup
- enabled kafka and hiredis modules
  resolves: rhbz#1542497
  resolves: rhbz#1542504
- renamed patch fixing imjournal duplicating messages
  resolves: rhbz#1544394

* Thu May 17 2018 Marek Tamaskovic <mtamasko@redhat.com> - 8.35.0-1
- rebase to 8.35
- rebased patches from 8.32 to 8.35
  - fixed imjournal-duplicates
  - fixed imjournal-default-tag
  - fixed service patch
  - fixed in upstream deserialize-property-name

* Fri Mar 23 2018 Radovan Sroka <rsroka@redhat.com> - 8.32.0-2
- rebuild, bumped release number

* Tue Feb 06 2018 Radovan Sroka <rsroka@redhat.com> - 8.32.0-1
- initial clean build with plugins from rhel7
- removed plugins:
  - libdbi
  - omruleset
  - pmrfc3164sd
- imported from fedora26  
