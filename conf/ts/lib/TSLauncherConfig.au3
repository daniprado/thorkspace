; Thorkspace Launcher-Config
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
; Starting work drive
Global $sDrive = ""
; Acting as LAN repository
Global $iRepoLan = 0
; Workspace branch calculation
Global $iBranchCalc = 0

; Software info
; 0 - Check
; 1 - app=<<Name>>
; 2 - Command
; 3 - Previously checked
Global $aSoftware[0][4]
Global $iSoftware = 0

; Workspaces info
; 0 - Check
; 1 - ws=<<Name>>
; 2 - Command
; 3 - Previously checked
; 4 - Preexistent
; 5 - Tooltip title
; 6 - Tooltip text
Global $aWorkspaces[0][7]
Global $iWorkspaces = 0

; IDEs
Global $sIDEs = ""
#EndRegion CONFIG

#Region FUNCTIONS
Func LoadConfig()
   Local $fConfig = FileOpen($CFG_LAUNCHER, $FO_READ)
   Local $sConfig, $aProgram, $cItem, $aDev, $sDev
   While True
	  $sConfig = FileReadLine($fConfig)
	  If @error Then ExitLoop
	  
	  If StringRegExp($sConfig, $DAT_DRIVE & '(.*)') Then
		 $sDrive = StringSplit($sConfig, "=")[2]

	  ElseIf StringRegExp($sConfig, $DAT_REPOLAN & '(.*)') Then 
         $iRepoLan = Int(StringSplit($sConfig, "=")[2])
	  
	  ElseIf StringRegExp($sConfig, $DAT_BRANCHCALC & '(.*)') Then 
         $iBranchCalc = Int(StringSplit($sConfig, "=")[2])
	  
	  ElseIf StringRegExp($sConfig, $DAT_APP & '(.*)') Then
		 $aProgram = StringSplit($sConfig, $SEP)
		 $cItem = GUICtrlCreateTreeViewItem(StringReplace($aProgram[1], $DAT_APP, '', 1), $cTVSoftware)
		 _ArrayAdd($aSoftware, $cItem, 0)
		 $aSoftware[$iSoftware][1] = $aProgram[1]
		 $aSoftware[$iSoftware][2] = $aProgram[2]
		 If $aProgram[0] = 3 Then
			GUICtrlSetState($cItem, $GUI_CHECKED)
			$aSoftware[$iSoftware][3] = True
		 Else
			$aSoftware[$iSoftware][3] = False
		 EndIf
		 $iSoftware = $iSoftware + 1
	  
	  ElseIf StringRegExp($sConfig, $DAT_DEV & '(.*)') Then
		 $aDev = StringSplit($sConfig, $SEP)
		 $sDev = StringSplit($aDev[1], "=")[2]
		 $cItem = GUICtrlCreateTreeViewItem($sDev, $cTVWorkspaces)
		 _ArrayAdd($aWorkspaces, $cItem, 0)
		 $aWorkspaces[$iWorkspaces][1] = $aDev[1]
		 $aWorkspaces[$iWorkspaces][2] = __getIdeCommand($sDev)
		 If $aDev[0] = 2 Then
			GUICtrlSetState($cItem, $GUI_CHECKED)
			$aWorkspaces[$iWorkspaces][3] = True
		 Else
			$aWorkspaces[$iWorkspaces][3] = False
		 EndIf
		 $aWorkspaces[$iWorkspaces][4] = True
		 $aWorkspaces[$iWorkspaces][5] = $sDev
		 If $aWorkspaces[$iWorkspaces][2] <> "" Then 
		    $aWorkspaces[$iWorkspaces][5] = $sDev & " [" & StringSplit($aWorkspaces[$iWorkspaces][2], "\")[2] & "]"
		    $aWorkspaces[$iWorkspaces][6] = __getProjects($sDev)
		 EndIf
         $iWorkspaces = $iWorkspaces + 1
	  EndIf
   Wend
   FileClose($fConfig)

   GUICtrlSetData($cWorkDrive, $DRIVES, $sDrive)
   If $iBranchCalc Then GUICtrlSetState($cBranchCalc, $GUI_CHECKED)
   
   Local $aIdes = _FileListToArray($PATH_IDE, "*", $FLTA_FOLDERS)
   If @error = 0 Then
      For $i = 1 To $aIdes[0]
	     $sIDEs = $sIDEs & $aIdes[$i] & "|"
      Next
   EndIf
   $sIDEs = StringLeft($sIDEs, StringLen($sIDEs) - 1)
EndFunc

