Name:           librist
Version:        %{version}
Release:        %{release}%{distro}
Summary:        RIST library and tools
URL:            https://code.videolan.org/rist/librist

License:        BSD
Source0:        librist-%{version}.tgz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  meson
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  binutils
BuildRequires:  libcmocka-devel
BuildRequires:  cjson-devel
BuildRequires:  mbedtls-devel
Requires:       libcmocka
Requires:       cjson
Requires:       mbedtls

%description
Reliable Internet Stream Transport (RIST)

# Disable debuginfo package.
%global debug_package %{nil}

%prep
%setup -q -n %{name}-%{version}

%build
%meson --default-library both
%meson_build

%install
%meson_install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/rist*
%{_libdir}/librist.so*
%{_libdir}/librist.a
%{_includedir}/librist
%license COPYING

