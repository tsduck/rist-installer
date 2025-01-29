# RIST installers

[RIST](https://code.videolan.org/rist) is the Reliable Internet Stream Transport.
Its basic library and tools are in project [librist](https://code.videolan.org/rist/librist).

This repository contains scripts to build librist installers for Windows.

In 2021, when this installer project was created, librist was not available on
any Linux distro. The project contained scripts to build `.rpm` and `.deb`
installers for Linux. Now, in 2025, all major Linux distros include librist
and this part of the installer project is no longer necessary and was deleted.
This project now only provides librist installers for Windows.

On macOS, librist is installed using [Homebrew](https://brew.sh), the package
manager for open-source projects on macOS. Use command `brew install librist`.

This repository does not contain any third-party source code, neither librist
nor any of its dependencies. It contains only scripts and configuration files
which download third-party source code when necessary and build it.

Before building the RIST installers for the first time, make sure to run the
script `install-prerequisites.ps1` to install the required building tools.

Temporary subdirectories, created by the scripts, not archived in the repo:

- `installers`: All binary installers are stored here.
- `build`: Used to compile RIST and build the installers.

## Installing librist on Windows

On Windows, the executable installer is named `librist-(version).exe`.
Simply run it to install librist.

If automation is required (in a CI/CD pipeline for instance), the sample PowerShell
script `win/install-librist.ps1` can be freely copied in your project. Run it in the
pre-build phase of your CI workflow. The script automatically downloads and installs
the latest version of librist for Windows.

## Building Windows applications with librist

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
