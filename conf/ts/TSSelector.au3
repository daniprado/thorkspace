; Thorkspace Selector
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
#include <Misc.au3>
#include <Array.au3>
#include "lib\TSConstants.au3"
#include "lib\TSPackages.au3"
#include "lib\GUITreeViewEx.au3"
#EndRegion INCLUDE

#Region CONFIG
Local $gui, $cTVRepo, $cTVInst, $cRepoLan, $cUpdate, $cSave, $cReset
Local $iSelectedRepo, $bSelStateRepo, $iSelectedInst, $bSelStateInst

; Package groups' data
; 0 - Text
; 1 - Directory
; 2 - TV_Data Repository
; 3 - Repository empty
; 4 - TV_Data Installed
; 5 - Installed empty
Local $aGrps[6][4]

Local $bNotInstalled = EnvGet($ENV_NOTINSTALLED) <> ""
#EndRegion CONFIG

#Region SCRIPT
__main()
Exit(0)
#EndRegion SCRIPT

#Region MAIN
Func __main()

   If Not _Singleton($TITLE_SELECTOR, 1) Then
       Sleep(500)
       WinActivate($TITLE_SELECTOR)
       Exit(1)
   EndIf
   If @ScriptDir <> @WorkingDir Then
       FileChangeDir(@ScriptDir)
   EndIf

   LoadPackages()
   __startGUI()
   __loadGrps()
   __initPkgsState()

   GUISetState(@SW_SHOW)
   _GUITreeViewEx_RegMsg()
   While True
      Sleep(50)
      Switch GUIGetMsg()
         Case $cUpdate
            __updateVersion()
            ExitLoop
   	     Case $cSave
            __packData()
   	   	    ExitLoop
         Case $cReset
            __initPkgsState()
         Case $cRepoLan
            __repoLanCheck()
   	     Case $GUI_EVENT_CLOSE
   	   	    Exit(0)
      EndSwitch
      __autoCheck()
      _GUITreeViewEx_AutoCheck()
   WEnd
EndFunc
#EndRegion MAIN

