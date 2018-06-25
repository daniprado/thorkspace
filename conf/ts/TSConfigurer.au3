; Thorkspace Configurer
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
; This file is written in AutoIT Script (https://www.autoitscript.com/autoit3/docs/)

#Region INCLUDE
#include <FileConstants.au3>
#include <File.au3>
#include "lib\TSConstants.au3"
#EndRegion INCLUDE

#Region SCRIPT
main()
Exit(0)
#EndRegion SCRIPT

#Region MAIN
Func main()
   If @ScriptDir <> @WorkingDir Then
       FileChangeDir(@ScriptDir)
   EndIf
   
   If $NEWDEVS <> "" Then
      __createWSs()
   EndIf
   
   If $NEWDRIVE <> "" Then
      __changeDrive()
   EndIf
EndFunc
#EndRegion MAIN

#Region FUNCTIONS
Func __createWSs()
   Local $aNewDevs = StringSplit($NEWDEVS, $SEP)
   Local $aNewDev, $sOrigin, $sDest
   For $i = 1 To $aNewDevs[0]
      If $aNewDevs[$i] <> "" Then
         $aNewDev = StringSplit($aNewDevs[$i], $SEP2)
         $sOrigin = $PATH_IDE & "\" & $aNewDev[2] & $CFG_TS
         $sDest = $PATH_DEV & "\" & $aNewDev[1]
         RunWait("7z.exe x " & $sOrigin & $CFG_WSBASE & ".7z -y -o" & $sOrigin)
         DirMove($sOrigin & $CFG_WSBASE, $sDest)
         FileCopy($sOrigin & $CFG_TSBASE, $sDest & $CFG_TS)
      EndIf
   Next
EndFunc

Func __changeDrive()
   Local $aIdes = _FileListToArray($PATH_IDE)
   Local $sIde
   For $i = 1 To $aIdes[0]
      $sIde = $PATH_IDE & "\"  & $aIdes[$i]
      __adapt($aIdes[$i], $sIde & $CFG_TS & "\" & $DIR_IDE, $sIde)
   Next
 
   Local $aDevs = _FileListToArray($PATH_DEV)
   If (Not @error) Then
      Local $sDev, $fTsIde, $sIde
      For $i = 1 To $aDevs[0]
         $sDev = $PATH_DEV & "\"  & $aDevs[$i]
         $fTsIde = FileOpen($sDev & $CFG_TS, $FO_READ)
        	$sIde = StringSplit(FileReadLine($fTsIde), '\')[2]
         FileClose($fTsIde)
         __adapt($aDevs[$i], $PATH_IDE & "\" & $sIde & $CFG_TS & "\" & $DIR_DEV, $sDev)
      Next
   EndIf
 
   Local $aSections = _FileListToArray($PATH_BIN, "*", $FLTA_FOLDERS)
   Local $sSection, $aApps, $sApp
   For $i = 1 To $aSections[0]
      If $aSections[$i] <> $DIR_BASE And $aSections[$i] <> $DIR_IDE And $aSections[$i] <> $DIR_JAVA Then
         $sSection = $PATH_BIN & "\" & $aSections[$i]
         $aApps = _FileListToArray($sSection, "*", $FLTA_FOLDERS)
         If (Not @error) Then
        	   For $j = 1 To $aApps[0]
        	      $sApp = $sSection & "\" & $aApps[$j]
        	      __adapt($aApps[$j], $sApp & $CFG_TS & "\" & $DIR_APP, $sApp)
        	      __adapt($aApps[$j], $sApp & $CFG_TS & "\" & $DIR_DATA, $PATH_ENV)
        	   Next
         EndIf
      EndIf
   Next
EndFunc

Func __adapt(Const $sProg, Const $sOrigin, Const $sDest)

   Local $aFiles = _FileListToArrayRec($sOrigin, "*", $FLTAR_FILES, $FLTAR_RECUR)
   If (Not @error) Then
	  For $i = 1 To $aFiles[0]

		 Local $fileIn = FileOpen($sOrigin & "\" & $aFiles[$i], $FO_READ)
		 Local $sfile = FileRead($fileIn, FileGetSize($sOrigin & "\" & $aFiles[$i]))
		 FileClose($fileIn)

		 ;~ 	  Standard
		 $sfile = StringReplace($sfile, '%WORK_LETTER%', $WORKLETTER)
		 $sfile = StringReplace($sfile, '%WORK%', $PATH_WORK)
		 $sfile = StringReplace($sfile, '%HOMEPATH%', $PATH_HOME)
		 $sfile = StringReplace($sfile, '%CONFPATH%', $PATH_CONF)
		 $sfile = StringReplace($sfile, '%BINPATH%', $PATH_BIN)
		 $sfile = StringReplace($sfile, '%DEVPATH%', $PATH_DEV)
		 $sfile = StringReplace($sfile, '%DEVPATH+%', $PATH_DEV & "\" & $sProg)
		 $sfile = StringReplace($sfile, '%IDE_HOME%', $PATH_IDE)
		 $sfile = StringReplace($sfile, '%JAVA_HOME%', $PATH_JAVA)
		 $sfile = StringReplace($sfile, '%MAVEN_HOME%', $PATH_MAVEN)
		 ;~ 	  Java type 1
		 $sfile = StringReplace($sfile, '#HOMEPATH#', StringReplace($PATH_HOME, "\", "/"))
		 $sfile = StringReplace($sfile, '#CONFPATH#', StringReplace($PATH_CONF, "\", "/"))
		 $sfile = StringReplace($sfile, '#BINPATH#', StringReplace($PATH_BIN, "\", "/"))
		 $sfile = StringReplace($sfile, '#DEVPATH#', StringReplace($PATH_DEV, "\", "/"))
		 $sfile = StringReplace($sfile, '#DEVPATH+#', StringReplace($PATH_DEV & "\" & $sProg, "\", "/"))
		 $sfile = StringReplace($sfile, '#IDE_HOME#', StringReplace($PATH_IDE, "\", "/"))
		 $sfile = StringReplace($sfile, '#JAVA_HOME#', StringReplace($PATH_JAVA, "\", "/"))
		 $sfile = StringReplace($sfile, '#MAVEN_HOME#', StringReplace($PATH_MAVEN, "\", "/"))
		 ;~ 	  Java type 2
		 $sfile = StringReplace($sfile, '$WORK$', StringReplace($PATH_WORK, ":", "\:"))
		 $sfile = StringReplace($sfile, '$HOMEPATH$', StringReplace(StringReplace($PATH_HOME, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$CONFPATH$', StringReplace(StringReplace($PATH_CONF, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$BINPATH$', StringReplace(StringReplace($PATH_BIN, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$PATH_DEV$', StringReplace(StringReplace($PATH_DEV, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$PATH_DEV+$', StringReplace(StringReplace($PATH_DEV & "\" & $sProg, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$PATH_IDE$', StringReplace(StringReplace($PATH_IDE, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$JAVA_HOME$', StringReplace(StringReplace($PATH_JAVA, "\", "/"), ":", "\:"))
		 $sfile = StringReplace($sfile, '$MAVEN_HOME$', StringReplace(StringReplace($PATH_MAVEN, "\", "/"), ":", "\:"))
		 ;~ 	  Java type 3
		 $sfile = StringReplace($sfile, '*HOMEPATH*', StringReplace(StringReplace($PATH_HOME, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*CONFPATH*', StringReplace(StringReplace($PATH_CONF, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*BINPATH*', StringReplace(StringReplace($PATH_BIN, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*DEVPATH*', StringReplace(StringReplace($PATH_DEV, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*DEVPATH+*', StringReplace(StringReplace($PATH_DEV & "\" & $sProg, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*IDE_HOME*', StringReplace(StringReplace($PATH_IDE, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*JAVA_HOME*', StringReplace(StringReplace($PATH_JAVA, "\", "\\"), ":", "\:"))
		 $sfile = StringReplace($sfile, '*MAVEN_HOME*', StringReplace(StringReplace($PATH_MAVEN, "\", "\\"), ":", "\:"))

		 Local $fileOut = FileOpen($sDest & "\" & $aFiles[$i], $FO_OVERWRITE)
		 FileWrite($fileOut, $sfile)
		 FileClose($fileOut)
	  Next
   EndIf
EndFunc
#EndRegion FUNCTIONS