Func SaveConfig()

   Local $sConfig = $DAT_DRIVE & GUICtrlRead($cWorkDrive) & @CRLF

   $sConfig = $sConfig & $DAT_REPOLAN & $iRepoLan & @CRLF

   $iBranchCalc = 0
   If BitAnd(GUICtrlRead($cBranchCalc), $GUI_CHECKED) = $GUI_CHECKED Then $iBranchCalc = 1
   $sConfig = $sConfig & $DAT_BRANCHCALC & $iBranchCalc & @CRLF

   Local $sCheckedApp 
   For  $i = 0 To $iSoftware - 1
	  $sCheckedApp = ""
	  If GUICtrlRead($cCheckSave) = $GUI_CHECKED Then
		 If (BitAND(GUICtrlRead($aSoftware[$i][0]), $GUI_CHECKED) = $GUI_CHECKED) Then
			$sCheckedApp = $CHECKED
		 EndIf
	  Else
		 If $aSoftware[$i][3] Then
			$sCheckedApp = $CHECKED
		 EndIf
	  EndIf
	  $sConfig = $sConfig & $aSoftware[$i][1] & $SEP & $aSoftware[$i][2] & $sCheckedApp & @CRLF
   Next

   Local $sCheckedDev 
   For $i = 0 To $iWorkspaces - 1
	  $sCheckedDev = ""
	  If GUICtrlRead($cCheckSave) = $GUI_CHECKED Then
		 If BitAND(GUICtrlRead($aWorkspaces[$i][0]), $GUI_CHECKED) = $GUI_CHECKED Then
			$sCheckedDev = $CHECKED
		 EndIf
	  Else
		 If $aWorkspaces[$i][3] Then
			$sCheckedDev = $CHECKED
		 EndIf
	  EndIf
	  If Not $aWorkspaces[$i][4] Then
         ; TODO ¿¿??
	  EndIf
	  $sConfig = $sConfig & $aWorkspaces[$i][1] & $sCheckedDev & @CRLF
   Next

   Local $fConfigOut = FileOpen($CFG_LAUNCHER, $FO_OVERWRITE)
   FileWrite($fConfigOut, $sConfig)
   FileClose($fConfigOut)
EndFunc

Func __getIdeCommand(Const $sDev)
   Local $fTsIde = FileOpen($PATH_DEV & "\" & $sDev & $CFG_TS, $FO_READ)
   Local $sResult = FileReadLine($fTsIde)
   FileClose($fTsIde)
   Return $sResult
EndFunc

Func __getProjects(Const $sDev)

   Local $sResult = ""
   Local $sPath = $PATH_DEV & "\" & $sDev
   Local $aDirs = _FileListToArray($sPath, "*", $FLTA_FOLDERS)
   If Not @error Then
      Local $sCmdOut, $sCmdMsg = '', $aTag, $aOut, $aVer, $bFound
      For $i=1 To $aDirs[0]
         $bFound = False
         $aTag = _FileListToArray($sPath & "\" & $aDirs[$i], ".svn", $FLTA_FOLDERS)
         If Not @error Then
            $bFound = True
            If $iBranchCalc Then
               $sCmdOut = Run(@ComSpec & ' /c svn info "' & $sPath & '\' & $aDirs[$i] & '"', "", @SW_HIDE, $STDERR_MERGED)
               ProcessWait($sCmdOut, 1)
               $sCmdMsg = StdoutRead($sCmdOut)
               If @error Then ContinueLoop
               $aOut = StringSplit($sCmdMsg, @CRLF, $STR_ENTIRESPLIT)
               If $aOut[0] < 3 Then ContinueLoop
               $aVer = StringSplit($aOut[3], "/")
               $sResult = $sResult & $aDirs[$i] & ": " & $aVer[$aVer[0]] & " (svn)" & @CRLF
            EndIf
         EndIf 
         If Not $bFound Then
            $aTag = _FileListToArray($sPath & "\" & $aDirs[$i], ".git", $FLTA_FOLDERS)
            If Not @error Then
               $bFound = True
               If $iBranchCalc Then
                  $sCmdOut = Run(@ComSpec & " /c git branch ", $sPath & '\' & $aDirs[$i], @SW_HIDE, $STDERR_MERGED)
                  ProcessWait($sCmdOut, 1)
                  $sCmdMsg = StdoutRead($sCmdOut)
                  If @error Then ContinueLoop
                  $aOut = StringSplit($sCmdMsg, @CRLF, $STR_ENTIRESPLIT)
                  If $aOut[0] < 1 Then ContinueLoop
                  $aVer = StringSplit($aOut[1], " ")
                  $sResult = $sResult & $aDirs[$i] & ": " & StringStripWS($aVer[$aVer[0]], $STR_STRIPALL) & " (git)" & @CRLF
               EndIf
            EndIf
         EndIf
         If $bFound And Not $iBranchCalc Then $sResult = $sResult & $aDirs[$i] & @CRLF
      Next
   EndIf
   return $sResult

EndFunc
#EndRegion FUNCTIONS
