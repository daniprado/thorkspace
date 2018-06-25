; Thorkspace Launcher
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
; Special thanks to David Perez Carrera

#Region INCLUDE
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <ComboConstants.au3>
#include <FontConstants.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include <GuiComboBox.au3>
#include <Misc.au3>
#include <Date.au3>
#include "lib\TSConstants.au3"
#include "lib\TSLauncherConfig.au3"
#include "lib\TSLauncherScripter.au3"
#include "lib\TSLauncherDevCreator.au3"
#include "lib\GUITreeViewEx.au3"
#EndRegion INCLUDE

#Region CONFIG
Global $gui, $cLaunch, $cUpdater, $cTVWorkspaces, $cTVSoftware
Global $cCreateDev, $cDeleteDev, $cCheckSave, $cScriptSave, $cWorkDrive, $cBranchCalc

Local $iWsSelected = 0
#EndRegion CONFIG

#Region SCRIPT
main()
Exit(0)
#EndRegion SCRIPT

#Region MAIN
Func main()
   If Not _Singleton($TITLE_LAUNCHER, 1) Then
       Sleep(500)
       WinActivate($TITLE_LAUNCHER)
       Exit(1)
   EndIf
   If @ScriptDir <> @WorkingDir Then
       FileChangeDir(@ScriptDir)
   EndIf

   __startGUI()
   LoadConfig()
   HotKeySet("{ESC}", "__hotKeyPressed")

   GUISetState(@SW_SHOW)
   While 1
      Sleep(50)
      Switch GUIGetMsg()
   	     Case $cLaunch
   	   	    __launch()
            ExitLoop
   	     Case $cUpdater
   	   	    _FileCreate($PATH_UPDATERTRIGGER)
            ExitLoop
   	     Case $cCreateDev
   	   	    WinSetOnTop($TITLE_LAUNCHER, "", $WINDOWS_NOONTOP)
   	   	    GuiSetState(@SW_DISABLE)
   	   	    CreateDev()
   	   	    GuiSetState(@SW_ENABLE)
   	   	    WinSetOnTop($TITLE_LAUNCHER, "", $WINDOWS_ONTOP)
   	     Case $cDeleteDev
   	   	    __deleteDev()
         Case $cBranchCalc
            __branchCalcSelected() 
  	     Case $GUI_EVENT_CLOSE
   	   	    Exit(1)
      EndSwitch
      __autoTip()
   WEnd
EndFunc
#Region MAIN

