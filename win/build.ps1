#-----------------------------------------------------------------------------
#
#  RIST library installers
#  Copyright (c) 2021, Thierry Lelegard
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#  THE POSSIBILITY OF SUCH DAMAGE.
#
#-----------------------------------------------------------------------------

<#
 .SYNOPSIS

  Build the RIST library installer for Windows.

 .PARAMETER BareVersion

  Use the "bare version" number from librist, without commit id if there is
  no tag on the current commit. By default, use a detailed version number
  (most recent version, number of commits since then, short commit SHA).

 .PARAMETER Clean

  Cleanup the build directory and exit. Do not build anything.

 .PARAMETER NoBuild

  Do not rebuild RIST library and tools. Assume that they are already built.
  Only build the installer.

 .PARAMETER NoGit

  Do not clone or update the librist repository. Assume it is already up to
  date and use the current state.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.

 .PARAMETER Tag

  Specify the git tag or commit to build. By default, use the latest repo
  state.
#>
[CmdletBinding()]
param(
    [switch]$BareVersion = $false,
    [switch]$Clean = $false,
    [switch]$NoBuild = $false,
    [switch]$NoGit = $false,
    [switch]$NoPause = $false,
    [string]$Tag = ""
)

Write-Output "RIST library installer build procedure"

# A function to exit this script.
function Exit-Script([string]$Message = "")
{
    $Code = 0
    if ($Message -ne "") {
        Write-Host "ERROR: $Message"
        $Code = 1
    }
    if (-not $NoPause) {
        pause
    }
    exit $Code
}

# Local directories.
$ScriptDir = $PSScriptRoot
$RootDir = (Split-Path -Parent $PSScriptRoot)
$InstallerDir = "$RootDir\installers"
$BuildDir = "$RootDir\build"
$RepoDir = "$BuildDir\librist"
$PreInstallDir = "$BuildDir\install"

# Cleanup when required.
if ($Clean) {
    Write-Output "Cleaning up build directories ..."
    Remove-Item $BuildDir -Force -Recurse -ErrorAction SilentlyContinue
    Exit-Script
}

# Create local build directories.
[void] (New-Item -Path $BuildDir -ItemType Directory -Force)
[void] (New-Item -Path $PreInstallDir -ItemType Directory -Force)
[void] (New-Item -Path $InstallerDir -ItemType Directory -Force)

# Locate NSIS, the Nullsoft Scriptable Installation System.
Write-Output "Searching NSIS ..."
$NSIS = Get-Item "C:\Program Files*\NSIS\makensis.exe" | ForEach-Object { $_.FullName} | Select-Object -Last 1
if (-not $NSIS) {
    Exit-Script "NSIS not found"
}

