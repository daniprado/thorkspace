; Thorkspace Launcher-Scripter
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
#include "TSConstants.au3"
#EndRegion INCLUDE

#Region CONFIG
Global $sSoftware = ""
Global $sWorkspaces = ""
#EndRegion CONFIG

#Region FUNCTIONS
Func CreateTempScripts()
   Local $tempBat = FileOpen($PATH_TMPFILE & ".bat", $FO_OVERWRITE)
   Local $sNewDrive = GUICtrlRead($cWorkDrive)

   FileWriteLine($tempBat, '@echo off')
   FileWriteLine($tempBat, "SET " & $ENV_WORKLETTER & "=" & $sNewDrive)
   FileWriteLine($tempBat, "SET " & $ENV_WORKPATH & "=%" & $ENV_WORKLETTER & "%:")
   FileWriteLine($tempBat, "SUBST %" & $ENV_WORKPATH & "% " & $PATH_ROOT)
   FileWriteLine($tempBat, 'if not exist "%' & $ENV_WORKPATH & '%\launch.bat" (')
   FileWriteLine($tempBat, 'echo Drive letter creation FAIL!')
   FileWriteLine($tempBat, 'exit 0')
   FileWriteLine($tempBat, ')')
   FileWriteLine($tempBat, "CALL %" & $ENV_WORKPATH & "%" & $CFG_ENV)

   Local $bChangeConfig = False
   Local $sNewDevs = ""
   For $i = 0 To $iWorkspaces - 1
	  If Not $aWorkspaces[$i][4] Then
		 $sNewDevs = $sNewDevs & StringSplit($aWorkspaces[$i][1], "=")[2] & $SEP2
		 $sNewDevs = $sNewDevs & StringSplit($aWorkspaces[$i][2], "\")[2] & $SEP
		 $bChangeConfig = True
	  EndIf
   Next

   If $sNewDevs <> "" Then
	  FileWriteLine($tempBat, "SET " & $ENV_NEWDEVS & "=" & $sNewDevs)
   EndIf
   
   If $sDrive <> $sNewDrive Then
  	 FileWriteLine($tempBat, "SET " & $ENV_NEWDRIVE & "=YES!")
     $bChangeConfig = True
   EndIf
   
   If $bChangeConfig Then
	  FileWriteLine($tempBat, "CALL " & $EXEC_CONFIGURER)
	  FileDelete($PATH_STARTERBAT)
	  FileDelete($PATH_STARTERAU3)
   EndIf
   
   If $sWorkspaces <> "" Or $sSoftware <> "" Or $iRepoLan Then
	  FileWriteLine($tempBat, "CALL " & $EXEC_TEMPAU3)
	  Local $tempAu3 = FileOpen($PATH_TMPFILE & ".au3", $FO_OVERWRITE)
	  FileWrite($tempAu3, $sWorkspaces)
	  FileWrite($tempAu3, $sSoftware)
      If $iRepoLan Then FileWrite($tempAu3, $EXEC_REPOLAN & @CRLF)
	  FileWriteLine($tempAu3, "Exit(0)")
	  FileClose($tempAu3)
   EndIf
   FileClose($tempBat)
EndFunc

Func CreateStarter()

   Local $outBat = FileOpen($PATH_STARTERBAT, $FO_OVERWRITE)
   FileWriteLine($outBat, '@echo off')
   FileWriteLine($outBat, "SET " & $ENV_WORKPATH & "=" & GUICtrlRead($cWorkDrive) & ":")
   FileWriteLine($outBat, "SUBST %" & $ENV_WORKPATH & "% " & $PATH_ROOT)
   FileWriteLine($outBat, 'if not exist "%' & $ENV_WORKPATH & '%\launch.bat" (')
   FileWriteLine($outBat, 'echo Drive letter creation FAIL!')
   FileWriteLine($outBat, 'exit 0')
   FileWriteLine($outBat, ')')
   FileWriteLine($outBat, "CALL %" & $ENV_WORKPATH & "%" & $CFG_ENV)
   FileWriteLine($outBat, "CALL " & $EXEC_STARTER)
   FileClose($outBat)

   Local $outAu3 = FileOpen($PATH_STARTERAU3, $FO_OVERWRITE)
   FileWriteLine($outBat, @CRLF & "#Region WORKSPACES")
   FileWrite($outAu3, $sWorkspaces)
   FileWriteLine($outBat, "#EndRegion WORKSPACES" & @CRLF & "#Region SOFTWARE")
   FileWrite($outAu3, $sSoftware)
   FileWriteLine($outAu3, "#EndRegion SOFTWARE" & @CRLF & "Exit(0)")
EndFunc
#EndRegion FUNCTIONS