#Region FUNCTIONS
Func __startGUI()
   $gui = GUICreate($TITLE_LAUNCHER, 360, 315)
   GUISetIcon($PATH_ICON, 0)
   WinSetOnTop($TITLE_LAUNCHER, "", $WINDOWS_ONTOP)

   GUICtrlCreateLabel("Drive", 85, 10, 50, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   GUICtrlCreateLabel("<~~", 55, 10, 30, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   GUICtrlCreateLabel("Workspaces", 130, 40, 70, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   GUICtrlCreateLabel("~~~~>", 170, 55, 40, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   GUICtrlCreateLabel("Software", 120, 87, 70, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   GUICtrlCreateLabel("<~~", 150, 108, 30, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)

   $cCreateDev = GUICtrlCreateButton("+", 193, 230, 17, 17)
   GUICtrlSetFont(-1, 10, 0, 0, $FONT_TYPE)
   $cDeleteDev = GUICtrlCreateButton("-", 193, 250, 17, 17)
   GUICtrlSetFont(-1, 10, 0, 0, $FONT_TYPE)
   $cUpdater = GUICtrlCreateButton("Updater", 230, 288, 45, 20)
   GUICtrlSetFont(-1, 8, 0, 0, $FONT_TYPE)
   $cLaunch = GUICtrlCreateButton("Launch!", 290, 285, 60, 25)
   GUICtrlSetFont(-1, 10, 0, 0, $FONT_TYPE)
   $cCheckSave = GUICtrlCreateCheckbox("Save config", 15, 288, 90, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cScriptSave = GUICtrlCreateCheckbox("Save script", 120, 288, 90, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cBranchCalc = GUICtrlCreateCheckbox("Branch calc.", 140, 15, 70, 20)
   GUICtrlSetFont(-1, 8, 0, 0, $FONT_TYPE)

   $cWorkDrive = GUICtrlCreateCombo("", 20, 8, 33, 20, $CBS_DROPDOWNLIST + $CBS_UPPERCASE)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cTVWorkspaces = GUICtrlCreateTreeView(210, 10, 140, 270, $TVS_CHECKBOXES)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cTVSoftware = GUICtrlCreateTreeView(10, 110, 140, 170, $TVS_CHECKBOXES)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
EndFunc

Func __launch()

   __validate()
   SaveConfig()

   ; It will execute scripts depending on:
   ;   * Workspaces creation
   ;   * Drive change
   ;   * Checked software/workspaces
   __prepareExecution()
   Local $bLaunch = $sWorkspaces <> "" Or $sSoftware <> "" Or $iRepoLan Or $sDrive <> GUICtrlRead($cWorkDrive)
   Local $i = 0
   While (Not $bLaunch And $i < $iWorkspaces)
	  $bLaunch = $bLaunch Or (Not $aWorkspaces[$i][4])
	  $i = $i + 1
   WEnd

   If ($bLaunch) Then
	  ; temp-scripts creation
	  ; 	* configurer.au3 call
	  ;		* Software/Workspaces calls
	  CreateTempScripts()
      ; start.bat creation
	  If ($bLaunch And GUICtrlRead($cScriptSave) = $GUI_CHECKED) Then CreateStarter()
   EndIf
EndFunc

Func __deleteDev()
   For $i = 0 To $iWorkspaces - 1
	  If BitAND(GUICtrlRead($aWorkspaces[$i][0]), $GUI_FOCUS) = $GUI_FOCUS Then
		 GUICtrlDelete($aWorkspaces[$i][0])
		 _ArrayDelete($aWorkspaces, $i)
		 $iWorkspaces = $iWorkspaces - 1
		 ExitLoop
	  EndIf
   Next
EndFunc

Func __hotKeyPressed()
   Switch @HotKeyPressed
	  Case "{ESC}"
	  Exit(1)
   EndSwitch
EndFunc

Func __validate()
   Local $sNewDrive = GUICtrlRead($cWorkDrive)
   Local $fVersion = FileFindFirstFile ($PATH_RUNVER & "*")
   Local $sVersion = FileFindNextFile($fVersion)
   FileClose($fVersion)

   If FileExists($sDrive & ":" & $PATH_VERSION) = 1 Then
     Local $fVDrive = FileFindFirstFile ($sDrive & ":" & $PATH_VERSION)
	 Local $sVDrive = FileFindNextFile($fVDrive)
	 FileClose($fVDrive)
	 If $sDrive <> $sNewDrive And $sVersion <> $sVDrive Then
       GuiSetState(@SW_DISABLE)
	   MsgBox ($MB_SYSTEMMODAL+$MB_ICONERROR, "Error!", "You tried to change Drive over a running Thorkspace")
	   GUIDelete()
	   Exit(1)
     ElseIf $sDrive = $sNewDrive And $sVersion <> $sVDrive Then
       GuiSetState(@SW_DISABLE)
	   MsgBox ($MB_SYSTEMMODAL+$MB_ICONERROR, "Error!", "You tried to change Drive to a letter already in use")
	   GUIDelete()
	   Exit(1)
	 EndIf
   ElseIf FileExists($sNewDrive & ":" & $PATH_VERSION) = 1 Then
	 Local $fVDrive = FileFindFirstFile ($sNewDrive  & ":" & $PATH_VERSION)
	 Local $sVDrive = FileFindNextFile($fVDrive)
	 FileClose($fVDrive)
	 If $sVersion <> $sVUnidad Then
       GuiSetState(@SW_DISABLE)
       MsgBox ($MB_SYSTEMMODAL+$MB_ICONERROR, "Error!", "You tried to run Thorkspace in a Drive already in use")
       GUIDelete()
	   Exit(1)
	 EndIf
   EndIf

   Local $iTime = _TimeToTicks(@HOUR, @MIN, @SEC)
   FileMove($PATH_RUNVER & "*", $PATH_RUNVER & String($iTime))

EndFunc

Func __prepareExecution()
   Local $sCommand
   For $i = 0 To $iWorkspaces - 1
	  If BitAND(GUICtrlRead($aWorkspaces[$i][0]), $GUI_CHECKED) = $GUI_CHECKED Then
		 $sCommand = StringRegExpReplace($aWorkspaces[$i][2], "%([^%]*?)%", ' " & EnvGet("$1") & "', 0)
		 $sCommand = StringReplace($sCommand, "{WORKSPACE}", '" & EnvGet("' & $ENV_DEVPATH & '") & "\' & StringSplit($aWorkspaces[$i][1], "=")[2], 0)
		 $sCommand = StringReplace($sCommand, "{HOME}", StringReplace($PATH_HOME, "\", "/"), 0)
		 $sWorkspaces = $sWorkspaces & 'Run(EnvGet("' & $ENV_IDEPATH & '") & "' & $sCommand & '")' & @CRLF
	  EndIf
   Next

   Local $sChDir
   For $i = 0 To $iSoftware - 1
	  If BitAND(GUICtrlRead($aSoftware[$i][0]), $GUI_CHECKED) = $GUI_CHECKED Then
		 $sCommand = StringRegExpReplace($aSoftware[$i][2], "%([^%]*?)%", " "" & EnvGet(""$1"") & """, 0)
		 $sChDir = StringSplit($sCommand,"\")[1]
		 For $j = 2 To StringSplit($sCommand,"\")[0] - 1
		    $sChDir = $sChDir & "\" & StringSplit($sCommand,"\")[$j]
		 Next
		 $sSoftware = $sSoftware & "FileChangeDir(EnvGet('" & $ENV_BINPATH & "') & '" & $sChDir & "')" & @CRLF
		 $sSoftware = $sSoftware & "Run(EnvGet('" & $ENV_BINPATH & "') & '" & $sCommand & "')" & @CRLF
	  EndIf
   Next
EndFunc

Func __autoTip()
   Local $iSelected = GUICtrlRead($cTVWorkspaces)
   If $iSelected <> 0 And $iSelected <> $iWsSelected Then
      $iWsSelected = $iSelected
      Local $aPos = WinGetPos($TITLE_LAUNCHER)
      Local $iWS
      For $i = 0 To $iWorkspaces - 1
         If $aWorkspaces[$i][0] = $iSelected Then
            $iWS = $i
            ExitLoop
         EndIf
      Next
      ToolTip($aWorkspaces[$iWS][6], $aPos[0] + 380, $aPos[1] + 25 + (20 * $iWs), $aWorkspaces[$iWS][5])
   EndIf
EndFunc

Func __branchCalcSelected()
   If BitAnd(GUICtrlRead($cBranchCalc), $GUI_CHECKED) = $GUI_CHECKED Then
      GuiSetState(@SW_DISABLE)
      MsgBox($MB_OK + $MB_ICONWARNING + $MB_SYSTEMMODAL + $MB_SETFOREGROUND, "Workspace branch calculation", "Next time you launch Thorkspace you will see the names of branches next to the project names on workspace's tooltip window." & @CRLF & @CRLF & "These calculations will make Thorkspace's launcher load slower, so be patient.")
      GuiSetState(@SW_ENABLE)
   EndIF
EndFunc
#EndRegion FUNCTIONS
