; Thorkspace Packages
;
; Copyright (C) 2017-2018 - Daniel Prado (dpradom@argallar.com)
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
; This file is written in AutoIT Script (https://www.autoitscript.com/autoit3/docs)

#Region INCLUDE
#include <Array.au3>
#include <File.au3>
#include "TSConstants.au3"
#EndRegion INCLUDE

#Region CONFIG
Global $sVersion = ""
Global $sBuild = ""
Global $sServer = ""
Global $sUrl = ""
Global $sCred = ""
Global $sProxy = ""
Global $iRepoLan = 0
Global $sGitUrl = ""
Global $sParmsGit = ""
Global $sParmsCurl = ""

Global $aPackagesNew[0]
Global $iPackagesNew = 0
Global $aPackagesOld[0]
Global $iPackagesOld = 0

; Installing, uninstalling and installed Pkg data
; 0 - Group
; 1 - Name
; 2 - Version
Global $aPackagesInstall[0][3]
Global $iPackagesInstall = 0
Global $aPackagesUninstall[0][3]
Global $iPackagesUninstall = 0
Global $aPackagesInstalled[0][3]
Global $iPackagesInstalled = 0

Global $sRepoVersion = ""
Global $sRepoBuild = ""
; Repository Pkg data
; 0 - Code
; 1 - Group
; 2 - Name (cannot include '(' char)
; 3 - Version
; 4 - Dependency codes
; 5 - Version comment
; 6 - Default
Global $aPackagesRepo[0][7]
Global $iPackagesRepo = 0
#EndRegion CONFIG

#Region FUNCTION
Func LoadPackages()
   __loadConfigFile()
   __loadInstalledPackages()
   __loadPkgRepository()
EndFunc

Func GetPackagesNewAndOld()
   Local $sPackagesNew = ""
   For $i = 0 To $iPackagesNew - 1
      $sPackagesNew = $sPackagesNew & $aPackagesNew[$i] & $SEP
   Next
   If $iPackagesNew > 0 Then
      FileWriteLine($PATH_UPDATERTRIGGER, $ENV_INST & "=" & StringLeft($sPackagesNew, StringLen($sPackagesNew) - 1))
   EndIf

   Local $sPackagesOld = ""
   For $i = 0 To $iPackagesOld - 1
      $sPackagesOld = $sPackagesOld & $aPackagesOld[$i] & $SEP
   Next
   If $iPackagesOld > 0 Then
      FileWriteLine($PATH_UPDATERTRIGGER, $ENV_UNINST & "=" & StringLeft($sPackagesOld, StringLen($sPackagesOld) - 1))
   EndIf
   If $iPackagesNew = 0 And $iPackagesOld = 0 Then FileDelete($PATH_UPDATERTRIGGER)
EndFunc

Func SetPackagesNewAndOld()

   Local $fPackages = FileOpen($PATH_UPDATERTRIGGER, $FO_READ)
   While 1
      Local $sPackages = FileReadLine($fPackages)
      If @error Then ExitLoop
      Local $sSplit = StringSplit($sPackages, "=", $STR_NOCOUNT)
      If $sSplit[0] = $ENV_INST Then
         $aPackagesNew = StringSplit($sSplit[1], $SEP, $STR_NOCOUNT)
         $iPackagesNew = UBound($aPackagesNew)
      ElseIF $sSplit[1] = $ENV_UNINST Then
         $aPackagesOld = StringSplit($sSplit[1], $SEP, $STR_NOCOUNT)
         $iPackagesOld = UBound($aPackagesOld)
      Else
         Exit(1)
      EndIf
   Wend
   FileDelete($PATH_UPDATERTRIGGER)
EndFunc

Func DownloadPkg(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt, Const $bRepoOnly = False)
 Local $sProx = ""
   If $sProxy <> "" Then $sProx = " -x " & $sProxy
   Local $sDestPath = GetTempFilePath($sGrp, $sPkg, $sVer, $sExt) 
   Switch $sServer
      Case $SERV_ARTIFACTORY
         RunWait("curl " & $sParmsCurl & " -o " & $sDestPath & $sProx & " -u" & $sCred & " " & $sUrl & GetPkgUri($sGrp, $sPkg, $sVer, $sExt))
         If @error <> 0 Then
            MsgBox(0, "Error!", "Problem downloading package: " & $sGrp & "/" & $sPkg)
            Exit(1)
         EndIf
      Case $SERV_LANREPO
         RunWait("curl " & $sParmsCurl & " -o " & $sDestPath & " " & $sUrl & GetPkgUri($sGrp, $sPkg, $sVer, $sExt))
      Case $SERV_LOCAL
         FileCopy($sUrl & StringReplace(GetPkgUri($sGrp, $sPkg, $sVer, $sExt), "/", "\"), $sDestPath)
   EndSwitch
   ; TODO Tratamiento de fichero no encontrado!

   If $iRepoLan Then
      Local $sRepoPath = GetLanRepoPath($sGrp, $sPkg, $sVer, $sExt)
      If $bRepoOnly Then 
         FileMove($sDestPath, $sRepoPath, $FC_OVERWRITE + $FC_CREATEPATH)
      Else 
         FileCopy($sDestPath, $sRepoPath, $FC_OVERWRITE + $FC_CREATEPATH)
      EndIf
   EndIf

   return $sDestPath
EndFunc

Func GetPkgUri(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt)
   Local $sGrpo = ""
   If $sGrp <> "" Then $sGrpo = "/" & $sGrp
   Local $sVero = ""
   If $sVer <> "" Then $sVero = "_" & $sVer
   Local $sExto = ""
   If $sExt <> "" Then $sExto = "." & $sExt
  
   return StringReplace(StringReplace(StringReplace(StringReplace($PATTERN_PKGURI, $TAG_EXT, $sExto), $TAG_VER, $sVero), $TAG_PKG, $sPkg), $TAG_GRP, $sGrpo)
EndFunc

Func GetTempFilePath(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt)
   Local $sGrpo = ""
   If $sGrp <> "" Then $sGrpo = "/" & $sGrp
   Local $sVero = ""
   If $sVer <> "" Then $sVero = "_" & $sVer
   Local $sExto = ""
   If $sExt <> "" Then $sExto = "." & $sExt
 
   return StringReplace(StringReplace(StringReplace(StringReplace($PATH_PKGFILE, $TAG_EXT, $sExto), $TAG_VER, $sVero), $TAG_PKG, $sPkg), $TAG_GRP, $sGrpo)
EndFunc

Func GetLanRepoPath(Const $sGrp, Const $sPkg, Const $sVer, Const $sExt)
   Local $sGrpl = ""
   If $sGrp <> "" Then $sGrpl = "\" & $sGrp
   Local $sVero = ""
   If $sVer <> "" Then $sVero = "_" & $sVer
   Local $sExto = ""
   If $sExt <> "" Then $sExto = "." & $sExt
  
   return StringReplace(StringReplace(StringReplace(StringReplace($PATH_REPOLAN, $TAG_EXT, $sExto), $TAG_VER, $sVero), $TAG_PKG, $sPkg), $TAG_GRP, $sGrpl)
EndFunc

Func IsInstalled(Const $sName)
   For $i = 0 To $iPackagesInstalled - 1
      If $aPackagesInstalled[$i][1] == $sName Then return True
   Next
   For $i = 0 To $iPackagesInstall - 1
      If $aPackagesInstall[$i][1] == $sName Then return True
   Next
   return False
EndFunc

Func GetCode(Const $sName)
   For $i = 0 To $iPackagesRepo - 1
      If $sName == $aPackagesRepo[$i][2] Then return $aPackagesRepo[$i][0]
   Next
   return "00"
EndFunc

Func GetDependencies(Const $sName)
   Local $aResult[1]
   Local $aDeps[0]
   For $i = 0 To $iPackagesRepo - 1
      If $sName == $aPackagesRepo[$i][2] Then $aDeps = StringSplit($aPackagesRepo[$i][4], $SEP3)
   Next
   For $i = 1 To $aDeps[0]
      _ArrayAdd($aResult, SearchRepoPkg($aDeps[$i]))
      $aResult[0] = $aResult[0] + 1
   Next
   return $aResult
EndFunc

Func GetDependents(Const $sName)
   Local $aResult[1]
   Local $sCode
   For $i = 0 To $iPackagesRepo - 1
      If $sName == $aPackagesRepo[$i][2] Then
         $sCode = $aPackagesRepo[$i][0]
         ExitLoop
      EndIf
   Next
   $aResult[0] = 0
   For $i = 0 To $iPackagesRepo - 1
      If StringInStr($sCode, $aPackagesRepo[$i][4]) Then
         _ArrayAdd($aResult, $aPackagesRepo[$i][2])
         $aResult[0] = $aResult[0] + 1
      EndIf
   Next
   return $aResult
EndFunc

Func __loadConfigFile()
   Local $fConfig = FileOpen($CFG_PACKAGES, $FO_READ)
   While 1
	  Local $sConfig = FileReadLine($fConfig)
	  If @error Then ExitLoop

      If StringLeft(StringStripWS($sConfig, $STR_STRIPLEADING), 1) <> ";" Then 
	     If StringRegExp($sConfig, $DAT_VER & '(.*)') Then
	        Local $sVer = StringSplit($sConfig, "=")[2]
	        $sVersion = StringSplit($sVer, ".")[1]
            $sBuild = StringSplit($sVer, ".")[2]
	     ElseIf StringRegExp($sConfig, $DAT_SERVER & '(.*)') Then
	        $sServer = StringSplit($sConfig, "=")[2]
	     ElseIf StringRegExp($sConfig, $DAT_URL & '(.*)') Then
	        $sUrl = StringSplit($sConfig, "=")[2]
	     ElseIf StringRegExp($sConfig, $DAT_CRED & '(.*)') Then
	        $sCred = StringSplit($sConfig, "=")[2]
	     ElseIf StringRegExp($sConfig, $DAT_PROXY & '(.*)') Then
	        $sProxy = StringSplit($sConfig, "=")[2]
	     ElseIf StringRegExp($sConfig, $DAT_GITURL & '(.*)') Then
	        $sUrlGit = StringSplit($sConfig, "=")[2]
	     ElseIf StringRegExp($sConfig, $DAT_GITPARMS & '(.*)') Then
	        $sParmsGit = StringSplit($sConfig, "=")[2]
	     ElseIf StringRegExp($sConfig, $DAT_CURLPARMS & '(.*)') Then
	        $sParmsCurl = StringSplit($sConfig, "=")[2]
         EndIf
      EndIf
   Wend
   FileClose($fConfig)
   If $sServer = "" Then $sServer = $SERV_ARTIFACTORY

   Local $fConfig = FileOpen($CFG_LAUNCHER, $FO_READ)
   While 1
      Local $sLineCfg = FileReadLine($fConfig)
      If @error Then ExitLoop
	  If StringRegExp($sLineCfg, $DAT_REPOLAN & '(.*)') Then 
         $iRepoLan = Int(StringSplit($sLineCfg, "=")[2])
         ExitLoop
      EndIf
   Wend
EndFunc

Func __loadInstalledPackages()
   Local $aPkgInst = _FileListToArray($PATH_PKGINST, $PATTERN_UNINST, $FLTA_FILES)
   If @error = 0 Then
      For $i = 1 To $aPkgInst[0]
         Local $sPkgInst = StringSplit($aPkgInst[$i], $SEP4)[1]
         _ArrayAdd($aPackagesInstalled, StringSplit($sPkgInst, $SEP2)[1], 0)
         $aPackagesInstalled[$iPackagesInstalled][1] = StringSplit($sPkgInst, $SEP2)[2]
         $aPackagesInstalled[$iPackagesInstalled][2] = StringSplit($aPkgInst[$i], $SEP4)[2]
         $iPackagesInstalled = $iPackagesInstalled + 1
      Next
   EndIf
EndFunc

Func __loadPkgRepository()
   Local $bError = False
   Local $sRepoPkgFile = DownloadPkg($GRP_REPO, $PKG_REPO, $sVersion, "")
   If @error = 0 Then
      Local $fPkgRepoFile = FileOpen($sRepoPkgFile, $FO_READ)
      Local $sRepoPkgLine = FileReadLine($fPkgRepoFile)
      If StringSplit($sRepoPkgLine, ".")[0] = 2 Then
         $sRepoVersion = StringSplit($sRepoPkgLine, ".")[1]
         $sRepoBuild = StringSplit($sRepoPkgLine, ".")[2]
         While Not $bError
            $sRepoPkgLine = FileReadLine($fPkgRepoFile)
            If @error Then ExitLoop
	        If StringInStr($sRepoPkgLine, $SEP2) <> 0 Then
               _ArrayAdd($aPackagesRepo, StringSplit($sRepoPkgLine, $SEP2)[1], 0)
               $aPackagesRepo[$iPackagesRepo][1] = StringSplit($sRepoPkgLine, $SEP2)[2]
               $aPackagesRepo[$iPackagesRepo][2] = StringSplit($sRepoPkgLine, $SEP2)[3]
               $aPackagesRepo[$iPackagesRepo][3] = StringSplit($sRepoPkgLine, $SEP2)[4]
               $aPackagesRepo[$iPackagesRepo][4] = StringSplit($sRepoPkgLine, $SEP2)[5]
               $aPackagesRepo[$iPackagesRepo][5] = StringSplit($sRepoPkgLine, $SEP2)[6]
               $aPackagesRepo[$iPackagesRepo][6] = StringSplit($sRepoPkgLine, $SEP2)[7]
               $iPackagesRepo = $iPackagesRepo + 1
	        Else
               $bError = True
	        EndIf
         Wend
      Else
         $bError = True
      EndIf
      FileClose($fPkgRepoFile)
      FileDelete($sRepoPkgFile)
   Else
      $bError = True
   EndIf

   If $bError Then
      MsgBox($MB_OK + $MB_ICONERROR + $MB_SYSTEMMODAL + $MB_SETFOREGROUND, "Cannot connect to Repository", "There was a problem connecting to repository server." & @CRLF & @CRLF & " You should fix your network issues and/or the configuration data at '" & $CFG_PACKAGES & "'.")
   	  FileDelete($PATH_UPDATERTRIGGER)
      Exit(0)
   EndIf
EndFunc

Func SearchRepoPkg(Const $sCodPkg)
   Local $iPkg = -1
   For $j = 0 To $iPackagesRepo - 1
   If $aPackagesRepo[$j][0] == $sCodPkg Then
   $iPkg = $j
   ExitLoop
   EndIf
   Next
   If $iPkg == -1 Then
	  MsgBox(0, "Repository error", "Package not found: [" & $sCodPkg & "].")
	  Exit 1
   EndIf
   return $iPkg
EndFunc
#EndRegion FUNCTION

