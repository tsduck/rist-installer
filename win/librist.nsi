;-----------------------------------------------------------------------------
;
;  RIST library installers
;  Copyright (c) 2021-2025, Thierry Lelegard
;  All rights reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are met:
;
;  1. Redistributions of source code must retain the above copyright notice,
;     this list of conditions and the following disclaimer.
;  2. Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
;
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
;  THE POSSIBILITY OF SUCH DAMAGE.
;
;-----------------------------------------------------------------------------
;
; NSIS script to build the RIST binary libraries installer for Windows.
; Do not invoke NSIS directly, use PowerShell script win\build.ps1.
;
;-----------------------------------------------------------------------------

Name "RIST"
Caption "RIST Libraries Installer"

!verbose push
!verbose 0
!include "MUI2.nsh"
!include "Sections.nsh"
!include "TextFunc.nsh"
!include "WordFunc.nsh"
!include "FileFunc.nsh"
!include "WinMessages.nsh"
!include "x64.nsh"
!verbose pop

; Installer file information.
VIProductVersion ${VersionInfo}
VIAddVersionKey ProductName "${ProductName}"
VIAddVersionKey ProductVersion "${Version}"
VIAddVersionKey Comments "The RIST libraries for Visual C++ on Windows"
VIAddVersionKey CompanyName "VideoLAN and librist"
VIAddVersionKey LegalCopyright "Copyright (c) 2029 SipRadius LLC, VideoLAN and librist authors"
VIAddVersionKey FileVersion "${VersionInfo}"
VIAddVersionKey FileDescription "RIST Installer"

; Name of binary installer file.
OutFile "${InstallerDir}\${ProductName}-${Version}.exe"

; Generate a Unicode installer (default is ANSI).
Unicode true

; Registry key for environment variables
!define EnvironmentKey '"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

; Registry entry for product info and uninstallation info.
!define ProductKey "Software\${ProductName}"
!define UninstallKey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${ProductName}"

; Use XP manifest.
XPStyle on

; Request administrator privileges for Windows Vista and higher.
RequestExecutionLevel admin

; "Modern User Interface" (MUI) settings.
!define MUI_ABORTWARNING

; Default installation folder.
InstallDir "$PROGRAMFILES\${ProductName}"

; Get installation folder from registry if available from a previous installation.
InstallDirRegKey HKLM "${ProductKey}" "InstallDir"

; Installer pages.
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

; Uninstaller pages.
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages.
!insertmacro MUI_LANGUAGE "English"

; Installation initialization.
function .onInit
    ; In 64-bit installers, don't use registry redirection.
    ${If} ${RunningX64}
    ${OrIf} ${IsNativeARM64}
        SetRegView 64
    ${EndIf}
functionEnd

; Uninstallation initialization.
function un.onInit
    ; In 64-bit installers, don't use registry redirection.
    ${If} ${RunningX64}
    ${OrIf} ${IsNativeARM64}
        SetRegView 64
    ${EndIf}
functionEnd

