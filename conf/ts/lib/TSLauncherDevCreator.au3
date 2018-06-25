; Thorkspace DevCreator
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
Local $__gui, $cName, $cIDE, $cSave, $cCancel
#EndRegion CONFIG

#Region FUNCTIONS
Func CreateDev()
   __startGUI__()
   GUISetState(@SW_SHOW)
   While 1
	  Sleep(50)
	  Switch GUIGetMsg()
		 Case $cSave
            __saveDev__()
			ExitLoop
		 Case $cCancel
			ExitLoop
		 Case $GUI_EVENT_CLOSE
			ExitLoop
		 Case Else
            __validate__()
	  EndSwitch
   WEnd
   GUIDelete()
EndFunc

Func __startGUI__()
   $__gui = GUICreate($TITLE_DEVCREATOR, 300, 115)
   WinSetOnTop($TITLE_DEVCREATOR, "", $WINDOWS_ONTOP)
   GUISetIcon($PATH_ICON, 0)
   GUICtrlCreateLabel("Name", 20, 20, 50, 20)
   GUICtrlSetFont(-1, 10, 0, 0, $FONT_TYPE)
   $cName = GUICtrlCreateEdit("", 80, 20, 200, 22, $ES_OEMCONVERT)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   GUICtrlCreateLabel("IDE", 20, 50, 50, 20)
   GUICtrlSetFont(-1, 10, 0, 0, $FONT_TYPE)
   $cIDE = GUICtrlCreateCombo("", 80, 50, 200, 20, $CBS_DROPDOWNLIST)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   GUICtrlSetData($cIDE, $sIDEs, "")
   $cSave = GUICtrlCreateButton("Save", 120, 90, 50, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   GUICtrlSetState($cSave, $GUI_DISABLE)
   $cCancel = GUICtrlCreateButton("Cancel", 180, 90, 50, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
EndFunc

Func __getBaseIde__(Const $sIde)
   Local $fTsIde = FileOpen($PATH_IDE & "\" & $sIde & $CFG_TS & $CFG_TSBASE, $FO_READ)
   Local $sResult = FileReadLine($fTsIde)
   FileClose($fTsIde)
   Return $sResult
EndFunc

Func __saveDev__()
	_ArrayAdd($aWorkspaces, GUICtrlCreateTreeViewItem(GUICtrlRead($cName), $cTVWorkspaces), 0)
	$aWorkspaces[$iWorkspaces][1] = $DAT_DEV & GUICtrlRead($cName)
	$aWorkspaces[$iWorkspaces][2] = __getBaseIde__(GUICtrlRead($cIDE))
	$aWorkspaces[$iWorkspaces][3] = False
	$aWorkspaces[$iWorkspaces][4] = Not (BitAND(GUICtrlGetState($cIDE), $GUI_ENABLE) = $GUI_ENABLE)
	$iWorkspaces = $iWorkspaces + 1
EndFunc

Func __validate__()
	If FileExists($PATH_DEV & GUICtrlRead($cName)) And BitAND(GUICtrlGetState($cIDE), $GUI_ENABLE) = $GUI_ENABLE Then
       ; Workspace already exists
	   If FileExists($PATH_DEV & GUICtrlRead($cName) & $CFG_TS) Then
		  _GUICtrlComboBox_SelectString($cIDE, StringSplit(GetIDECommand(GUICtrlRead($cName)), "\")[2])
	   Else
		  _GUICtrlComboBox_SelectString($cIDE, "")
	   EndIf
	   GUICtrlSetState($cIDE, $GUI_DISABLE)
	ElseIf (Not FileExists($PATH_DEV & GUICtrlRead($cName))) Then
	   GUICtrlSetState($cIDE, $GUI_ENABLE)
	EndIf

	; Save can only be executed if both fields have a value
	If GUICtrlRead($cName) <> "" And GUICtrlRead($cIDE) <> "" Then
       GUICtrlSetState($cSave, $GUI_ENABLE)
	Else
       GUICtrlSetState($cSave, $GUI_DISABLE)
	EndIf
EndFunc
#EndRegion FUNCTIONS
