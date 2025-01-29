<#
 .SYNOPSIS

  Install pre-requisites packages to build RIST on Windows, namely NSIS and
  Meson. Because of its specific installation system, Visual Studio is not
  installed in this procedure. We assume it is already installed (the free
  Community Edition is fine).

 .PARAMETER NoPause

  Do not wait for the user to press <enter> at end of execution. By default,
  execute a "pause" instruction at the end of execution, which is useful
  when the script was run from Windows Explorer.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$NoPause = $false)

$ProgressPreference = 'SilentlyContinue'

Write-Output "==== WinGet installation"
. "$PSScriptRoot\winget-install.ps1"

Write-Output "==== NSIS installation"
winget install NSIS.NSIS --accept-source-agreements

Write-Output "==== Meson installation"
winget install mesonbuild.meson --accept-source-agreements

if (-not $NoPause) {
    pause
}
