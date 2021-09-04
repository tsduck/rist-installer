# RIST installers

[RIST](https://code.videolan.org/rist) is the Reliable Internet Stream Transport.

This repository contains scripts to build RIST installers for Linux and Windows.

This repository does not contain any third-party source code, neither librist
nor any of its dependencies. It contains only scripts and configuration files
which download third-party source code when necessary and build it.

Subdirectories:

- `deb`: Build on apt-based distros (Debian, Ubuntu, Rapsbian, Mint, etc.)
- `rpm`: Build on rpm-based distros (Red Hat, CentOS, Fedora, Oracle, etc.)
- `win`: Build on Windows, using Visual Studio.

To build the RIST installers on a given platform, run the script `build.sh` or
`build.ps1` in the subdirectory for this platform.

Temporary subdirectories, created by the scripts, not archived in the repo:

- `installers`: All binary installers are stored here.
- `build`: Used to compile RIST and build the installers.

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
