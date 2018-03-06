Summary:          Make sure release branch dependency versions are locked down
Name:             branch-deps
Version:          1.0.0
Release:          1%{?dist}
License:          APL2.0
URL:              http://github.com/openshift/origin-aggregated-logging
Group:            System Environment/Daemons
BuildRoot:        %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:        noarch

Requires:         skopeo-containers >= 1:0.1.27
Requires:         skopeo-containers < 1:0.1.28
Requires:         docker >= 2:1.12
Requires:         docker < 2:1.13

%description
Make sure release branch dependency versions are locked down so that
we can run logging CI on a specific branch release.

%prep
cat > README<<EOF
Make sure release branch dependency versions are locked down so that
we can run logging CI on a specific branch release.
EOF

%build
# empty

%install
rm -rf $RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc README

%changelog
* Mon Mar 05 2018 Rich Megginson <rmeggins@redhat.com> - 1.0.0-1
- initial commit

