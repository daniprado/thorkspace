; Thorkspace Uninstaller
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

#Region FUNCTIONS
Func SimpleUninstall(Const $sGrp, Const $sPkg, Const $sInstFolder)
   DirRemove(EnvGet("BINPATH") & $sInstFolder, $DIR_REMOVE)
   __SelfDelete()
   MsgBox($MB_TASKMODAL, 'Uninstalled Package', $sGrp & '/' & $sPkg & ' Uninstalled!', 1)
EndFunc

Func RemoveData(Const $sDestFile, Const $sTag)
   If FileExists($sDestFile) Then
	  Local $fDestFile = FileOpen($sDestFile, $FO_READ)
	  Local $fOutfile = FileOpen($sDestFile & "_", $FO_WRITE)
	  Local $bDeleting = False
	  Local $bEnd = False
	  While 1
		 Local $sDestLine = FileReadLine($fDestFile)
		 ; Se lee del fichero hasta que salte error (EOF)
		 If @error Then ExitLoop

		 If Not StringCompare($sTag, $sDestLine) Then
			If Not $bDeleting Then
			   $bDeleting = True
			Else
			   $bEnd = True
			EndIf
		 EndIf
		 If Not $bDeleting Then
			FileWriteLine($fOutFile, $sDestLine)
		 EndIf
		 If $bEnd Then $bDeleting = False
	  Wend
	  FileClose($fOutFile)
	  FileClose($fDestFile)
	  FileMove($sDestFile & $SEP4, $sDestFile, $FC_OVERWRITE)
   EndIf
EndFunc

Func RemoveText(Const $sDestFile, Const $sTag)
   If FileExists($sDestFile) Then
	  Local $aTags = StringSplit($sTag, @CRLF, $STR_ENTIRESPLIT)
	  Local $fDestFile = FileOpen($sDestFile, $FO_READ)
	  Local $fOutfile = FileOpen($sDestFile & $SEP4, $FO_WRITE)
	  While 1
		 Local $sDestLine = FileReadLine($fDestFile)
		 If @error Then ExitLoop

		 Local $bFound = False
		 For $i = 1 To $aTags[0]
			If StringInStr($aTags[i], $sDestLine) Then
			   $bFound = True
			   ExitLoop
			EndIf
		 Next
		 If Not $bFound Then FileWriteLine($fOutFile, $sDestLine)
	  Wend
	  FileClose($fOutFile)
	  FileClose($fDestFile)
	  FileMove($sDestFile & $SEP4, $sDestFile, $FC_OVERWRITE)
   EndIf
EndFunc

Func _SelfDelete()
    FileDelete(@TempDir & "\scratch.cmd")
    Local $cmdfile = ':loop' & @CRLF _
            & 'del "' & @ScriptFullPath & '"' & @CRLF _
            & 'if exist "' & @ScriptFullPath & '" goto loop' & @CRLF _
            & 'del ' & @TempDir & '\scratch.cmd'
    FileWrite(@TempDir & "\scratch.cmd", $cmdfile)
    Run(@TempDir & "\scratch.cmd", @TempDir, @SW_HIDE)
EndFunc
#EndRegion FUNCTIONS

