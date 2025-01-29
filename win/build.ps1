﻿#-----------------------------------------------------------------------------
#
#  RIST library installers
#  Copyright (c) 2021-2025, Thierry Lelegard
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

 .PARAMETER Branch

  Switch to the specified local branch after updating the repository.
  Useful when local patches are not yet merged in the main repository.

 .PARAMETER Clean

  Cleanup the build directory and exit. Do not build anything.

 .PARAMETER GitHubActions

  When used in a GitHub Action workflow, define the INSTALLER_EXE
  environment variable with the base name of the binary installer file.

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
    [string]$Branch = "",
    [switch]$Clean = $false,
    [switch]$GitHubActions = $false,
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

# Cleanup when required.
if ($Clean) {
    Write-Output "Cleaning up build directories ..."
    Remove-Item $BuildDir -Force -Recurse -ErrorAction SilentlyContinue
    Exit-Script
}

# Create local build directories.
[void] (New-Item -Path $BuildDir -ItemType Directory -Force)
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
        foreach ($Arch in @("Win32", "x64", "Arm64")) {
            Remove-Item $BuildDir\${Conf}-${Arch} -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

# Update Git repository.
if ((-not $NoGit) -and (-not $NoBuild)) {

    # Get URL of repo from URL.txt file in root directory (remove comments, keep one line).
    $RepoUrl = ((Get-Content "$RootDir\URL.txt") -notmatch '^ *$' -notmatch '^ *#' -match '^URL=' -replace 'URL=','' | Select-Object -Last 1)
    $RepoBranch = ((Get-Content "$RootDir\URL.txt") -notmatch '^ *$' -notmatch '^ *#' -match '^BRANCH=' -replace 'BRANCH=','' | Select-Object -Last 1)

    # Clone repository or update it.
    # Note that git outputs its log on stderr, so use --quiet.
    if (Test-Path "$RepoDir\.git") {
        # The repo is already cloned, just update it.
        Write-Output "Updating repository ..."
        Push-Location $RepoDir
        git checkout $RepoBranch --quiet
        git pull origin $RepoBranch --quiet
        Pop-Location
    }
    else {
        # Clone the repo.
        Write-Output "Cloning $RepoUrl ..."
        git clone --quiet $RepoUrl $RepoDir
        if (-not (Test-Path "$RepoDir\.git")) {
            Exit-Script "Failed to clone $RepoUrl"
        }
        Push-Location $RepoDir
        git checkout $RepoBranch --quiet
        Pop-Location
    }

    # Checkout the required tag. Cleanup the build directories to restart from scratch.
    if ($Tag.Length -gt 0) {
        Write-Output "Checking out $Tag ..."
        Push-Location $RepoDir
        git checkout --quiet $Tag
        Pop-Location
        Cleanup-Build
    }
    elseif ($Branch -ne "") {
        Write-Output "Checking out branch $Branch ..."
        Push-Location $RepoDir
        git checkout $Branch --quiet
        Pop-Location
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

# A function to build librist for a given architecture.
function Build-OnArch([string]$Arch, [string]$InitScript)
{
    # Setup environment for compilation: search initialization script.
    $Script = (Get-ChildItem -Recurse -Path "C:\Program Files*\Microsoft Visual Studio" -Include $InitScript | Select-Object -First 1).FullName
    if (-not $Script) {
        Exit-Script "$InitScript not found in Visual Studio"
    }

    # Run the CMD script, get all environment variable, set modified ones.
    $PreviousEnv = @{}
    cmd /Q /a /d /c "`"$Script`" & set" | Select-string "^[a-zA-Z0-9_]*=" | ForEach-Object {
        $s = $_ -split "=",2
        $name = $s[0]
        $value = $s[1]
        $previous = (Get-Item env:$name -ErrorAction SilentlyContinue).Value
        if ($value -ne $previous) {
            $PreviousEnv[$name] = $previous
            Set-Item env:$name $value
        }
    }
 
    # Generate Visual Studio projet files.
    meson setup --backend vs2022 --buildtype release --default-library both $BuildDir\Release-${Arch} $RepoDir
    meson setup --backend vs2022 --buildtype debug   --default-library both $BuildDir\Debug-${Arch}   $RepoDir

    # Build using Visual Studio.
    meson compile -C $BuildDir\Release-${Arch}
    meson compile -C $BuildDir\Debug-${Arch}

    # Restore previous environment variables.
    $PreviousEnv.GetEnumerator() | ForEach-Object {
        $name = $_.Name
        Set-Item env:$name $_.Value
    }
}

# Build only if necessary.
if (-not $NoBuild) {

    Cleanup-Build

    # Get local architecture.
    if ($env:PROCESSOR_ARCHITECTURE -like 'arm64*') {
        Build-OnArch "Arm64" "vcvarsarm64.bat"
        Build-OnArch "x64"   "vcvarsarm64_amd64.bat"
        Build-OnArch "Win32" "vcvarsarm64_x86.bat"
    }
    elseif ($env:PROCESSOR_ARCHITECTURE -like 'amd64*') {
        Build-OnArch "Arm64" "vcvarsamd64_arm64.bat"
        Build-OnArch "x64"   "vcvars64.bat"
        Build-OnArch "Win32" "vcvarsamd64_x86.bat"
    }
    elseif ($env:PROCESSOR_ARCHITECTURE -like 'x86*') {
        Build-OnArch "Arm64" "vcvarsx86_arm64.bat"
        Build-OnArch "x64"   "vcvarsx86_amd64.bat"
        Build-OnArch "Win32" "vcvars32.bat"
    }
    else {
        Exit-Script "Unknown architecture ${env:PROCESSOR_ARCHITECTURE}"
    }
}

# Build the binary installer.
Write-Output "Building installer ..."
& $NSIS /V2 `
    /DProductName=librist `
    /DVersion=$Version `
    /DVersionInfo=$VersionInfo `
    /DScriptDir=$ScriptDir `
    /DRepoDir=$RepoDir `
    /DBuildDir=$BuildDir `
    /DInstallerDir=$InstallerDir `
    "$ScriptDir\librist.nsi"

# Define INSTALLER_EXE in GitHub Actions.
if ($GitHubActions) {
    Write-Output "INSTALLER_EXE=librist-${Version}.exe" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
}

Exit-Script -NoPause:$NoPause
