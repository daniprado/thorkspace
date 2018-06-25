; Thorkspace Installer
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
#include <Constants.au3>
#include <FileConstants.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include "TSConstants.au3"
#EndRegion INCLUDE

#Region CONFIG
Const $ALWAYS = 0
Const $CREATE = 1
Const $OVERWRITE = 2
#EndRegion CONFIG

#Region FUNCTIONS
Func SimpleInstall(Const $sGrp, Const $sPkg)
   __selfDelete()
   MsgBox($MB_TASKMODAL, 'Installed Package', $sGrp & '/' & $sPkg & ' Installed!', 1)
EndFunc

Func InsertData(Const $sOrigFile, Const $sDestFile, Const $sTag, Const $iPolicy)
   If FileExists($sDestFile) Then
	  Local $sData = __getDataFromFile($sOrigFile, $sTag)
	  If $iPolicy = $ALWAYS Then
		 FileWrite($sDestFile, $sData)
	  Else
		 Local $sDestData = FileRead($sDestFile, FileGetSize($sDestFile))
		 If $iPolicy = $CREATE Then
			If Not StringInStr($sDestData, $sTag) Then
			   FileWrite($sDestFile, $sData)
			EndIf
		 ElseIf $iPolicy = $OVERWRITE Then
			If StringInStr($sDestData, $sTag) > 0 Then
			   ; TODO
			EndIf
		 EndIf
	  EndIf
   EndIf
EndFunc

Func InsertText(Const $sDestFile, Const $sText)
   If FileExists($sDestFile) Then FileWrite($sDestFile, $sText)
EndFunc

Func ReplaceText(Const $sDestFile, Const $sOrigText, Const $sDestText)
   If FileExists($sDestFile) Then
	  Local $fileIn = FileOpen($sDestFile, $FO_READ)
	  Local $sfile = FileRead($fileIn, FileGetSize($sDestFile))
	  FileClose($fileIn)
	  $sfile = StringReplace($sfile, $sOrigText, $sDestText)
	  Local $fileOut = FileOpen($sDestFile, $FO_OVERWRITE)
	  FileWrite($fileOut, $sfile)
	  FileClose($fileOut)
   EndIf
EndFunc

Func __getDataFromFile(Const $sOrigFile, Const $sTag)
   Local $fOrigFile = FileOpen($sOrigFile, $FO_READ)
   Local $sResult = ""
   Local $bCopying = False
   Local $bEnd = False
   While 1
      Local $sOrigLine = FileReadLine($fOrigFile)
      If @error Then ExitLoop

      If Not StringCompare($sTag, $sOrigLine) Then
         If Not $bCopying Then
            $bCopying = True
         Else
            $bEnd = True
         EndIf
      EndIf
      If $bCopying Then
         $sResult = $sResult & @CRLF & $sOrigLine
      EndIf
      If $bEnd Then ExitLoop
   Wend
   return $sResult
EndFunc

Func __selfDelete()
    FileDelete(@TempDir & "\scratch.cmd")
    Local $cmdfile = ':loop' & @CRLF _
            & 'del "' & @ScriptFullPath & '"' & @CRLF _
            & 'if exist "' & @ScriptFullPath & '" goto loop' & @CRLF _
            & 'del ' & @TempDir & '\scratch.cmd'
    FileWrite(@TempDir & "\scratch.cmd", $cmdfile)
    Run(@TempDir & "\scratch.cmd", @TempDir, @SW_HIDE)
EndFunc
#EndRegion FUNCTIONS