# A function to cleanup the build directories.
function Cleanup-Build()
{
    foreach ($Conf in @("Release", "Debug")) {
        foreach ($Arch in @("Win32", "x64")) {
            Remove-Item $BuildDir\${Conf}-${Arch} -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

# Update Git repository.
if ((-not $NoGit) -and (-not $NoBuild)) {

    # Get URL of repo from URL.txt file in root directory (remove comments, keep one line).
    $RepoUrl = ((Get-Content ..\URL.txt) -notmatch '^ *$' -notmatch '^ *#' | Select-Object -Last 1)

    # Clone repository or update it.
    # Note that git outputs its log on stderr, so use --quiet.
    if (Test-Path "$RepoDir\.git") {
        # The repo is already cloned, just update it.
        Write-Output "Updating repository ..."
        Push-Location $RepoDir
        git checkout master --quiet
        git pull origin master
        Pop-Location
    }
    else {
        # Clone the repo.
        Write-Output "Cloning $RepoUrl ..."
        git clone --quiet $RepoUrl $RepoDir
        if (-not (Test-Path "$RepoDir\.git")) {
            Exit-Script "Failed to clone $RepoUrl"
        }
    }

    # Checkout the required tag. Cleanup the build directories to restart from scratch.
    if ($Tag.Length -gt 0) {
        Write-Output "Checking out $Tag ..."
        Push-Location $RepoDir
        git checkout --quiet $Tag
        Pop-Location
        Cleanup-Build
    }
}

# Get librist version from repository.
Push-Location $RepoDir
if ($BareVersion) {
    $Version = (git describe --tags) -replace '^v','' -replace '-g.*',''
}
else {
    $Version = (git describe --tags) -replace '^v','' -replace '-g','-'
}
Pop-Location

# Split version string in pieces and make sure it has at least four elements (Windows version info format).
$VField = ($Version -split "[-\. ]") + @("0", "0", "0", "0") | Select-String -Pattern '^\d*$'
$VersionInfo = "$($VField[0]).$($VField[1]).$($VField[2]).$($VField[3])"

Write-Output "RIST version is $Version, Windows version info is $VersionInfo"

# Build only if necessary.
if (-not $NoBuild) {

    # Get local architecture.
    if ([System.IntPtr]::Size -eq 4) {
        $LocalArch = "Win32"
        $OtherArch = "x64"
    }
    else {
        $LocalArch = "x64"
        $OtherArch = "Win32"
    }

    # Build all build scripts using meson for local architecture.
    Cleanup-Build
    meson setup --backend vs2019 --buildtype release --default-library both $BuildDir\Release-${LocalArch} $RepoDir
    meson setup --backend vs2019 --buildtype debug   --default-library both $BuildDir\Debug-${LocalArch}   $RepoDir

    # Currently, there is no way to build for the "other" architecture with meson.
    # See: https://code.videolan.org/rist/librist/-/issues/123

    # Manually craft the build environment for the "other" architecture.
    #@@@ foreach ($Conf in @("Release", "Debug")) {
    #@@@     $local = "$BuildDir\${Conf}-${LocalArch}"
    #@@@     $other = "$BuildDir\${Conf}-${OtherArch}"
    #@@@     # Copy-Item -Force -Recurse $BuildDir\${Conf}-${LocalArch} $BuildDir\${Conf}-${OtherArch}
    #@@@     # Get-ChildItem -Recurse -Name $BuildDir\${Conf}-${OtherArch} | ForEach-Object {
    #@@@     Get-ChildItem -Recurse -Name $local | ForEach-Object {
    #@@@         $name = $_
    #@@@         if (Test-Path "$local\$name" -PathType Container) {
    #@@@             Write-Output "===> creating $other\$name"
    #@@@             [void] (New-Item -Path "$other\$name" -ItemType Directory -Force)
    #@@@         }
    #@@@         else {
    #@@@             (Get-Content -Raw "$local\$name") -replace "$LocalArch","$OtherArch" | Set-Content -Force "$other\$name"
    #@@@             # $file = "$BuildDir\${Conf}-${OtherArch}\$_"
    #@@@             # (Get-Content -Raw ${file}) -replace "$LocalArch","$OtherArch" | Set-Content -Force "${file}.new"
    #@@@             # Move-Item -Force "${file}.new" ${file}
    #@@@         }
    #@@@     }
    #@@@ }

    # Build librist in all configurations.
    foreach ($Conf in @("Release", "Debug")) {
        meson compile -C $BuildDir\${Conf}-${LocalArch}
    }
}

# Only when using single architecture.
$ArchName = "-" + ($LocalArch -replace "x64","Win64")

# Build the binary installer.
# Remove /DArch when we can build 32 and 64-bit versions at the same time.
Write-Output "Building installer ..."
& $NSIS /V2 `
    /DProductName=librist `    /DVersion=$Version `    /DVersionInfo=$VersionInfo `    /DOutputName=librist${ArchName}-${Version} `    /DArch=$LocalArch `    /DScriptDir=$ScriptDir `    /DRepoDir=$RepoDir `    /DBuildDir=$BuildDir `    /DInstallerDir=$InstallerDir `    "$ScriptDir\librist.nsi"

Exit-Script -NoPause:$NoPause
