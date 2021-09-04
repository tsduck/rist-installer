<#
 .SYNOPSIS

  Install pre-requisites packages to build RIST on Windows, namely Python and
  Meson. Because of its specific installation system, Visual Studio is not
  installed in this procedure. We assume it is already installed (the free
  Community Edition is fine).

 .PARAMETER ForceDownload

  Force downloads even if packages are already downloaded.

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$ForceDownload = $false,
    [switch]$GitHubActions = $false,
    [switch]$NoPause = $false
)

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
$RootDir = (Split-Path -Parent $PSScriptRoot)
$BuildDir = "$RootDir\build"
[void] (New-Item -Path $BuildDir -ItemType Directory -Force)

# Without this, Invoke-WebRequest is awfully slow.
$ProgressPreference = 'SilentlyContinue'

# Install Python.
Write-Output "Python download and installation procedure"
$DownloadPage = "https://www.python.org/downloads/windows/"
$FallbackURL = "https://www.python.org/ftp/python/3.9.0/python-3.9.0-amd64.exe"

# Get the HTML page for Python downloads.
$status = 0
$message = ""
$Ref = $null
try {
    $response = Invoke-WebRequest -UseBasicParsing -UserAgent Download -Uri $DownloadPage
    $status = [int] [Math]::Floor($response.StatusCode / 100)
}
catch {
    $message = $_.Exception.Message
}

if ($status -ne 1 -and $status -ne 2) {
    # Error fetching download page.
    if ($message -eq "" -and (Test-Path variable:response)) {
        Write-Output "Status code $($response.StatusCode), $($response.StatusDescription)"
    }
    else {
        Write-Output "#### Error accessing ${DownloadPage}: $message"
    }
}
else {
    # Parse HTML page to locate the latest installer.
    $Ref = $response.Links.href | Where-Object { $_ -like "*/python-*-amd64.exe" } | Select-Object -First 1
}

if (-not $Ref) {
    # Could not find a reference to installer.
    $Url = [System.Uri]$FallbackURL
}
else {
    # Build the absolute URL's from base URL (the download page) and href links.
    $Url = New-Object -TypeName 'System.Uri' -ArgumentList ([System.Uri]$DownloadPage, $Ref)
}

$InstallerName = (Split-Path -Leaf $Url.LocalPath)
$InstallerPath = "$BuildDir\$InstallerName"

# Download installer
if (-not $ForceDownload -and (Test-Path $InstallerPath)) {
    Write-Output "$InstallerName already downloaded, use -ForceDownload to download again"
}
else {
    Write-Output "Downloading $Url ..."
    Invoke-WebRequest -UseBasicParsing -UserAgent Download -Uri $Url -OutFile $InstallerPath
    if (-not (Test-Path $InstallerPath)) {
        Exit-Script "$Url download failed"
    }
}

# Run Python installer.
if (-not $NoInstall) {
    Write-Output "Installing $InstallerName"
    Start-Process -FilePath $InstallerPath -ArgumentList @("/quiet", "InstallAllUsers=1", "CompileAll=1", "PrependPath=1", "Include_test=0") -Wait
}

# Make sure the Path from Python installation is fully updated in this script.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

# Install meson using Python pip.
Write-Output "Installing meson using pip3"
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    # Already run as admin
    pip3 install meson
}
else {
    # Run pip3 as administrator, may need to answer UAC.
    Start-Process powershell -Verb runAs -ArgumentList 'pip3 install meson' -Wait
}

Exit-Script
