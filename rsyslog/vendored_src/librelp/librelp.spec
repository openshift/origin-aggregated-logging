Summary: The Reliable Event Logging Protocol library
Name: librelp
Version: 1.2.16
Release: 1%{?dist}
License: GPLv3+
Group: System Environment/Libraries
URL: http://www.rsyslog.com/
Requires(post): /sbin/ldconfig
Requires(postun): /sbin/ldconfig
BuildRequires: gnutls-devel >= 1.4.0

%description
Librelp is an easy to use library for the RELP protocol. RELP (stands
for Reliable Event Logging Protocol) is a general-purpose, extensible
logging protocol.

%package devel
Summary: Development files for the %{name} package
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}
Requires: pkgconfig
BuildRequires: autoconf
BuildRequires: automake
BuildRequires: libtool

%description devel
Librelp is an easy to use library for the RELP protocol. The
librelp-devel package contains the header files and libraries needed
to develop applications using librelp.

%prep
%setup -q
%patch0 -p1

%build
autoreconf -ivf
%configure --disable-static
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

rm $RPM_BUILD_ROOT/%{_libdir}/*.la

%post -p /sbin/ldconfig

%postun
if [ "$1" = "0" ] ; then
    /sbin/ldconfig
fi

%files
%defattr(-,root,root,-)
%doc AUTHORS COPYING NEWS README doc/*html
%{_libdir}/librelp.so.*

%files devel
%defattr(-,root,root)
%{_includedir}/*
%{_libdir}/librelp.so
%{_libdir}/pkgconfig/relp.pc

%changelog
* Wed Aug 08 2018 Jiri Vymazal <jvymazal@redhat.com> - 1.2.16-1
- rebase to 1.2.16
  resolves: rhbz#1613876

* Mon Mar 26 2018 Radovan Sroka <rsroka@redhat.com> - 1.2.15-1
- rebase to 1.2.15
- fixed CVE-2018-1000140

* Wed Feb 07 2018 Fedora Release Engineering <releng@fedoraproject.org> - 1.2.14-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 1.2.14-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Wed Jul 26 2017 Fedora Release Engineering <releng@fedoraproject.org> - 1.2.14-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Fri Jun 02 2017 Radovan Sroka <rsroka@redhat.com> - 1.2.14-1
- rebase to 1.2.14

* Thu Feb 23 2017 Jiri Vymazal <jvymazal@redhat.com> - 1.2.13-1
- rebase to 1.2.13
  resolves: rhbz#1425638
- added patch for GnuTLS crypto-policy adherence
  resolves: rhbz#1179317
- added autoconf, automake and libtool because package
  has patches now

* Fri Feb 10 2017 Fedora Release Engineering <releng@fedoraproject.org> - 1.2.12-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Tue Sep 27 2016 Radovan Sroka <rsroka@redhat.com> 1.2.12-1
- rebase to 1.2.12

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 1.2.7-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Wed Jun 17 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.2.7-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Sun Aug 17 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.2.7-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.2.7-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Fri May 16 2014 Tomas Heinrich <theinric@redhat.com> - 1.2.7-1
- rebase to 1.2.7

* Thu Mar 27 2014 François Cami <fcami@fedoraproject.org> - 1.2.5-1
- rebase to 1.2.5

* Wed Jul 31 2013 Tomas Heinrich <theinric@redhat.com> - 1.2.0-1
- rebase to 1.2.0
- add gnutls-devel to BuildRequires

* Wed Apr 10 2013 Tomas Heinrich <theinric@redhat.com> - 1.0.3-1
- rebase to 1.0.3

* Thu Apr 04 2013 Tomas Heinrich <theinric@redhat.com> - 1.0.2-1
- rebase to 1.0.2

* Thu Feb 14 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Wed Nov 21 2012 Tomas Heinrich <theinric@redhat.com> - 1.0.1-1
- upgrade to upstream version 1.0.1

* Thu Jul 19 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Fri Jan 13 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.0-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Tue Feb 08 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Thu Jul 15 2010 Tomas Heinrich <theinric@redhat.com> - 1.0.0-1
- upgrade to upstream version 1.0.0

* Sat Jul 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.1.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Wed Feb 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.1.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Wed May  7 2008 Tomas Heinrich <theinric@redhat.com> 0.1.1-2
- removed "BuildRequires: autoconf automake"

* Tue Apr 29 2008 Tomas Heinrich <theinric@redhat.com> 0.1.1-1
- initial build
