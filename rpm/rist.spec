Name:           rist
Version:        %{version}
Release:        %{release}%{distro}
Summary:        RIST tools
URL:            https://code.videolan.org/rist/librist

License:        BSD
Source0:        rist-%{version}.tgz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  meson
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  binutils
BuildRequires:  libcmocka-devel
BuildRequires:  cjson-devel
BuildRequires:  mbedtls-devel
Requires:       librist = %{version}-%{release}

%description
RIST is the "Reliable Internet Stream Transport".
This package provides the basic RIST tools.

%package  -n librist
Summary:  RIST library
Requires: libcmocka
Requires: cjson
Requires: mbedtls

%description -n librist
RIST is the "Reliable Internet Stream Transport".
This package provides the RIST library.

%package -n librist-devel
Summary:  Development files for RIST
Requires: librist = %{version}-%{release}

%description -n librist-devel
RIST is the "Reliable Internet Stream Transport". This package provides the
development environment for applications that use RIST.

# Disable debuginfo package.
%global debug_package %{nil}

%prep
%setup -q -n %{name}-%{version}

%build
mkdir -p build
cd build
meson .. --default-library both
ninja

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir} $RPM_BUILD_ROOT/%{_libdir} $RPM_BUILD_ROOT/%{_includedir}/librist
install -m 755 build/tools/rist2rist build/tools/ristreceiver build/tools/ristsender build/tools/ristsrppasswd $RPM_BUILD_ROOT/%{_bindir}
cp -d build/librist.so build/librist.so.*[0-9] $RPM_BUILD_ROOT/%{_libdir}
chmod 755 $RPM_BUILD_ROOT/%{_libdir}/librist.so*
install -m 644 build/librist.a $RPM_BUILD_ROOT/%{_libdir}
install -m 644 build/include/*.h build/include/librist/*.h include/librist/*.h $RPM_BUILD_ROOT/%{_includedir}/librist

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/rist*

%files -n librist
%defattr(-,root,root,-)
%{_libdir}/librist.so.*
%license COPYING

%files -n librist-devel
%defattr(-,root,root,-)
%{_libdir}/librist.so
%{_libdir}/librist.a
%{_includedir}/librist
