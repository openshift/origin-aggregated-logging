Name:		libfastjson
Version:	0.99.8
Release:	2%{?dist}
Summary:	A JSON implementation in C
License:	MIT
URL:		https://github.com/rsyslog/libfastjson

BuildRequires: autoconf automake libtool

%description
LIBFASTJSON implements a reference counting object
model that allows you to easily construct JSON
objects in C, output them as JSON formatted strings
and parse JSON formatted strings back into the
C representation of JSON objects.

%package	devel
Summary:	Development files for libfastjson
Group:		Development/Libraries
Requires:	%{name}%{?_isa} = %{version}-%{release}

%description	devel
This package contains libraries and header files for
developing applications that use libfastjson.

%prep
%setup -q

for doc in ChangeLog; do
 iconv -f iso-8859-1 -t utf8 $doc > $doc.new &&
 touch -r $doc $doc.new &&
 mv $doc.new $doc
done

%build
autoreconf -iv
export CFLAGS="$RPM_OPT_FLAGS -D_GNU_SOURCE" # temporary workaround for EPEL5, fixed upstream
%configure --enable-shared --disable-static

%install
make V=1 DESTDIR=%{buildroot} install
find %{buildroot} -name '*.la' -delete -print

%check
make V=1 check

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig

%files
%{!?_licensedir:%global license %%doc}
%license COPYING
%doc AUTHORS ChangeLog README.html
%{_libdir}/libfastjson.so.*

%files devel
%{_includedir}/libfastjson
%{_libdir}/libfastjson.so
%{_libdir}/pkgconfig/libfastjson.pc

%changelog
* Wed Feb 07 2018 Fedora Release Engineering <releng@fedoraproject.org> - 0.99.8-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Thu Jan 11 2018 Jiri Vymazal <jvymazal@redhat.com> - 0.99.8-1
- rebase to v0.99.8

* Mon Oct 23 2017 Radovan Sroka <rsroka@redhat.com> - 0.99.7-1
- rebase to v0.99.7

* Tue Aug 15 2017 Marek Tamaskovic <mtamasko@redhat.com> - 0.99.6-1
- rebase to v0.99.6

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.99.5-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Wed Jul 26 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.99.5-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Mon May 22 2017 Radovan Sroka <rsroka@redhat.com> - 0.99.5-1
- added autoreconf
- rebase to v0.99.5

* Fri Feb 10 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.99.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Tue Sep 27 2016 Radovan Sroka <rsroka@redhat.com> - 0.99.4-1
- Package created