; Installation section
Section "Install"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Visual Studio property files.
    SetOutPath "$INSTDIR"
    File /oname=COPYING.txt "${RepoDir}\COPYING"
    File "${ScriptDir}\librist-common.props"
    File "${ScriptDir}\librist-dll.props"
    File "${ScriptDir}\librist-static.props"
    Delete "${ScriptDir}\librist.props"

    ; Header files.
    CreateDirectory "$INSTDIR\include"
    CreateDirectory "$INSTDIR\include\librist"
    SetOutPath "$INSTDIR\include\librist"
    File "${RepoDir}\include\librist\*.h"
    File "${BuildDir}\Release-x64\include\librist\*.h"
    File "${BuildDir}\Release-x64\include\vcs_version.h"

    ; Libraries.
    CreateDirectory "$INSTDIR\lib"

    ; Arm64 libraries.
    CreateDirectory "$INSTDIR\lib\Release-ARM64"
    SetOutPath "$INSTDIR\lib\Release-ARM64"
    File "${BuildDir}\Release-ARM64\librist.dll"
    File "${BuildDir}\Release-ARM64\librist.lib"
    File "${BuildDir}\Release-ARM64\librist.a"

    CreateDirectory "$INSTDIR\lib\Debug-ARM64"
    SetOutPath "$INSTDIR\lib\Debug-ARM64"
    File "${BuildDir}\Debug-ARM64\librist.dll"
    File "${BuildDir}\Debug-ARM64\librist.lib"
    File "${BuildDir}\Debug-ARM64\librist.a"

    ; Win64 libraries.
    CreateDirectory "$INSTDIR\lib\Release-x64"
    SetOutPath "$INSTDIR\lib\Release-x64"
    File "${BuildDir}\Release-x64\librist.dll"
    File "${BuildDir}\Release-x64\librist.lib"
    File "${BuildDir}\Release-x64\librist.a"

    CreateDirectory "$INSTDIR\lib\Debug-x64"
    SetOutPath "$INSTDIR\lib\Debug-x64"
    File "${BuildDir}\Debug-x64\librist.dll"
    File "${BuildDir}\Debug-x64\librist.lib"
    File "${BuildDir}\Debug-x64\librist.a"

    ; Win32 libraries.
    CreateDirectory "$INSTDIR\lib\Release-Win32"
    SetOutPath "$INSTDIR\lib\Release-Win32"
    File "${BuildDir}\Release-Win32\librist.dll"
    File "${BuildDir}\Release-Win32\librist.lib"
    File "${BuildDir}\Release-Win32\librist.a"

    CreateDirectory "$INSTDIR\lib\Debug-Win32"
    SetOutPath "$INSTDIR\lib\Debug-Win32"
    File "${BuildDir}\Debug-Win32\librist.dll"
    File "${BuildDir}\Debug-Win32\librist.lib"
    File "${BuildDir}\Debug-Win32\librist.a"

    ; Tools.
    CreateDirectory "$INSTDIR\bin"
    SetOutPath "$INSTDIR\bin"
    ${If} ${IsNativeARM64}
        File "${BuildDir}\Release-ARM64\librist.dll"
        File "${BuildDir}\Release-ARM64\tools\rist2rist.exe"
        File "${BuildDir}\Release-ARM64\tools\ristreceiver.exe"
        File "${BuildDir}\Release-ARM64\tools\ristsender.exe"
        File "${BuildDir}\Release-ARM64\tools\ristsrppasswd.exe"
    ${ElseIf} ${RunningX64}
        File "${BuildDir}\Release-x64\librist.dll"
        File "${BuildDir}\Release-x64\tools\rist2rist.exe"
        File "${BuildDir}\Release-x64\tools\ristreceiver.exe"
        File "${BuildDir}\Release-x64\tools\ristsender.exe"
        File "${BuildDir}\Release-x64\tools\ristsrppasswd.exe"
    ${Else}
        File "${BuildDir}\Release-Win32\librist.dll"
        File "${BuildDir}\Release-Win32\tools\rist2rist.exe"
        File "${BuildDir}\Release-Win32\tools\ristreceiver.exe"
        File "${BuildDir}\Release-Win32\tools\ristsender.exe"
        File "${BuildDir}\Release-Win32\tools\ristsrppasswd.exe"
    ${EndIf}

    ; Add an environment variable to installation root.
    WriteRegStr HKLM ${EnvironmentKey} "LIBRIST" "$INSTDIR"

    ; Store installation folder in registry.
    WriteRegStr HKLM "${ProductKey}" "InstallDir" $INSTDIR

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
 
    ; Declare uninstaller in "Add/Remove Software" control panel
    WriteRegStr HKLM "${UninstallKey}" "DisplayName" "${ProductName}"
    WriteRegStr HKLM "${UninstallKey}" "Publisher" "VideoLAN and librist"
    WriteRegStr HKLM "${UninstallKey}" "URLInfoAbout" "https://code.videolan.org/rist/librist"
    WriteRegStr HKLM "${UninstallKey}" "DisplayVersion" "${Version}"
    WriteRegStr HKLM "${UninstallKey}" "DisplayIcon" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "${UninstallKey}" "UninstallString" "$INSTDIR\Uninstall.exe"

    ; Get estimated size of installed files
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "${UninstallKey}" "EstimatedSize" "$0"

    ; Notify applications of environment modifications
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

SectionEnd

; Uninstallation section
Section "Uninstall"

    ; Work on "all users" context, not current user.
    SetShellVarContext all

    ; Get installation folder from registry
    ReadRegStr $0 HKLM "${ProductKey}" "InstallDir"

    ; Delete product registry entries
    DeleteRegKey HKCU "${ProductKey}"
    DeleteRegKey HKLM "${ProductKey}"
    DeleteRegKey HKLM "${UninstallKey}"
    DeleteRegValue HKLM ${EnvironmentKey} "LIBRIST"

    ; Delete product files.
    RMDir /r "$0\include"
    RMDir /r "$0\bin"
    RMDir /r "$0\lib"
    Delete "$0\librist-common.props"
    Delete "$0\librist-dll.props"
    Delete "$0\librist-static.props"
    Delete "$0\COPYING.txt"
    Delete "$0\Uninstall.exe"
    RMDir "$0"

    ; Notify applications of environment modifications
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

SectionEnd
