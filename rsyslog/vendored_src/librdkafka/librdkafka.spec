Name:		librdkafka
Version:	0.11.4
Release:	1%{?dist}
Summary:	The Apache Kafka C library

Group:		Development/Libraries
License:	BSD
URL:		https://github.com/edenhill/librdkafka

BuildRequires:	gcc
BuildRequires:	gcc-c++
%if 0%{?rhel} > 7
BuildRequires: python3
%else
BuildRequires: python
%endif
BuildRequires:  openssl-devel
BuildRequires:  cyrus-sasl-devel
BuildRequires:  lz4-devel


%description
Librdkafka is a C/C++ library implementation of the Apache Kafka protocol,
containing both Producer and Consumer support.
It was designed with message delivery reliability and high performance in mind,
current figures exceed 800000 messages/second for the producer and 3 million
messages/second for the consumer.

%package	devel
Summary:	The Apache Kafka C library (Development Environment)
Group:		Development/Libraries
Requires:	%{name}%{?_isa} = %{version}-%{release}

%description	devel
librdkafka is a C/C++ library implementation of the Apache Kafka protocol,
containing both Producer and Consumer support.
This package contains headers and libraries required to build applications
using librdkafka.

%prep
%setup -q

%patch1 -p1 -b .python3

%build
%configure --enable-lz4 \
           --enable-ssl \
           --enable-sasl

%make_build

%check
make check

%install
%make_install
find %{buildroot} -name '*.a' -delete -print

%post	-p /sbin/ldconfig
%postun	-p /sbin/ldconfig

%files
%{_libdir}/librdkafka.so.*
%{_libdir}/librdkafka++.so.*
%doc README.md CONFIGURATION.md INTRODUCTION.md
%license LICENSE LICENSE.pycrc LICENSE.snappy

%files devel
%dir %{_includedir}/librdkafka
%attr(0644,root,root) %{_includedir}/librdkafka/*
%{_libdir}/librdkafka.so
%{_libdir}/librdkafka++.so
%{_libdir}/pkgconfig/rdkafka.pc
%{_libdir}/pkgconfig/rdkafka++.pc
%{_libdir}/pkgconfig/rdkafka-static.pc
%{_libdir}/pkgconfig/rdkafka++-static.pc


%changelog
* Fri Feb 08 2019 Jiri Vymazal <jvymazal@redhat.com> - 0.11.4-1
- rebase to v0.11.4 (0.11.5 was breaking rsyslog-kafka)
  resolves: rhbz#1614697

* Fri Aug 10 2018 Jiri Vymazal <jvymazal@redhat.com> - 0.11.5-1
- rebase to v0.11.5
  resolves: rhbz#1614697
- removed explicit %attr on symlinks

* Thu Jun 28 2018 Radovan Sroka <rsroka@redhat.com> - 0.11.0-2
- switch from python2 to python3
  resolves: rhbz#1595795

* Thu Aug 31 2017 Michal Luscon <mluscon@gmail.com> - 0.11.0-1
- Update to 0.11.0

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.9.5-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Wed Jul 26 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.9.5-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Mon May 22 2017 Radovan Sroka <rsroka@redhat.com> - 0.9.5-1
- Update to 0.9.4

* Sat Mar 11 2017 Michal Luscon <mluscon@gmail.com> - 0.9.4-1
- Update to 0.9.4
- enable lz4, ssl, sasl

* Fri Feb 10 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.9.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild


* Fri Nov 11 2016 Radovan Sroka <rsroka@redhat.com> 0.9.2-1
- 0.9.2 release
- package created
