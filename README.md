# RIST installers

[RIST](https://code.videolan.org/rist) is the Reliable Internet Stream Transport.
Its basic library and tools are in project [librist](https://code.videolan.org/rist/librist).

This repository contains scripts to build librist installers for Linux and Windows.

This repository does not contain any third-party source code, neither librist
nor any of its dependencies. It contains only scripts and configuration files
which download third-party source code when necessary and build it.

Subdirectories:

- `deb`: Build on apt-based distros (Debian, Ubuntu, Rapsbian, Mint, etc.)
- `rpm`: Build on rpm-based distros (Red Hat, CentOS, Fedora, Oracle, etc.)
- `win`: Build on Windows, using Visual Studio.

To build the RIST installers on a given platform, run the script `build.sh` or
`build.ps1` in the subdirectory for this platform.

Before building the RIST installers for the first time, make sure to run the
script `install-prerequisites.sh` or `install-prerequisites.ps1` to install
the required building tools.

Temporary subdirectories, created by the scripts, not archived in the repo:

- `installers`: All binary installers are stored here.
- `build`: Used to compile RIST and build the installers.

## Linux

On Linux, the package is named `librist-(version).deb` or `.rpm`, depending on the distro.
The package can be installed using the `dpkg` or `rpm` command, again depending on the distro.

It is expected that, at some point, the librist packages will be included in the major Linux
distros in their standard repositories. In the meantime, binary packages can be found in the
[release area of this project](https://github.com/tsduck/rist-installer/releases).

## Windows

### Installing librist on Windows

On Windows, the executable installer is named `librist-(version).exe`.
Simply run it to install librist.

If automation is required (in a CI/CD pipeline for instance), the sample PowerShell
script `win/install-librist.ps1` can be freely copied in your project. Run it in the
pre-build phase of your CI workflow. The script automatically downloads and installs
the latest version of librist for Windows.

### Building Windows applications with librist

After installing the librist binary, an environment variable named `LIBRIST` is
defined to the installation root (typically `C:\Program Files (x86)\librist`).

In this directory, there are Visual Studio property files to reference either
the librist DLL or static library from the application. Simply reference the
corresponding property file in your Visual Studio project to use librist.

You can also do that manually by editing the application project file (the XML
file named with a `.vcxproj` extension). Add one of the following lines just
before the end of the project file. Select the one you need to reference either
the librist DLL or static library.

~~~
<Import Project="$(LIBRIST)\librist-dll.props"/>
<Import Project="$(LIBRIST)\librist-static.props"/>
~~~

## macOS

This project does not provide binary packages for macOS. On this platform, librist
is installed using [Homebrew](https://brew.sh), the package manager for open-source
projects on macOS.

Use command:
~~~
brew install librist
~~~