#Region FUNCTIONS
Func __startGUI()
   Local $bVersionChange = $sVersion <> $sRepoVersion Or $sBuild <> $sRepoBuild  

   Local $iHeight = 540
   If $bVersionChange Then $iHeight = $iHeight + 30
   $gui = GUICreate($TITLE_SELECTOR, 500, $iHeight)
   GUISetIcon($PATH_ICON, 0)
   WinSetOnTop($TITLE_SELECTOR, "", $WINDOWS_ONTOP)

   GUICtrlCreateLabel("Repository", 10, 10, 100, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   GUICtrlCreateLabel("Installed", 255, 10, 100, 20)
   GUICtrlSetFont(-1, 11, $FW_BOLD, 0, $FONT_TYPE)
   $cTVRepo = GUICtrlCreateTreeView(10, 35, 235, 465, BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES))
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cTVInst = GUICtrlCreateTreeView(255, 35, 235, 465, BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES))
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cRepoLan = GUICtrlCreateCheckbox("Become a Thorkspace LAN Repository", 10, 510, 240, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cUpdate = GUICtrlCreateButton("Update!", 10, $iHeight - 30, 80, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   If $bVersionChange Then
      Local $sVerChangeLabel = ""
      If $sVersion <> $sRepoVersion Then
         $sVerChangeLabel = "Major version change!"
      Else
         $sVerChangeLabel = "Minor version change."
      EndIf
      GUICtrlCreateLabel($sVerChangeLabel, 100, $iHeight - 30, 200, 20)
      GUICtrlSetFont(-1, 10, $FW_BOLD, 0, $FONT_TYPE)
      GUICtrlSetColor(-1, $COLOR_RED)
   Else
      ControlHide($gui, "", $cUpdate)
   EndIf
   $cSave = GUICtrlCreateButton("Install", 410, 510, 80, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
   $cReset = GUICtrlCreateButton("Reset", 320, 510, 80, 20)
   GUICtrlSetFont(-1, 9, 0, 0, $FONT_TYPE)
EndFunc

Func __loadGrps()
   $aGrps[0][0] = $GRP_BASE
   $aGrps[0][1] = $GRP_JAVA
   $aGrps[0][2] = $GRP_IDE
   $aGrps[0][3] = $GRP_XTRA
   $aGrps[1][0] = $DIR_BASE
   $aGrps[1][1] = $DIR_JAVA
   $aGrps[1][2] = $DIR_IDE
   $aGrps[1][3] = $DIR_XTRA

   For $i = 0 To 3
      $aGrps[2][$i] = $aGrps[0][$i] & "|"
      $aGrps[3][$i] = True
      $aGrps[4][$i] = $aGrps[0][$i] & "|"
      $aGrps[5][$i] = True
   Next

   Local $sPkg, $iGrp, $iTV, $iNempty, $sCheck
   For $i = 0 To $iPackagesRepo - 1
      $sPkg = $aPackagesRepo[$i][2]
      For $j = 0 To 3
         If $aPackagesRepo[$i][1] == $aGrps[1][$j] Then $iGrp = $j
      Next
      $iTV = 2
      $iNempty = 3
      $sCheck = ""
      If IsInstalled($sPkg) Then
         $iTV = 4
         $iNempty = 5
      Else
         If $aPackagesRepo[$i][5] <> "" Then $sPkg = $sPkg & " (" & $aPackagesRepo[$i][5] & ")"
         If $aPackagesRepo[$i][6] <> "" And $bNotInstalled Then $sCheck = "#"
      EndIf
      $aGrps[$iTV][$iGrp] = $aGrps[$iTV][$iGrp] & "~" & $sCheck & $sPkg & "|"
      $aGrps[$iNempty][$iGrp] = False
   Next
EndFunc

Func __initPkgsState()
   Local $sTVRepo = ""
   Local $sTVInst = ""
   For $i = 0 To 3
      If Not $aGrps[3][$i] Then $sTVRepo = $sTVRepo & $aGrps[2][$i]
      If Not $aGrps[5][$i] Then $sTVInst = $sTVInst & $aGrps[4][$i]
   Next

   _GUITreeViewEx_CloseTV($cTVRepo)
   _GUICtrlTreeView_DeleteAll($cTVRepo)
   _GUITreeViewEx_LoadTV($cTVRepo, StringLeft($sTVRepo, StringLen($sTVRepo) - 1))
   _GUICtrlTreeView_Expand($cTVRepo)
   _GUITreeViewEx_InitTV($cTVRepo,True)

   _GUITreeViewEx_CloseTV($cTVInst)
   _GUICtrlTreeView_DeleteAll($cTVInst)
   _GUITreeViewEx_LoadTV($cTVInst, StringLeft($sTVInst, StringLen($sTVInst) - 1))
   _GUICtrlTreeView_Expand($cTVInst)
   _GUITreeViewEx_InitTV($cTVInst,True)

   _GUITreeViewEx_AutoCheck()
   _GUITreeViewEx_Check_All($cTVInst)

   GUICtrlSetState($cRepoLan, $iRepoLan)
EndFunc

Func __autoCheck()
   ; TODO Uninstall feature not implemented
   _GUITreeViewEx_Check_All($cTVInst)
EndFunc

Func __packData()

   Local $sTVRepoSave = _GUITreeViewEx_SaveTV($cTVRepo)
   Local $aTVRepoSplit = StringSplit($sTVRepoSave, "|~#", $STR_ENTIRESPLIT)
   Local $sPkg
   For $i = 2 To $aTVRepoSplit[0]
      $sPkg = StringSplit($aTVRepoSplit[$i], "|")[1]
      If StringInStr($sPkg, "(") Then $sPkg = StringStripWS(StringSplit($sPkg, "(")[1], $STR_STRIPALL)
      _ArrayAdd($aPackagesNew, $sPkg)
      $iPackagesNew = $iPackagesNew + 1
   Next

   Local $sTVInstSave = _GUITreeViewEx_SaveTV($cTVInst)
   Local $aTVInstSplit = StringSplit($sTVInstSave, "|~", $STR_ENTIRESPLIT)
   For $i = 2 To $aTVInstSplit[0]
      If StringLeft($aTVInstSplit[$i], 1) <> "#" Then
         _ArrayAdd($aPackagesOld, StringSplit($aTVInstSplit[$i], "|")[1])
         $iPackagesOld = $iPackagesOld + 1
      EndIf
   Next
    __repoLan()
   GetPackagesNewAndOld()
EndFunc

Func __updateVersion()
   FileChangeDir($PATH_ROOT)
   RunWait("git pull " & $sParmsGit)
   _FileCreate($PATH_RESTARTTRIGGER)
EndFunc

Func __repoLan()

   Local $fLauncherCfg = FileOpen($CFG_LAUNCHER, $FO_READ)
   Local $sConfig = "", $sLineCfg
   Local $iRepoLanState = 0
   If BitAnd(GUICtrlRead($cRepoLan), $GUI_CHECKED) = $GUI_CHECKED Then $iRepoLanState = 1
   While True
      $sLineCfg = FileReadLine($fLauncherCfg)
      If @error Then ExitLoop
	  If StringRegExp($sLineCfg, $DAT_REPOLAN & '(.*)') Then
         $sConfig = $sConfig & $DAT_REPOLAN & $iRepoLanState & @CRLF
      Else
         $sConfig = $sConfig & $sLineCfg & @CRLF
      EndIf 
   Wend
   FileClose($fLauncherCfg)
   Local $fConfigOut = FileOpen($CFG_LAUNCHER, $FO_OVERWRITE)
   FileWrite($fConfigOut, $sConfig)
   FileClose($fConfigOut)

   If $iRepoLanState Then
      _ArrayAdd($aPackagesNew, $PKG_REPOLAN)
      $iPackagesNew = $iPackagesNew + 1
   EndIf
EndFunc

Func __repoLanCheck()

   If BitAnd(GUICtrlRead($cRepoLan), $GUI_CHECKED) = $GUI_CHECKED And Not FileExists($PATH_REPO & "\" & $DIR_BASE) Then
      GuiSetState(@SW_DISABLE)
      MsgBox($MB_OK + $MB_ICONWARNING + $MB_SYSTEMMODAL + $MB_SETFOREGROUND, "Welcome to Thorkspace's LAN contagion!", "Checking this box your Thorkspace copy will become a LAN server for others to download packages (or even Thorkspace's scripts)." & @CRLF & @CRLF & "You will have to download every package from your current server (for your current version)... and it will take a few minutes." & @CRLF & "Please be patient." & @CRLF & @CRLF & "Once download is done, every time you run your Thorkspace a HFS server will start on your computer, letting others configure your LAN IP on their packages.cfg file so they don't need Internet to install new packages." & @CRLF & @CRLF & "Thanks for spreading Thorkspace!")
      GuiSetState(@SW_ENABLE)
   EndIf
EndFunc
#EndRegion FUNCTION
