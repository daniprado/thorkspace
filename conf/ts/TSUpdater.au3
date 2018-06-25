; Thorkspace Updater
;
; Copyright (C) 2018 - Daniel Prado (dpradom@argallar.com)
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; This file is written in AutoIT Script (https://www.autoitscript.com/autoit3/docs/)

#Region INCLUDE
#include "lib\TSConstants.au3"
#include "lib\TSPackages.au3"
#EndRegion INCLUDE

#Region CONFIG
#EndRegion CONFIG

#Region SCRIPT
main()
Exit(0)
#EndRegion SCRIPT

#Region MAIN
Func main()

   Local $sGrp, $sPkg, $sVer, $sExt

   If @ScriptDir <> @WorkingDir Then
       FileChangeDir(@ScriptDir)
   EndIf

   LoadPackages()
   SetPackagesNewAndOld()

   If $iRepoLan And Not FileExists($PATH_REPO & "\" & $DIR_BASE) Then
      __startRepoLan() 
   EndIf

   If $iPackagesNew > 0 Then
      __calculateInstall()
      For $i = 0 To $iPackagesInstall - 1
         $sGrp = $aPackagesInstall[$i][0]
         $sPkg = $aPackagesInstall[$i][1]
         $sVer = $aPackagesInstall[$i][2]
         $sExt = "7z"
         DownloadPkg($sGrp, $sPkg, $sVer, $sExt)
         __installPkg($sGrp, $sPkg, $sVer, $sExt)
      Next
   EndIf

   If $iPackagesOld > 0 Then
      ;__calculateUninstall()
      ;For $i = 0 To $iPackagesUninstall - 1
      ;   $sGrp = $aPackagesUninstall[$i][0]
      ;   $sPkg = $aPackagesUninstall[$i][1]
      ;   $sVer = $aPackagesUninstall[$i][2]
      ;   __uninstallPkg($sGrp, $sPkg, $sVer)
      ;Next
   EndIf

   If $iRepoLan Then
      For $i = 0 To $iPackagesRepo - 1
         $sGrp = $aPackagesRepo[$i][1]
         $sPkg = $aPackagesRepo[$i][2]
         $sVer = $aPackagesRepo[$i][3]
         $sExt = "7z"
         If __pkgRepoLanNeeded($sGrp, $sPkg, $sVer, $sExt) Then DownloadPkg($sGrp, $sPkg, $sVer, $sExt, True)
      Next
   EndIf
EndFunc
#EndRegion MAIN

#Region FUNCTIONS
Func __calculateInstall()
   For $i = 0 To $iPackagesNew - 1
      If Not IsInstalled($aPackagesNew[$i]) Then
         For $k = 0 To $iPackagesRepo - 1
            If $aPackagesRepo[$k][2] == $aPackagesNew[$i] Then
               __addPkgToInstall($k)
               ExitLoop
            EndIf
         Next
      EndIf
   Next
EndFunc

Func __calculateUninstall()
; TODO
EndFunc

Func __addPkgToInstall($iPosPkg)
   If $aPackagesRepo[$iPosPkg][4] <> "" Then
      For $i = 1 To StringSplit($aPackagesRepo[$iPosPkg][4], $SEP3)[0]
         Local $sDep = StringSplit($aPackagesRepo[$iPosPkg][4], $SEP3)[$i]
         Local $iDep = SearchRepoPkg($sDep)
         If Not IsInstalled($aPackagesRepo[$iDep][2]) Then
            __addPkgToInstall($iDep)
         EndIF
      Next
   EndIf

   _ArrayAdd($aPackagesInstall, $aPackagesRepo[$iPosPkg][1], 0)
   $aPackagesInstall[$iPackagesInstall][1] = $aPackagesRepo[$iPosPkg][2]
   $aPackagesInstall[$iPackagesInstall][2] = $aPackagesRepo[$iPosPkg][3]
   $iPackagesInstall = $iPackagesInstall + 1
EndFunc

Func __installPkg(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt)
   Local $sFilePath = GetTempFilePath($sGrp, $sPkg, $sVer, $sExt)
   RunWait("7z.exe x " & $sFilePath & " -y -o" & $PATH_ROOT)
   Local $sScript = StringReplace(StringReplace(StringReplace($SCRIPT_INSTALL, $TAG_GRP, $sGrp), $TAG_VER, $sVer), $TAG_PKG, $sPkg)
   If (FileExists($sScript) = 1) Then
      RunWait($EXECUTE & $sScript)
   EndIf
   FileDelete($sFilePath)
EndFunc

Func __uninstallPkg(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt)
   Local $sScript = StringReplace(StringReplace(StringReplace($SCRIPT_UNINSTALL, $TAG_GRP, $sGrp), $TAG_VER, $sVer), $TAG_PKG, $sPkg)
   If (FileExists($sScript) = 1) Then
      RunWait($EXECUTE & $sScript)
   EndIf
   FileDelete($sScript)
EndFunc

Func __startRepoLan()
   DirCreate($PATH_REPO)
   DownloadPkg($GRP_REPO, $PKG_REPO, $sVersion, "", True)
   DownloadPkg($GRP_REPO, "7-Zip", "", "exe", True)
   DownloadPkg($GRP_REPO, "AutoIt", "", "7z", True)
   DownloadPkg($GRP_REPO, "MinGit", "", "7z", True)
   Local $sDestPath = $PATH_REPO & "\thorkspace"
   FileChangeDir($PATH_REPO)
   RunWait("git clone " & $sParmsGit & " " & $sGitUrl & " " & $sDestPath)
   RunWait("7z a " & $sDestPath & ".7z -r " & $sDestPath & "\")
   DirRemove($sDestPath, $DIR_REMOVE)
   FileChangeDir(@ScriptDir)
EndFunc

Func __pkgRepoLanNeeded(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt)

   Local $bResult = True
   If FileExists(GetLanRepoPath($sGrp, $sPkg, $sVer, $sExt)) Then
      $bResult= False
      ; TODO Checksum validation
   EndIf

   return $bResult
EndFunc
#EndRegion FUNCTIONS

