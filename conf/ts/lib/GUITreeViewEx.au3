#Region ;**** Directives created by AutoIt3Wrapper_GUI ****

;Line to add to your Main autoit script to add the ressource
#AutoIt3Wrapper_Res_File_Add=.\Modern 3 set.bmp,  RT_RCDATA, THREESTATETREEVIEW
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include-once

; #INDEX# =======================================================================================================================
; Title .........: GUITreeViewEx
; AutoIt Version : 3.3.12 +
; Language ......: English
; Description ...: Functions that assist with TreeView loading/saving and checkbox management.
; Remarks .......: - It is good practice to use _GUITreeViewEx_Close when an initiated TreeView is deleted to free the memory used
;                    by the $g_GTVEx_aTVData array which shadows the TreeView contents.
;                  - If the script already has a WM_NOTIFY handler then call the _GUITreeViewEx_WM_NOTIFY_Handler from within the
;                    existing handler and do not use _GUITreeViewEx_RegMsg
; Author(s) .....: Melba23
; from...........: https://www.autoitscript.com/forum/topic/166594-guitreeviewex-new-release-11-jan-15/
; https://www.autoitscript.com/forum/topic/80161-shelltristatetreeview/
; ===============================================================================================================================

; #INCLUDES# =========================================================================================================
#include <WindowsConstants.au3>
#include <GuiTreeView.au3>
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <Array.au3>
#include "limited_ressources.au3"


; to do
; handle keystroke
; handle selection when collapsed
; handle initial selection (when load)


; #GLOBAL VARIABLES# =================================================================================================
; TV item selection change flag
Global $g_GTVEx_hItemSelected = 0
; TV check data array
Global $g_GTVEx_aTVData[1][2] = [[0, 0]]
; [0][0] = TreeView count      [n][0] = Handle of intitiated TreeView
; [0][1] = TreeView activated  [n][1] = Array holding TreeView checkbox data
Global $g_GTVEX_ThreeState[1][2] = [[0, False]]
; [0][0] = Unused              [n][0] = Handle of intitiated TreeView
; [0][1] = Unused              [n][1] = Using ThreeState (True|False)
Const $KB_SPACE = Asc(" ")

; #CURRENT# ==========================================================================================================
; _GUITreeViewEx_LoadTV            : Fills the TreeView from a delimited string of item titles, level and check state
; _GUITreeViewEx_SaveTV            : Saves the TreeView into a delimited string of item titles, level and check state
; _GUITreeViewEx_InitTV            : Parses the TreeView to create an array of current checkbox states
; _GUITreeViewEx_CloseTV           : Removes the TreeView from the initialised list
; _GUITreeViewEx_RegMsg            : Registers the _GUITreeViewEx_WM_NOTIFY_Handler handler
; _GUITreeViewEx_WM_NOTIFY_Handler : _WM_NOTIFY_Handler handler for the UDF
; _GUITreeViewEx_AutoCheck         : Checks if a checkbox has been altered and adjust parent and children accordingly
; _GUITreeViewEx_Check_All         : Check or clear all checkboxes in an initiated TreeVie
;__GTVEx_Adjust_ParentsState($hTV, $hPassedItem, ByRef $aTVCheckData, $bState)
;
; ====================================================================================================================

; #INTERNAL_USE_ONLY#=================================================================================================
; __GTVEx_Adjust_Parents  		: Adjusts checkboxes above the one changed
; __GTVEx_Adjust_Children 		: Adjusts checkboxes below the one changed
; __GTVEx_Adjust_ParentsState	: Adjusts checkboxes above the one changed for ThreeState Treeview
; __GTVEx_LoadStateImage		: To create image structure for a three State Treeview
; __GTVEx_ImageList_LoadImage	: To load image structure for a three State Treeview
; ====================================================================================================================

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_LoadTV
; Description ...: Loads the TreeView from a delimited string of item titles, level and check state
; Syntax.........: _GUITreeViewEx_LoadTV($hTV, $sString [, $sDelimiter = "|" [, $sLevel = "~" [, $sChecked = "#"]]])
; Parameters ....: $hTV        - Handle or ControlID of TreeView
;                  $sString    - Delimited string holding item titles and level information
;                  $sDelimiter - Character delimiting item titles (default = |)
;                  $sLevel     - Character indicating level status (default - ~)
;                  $sChecked   - Character indicating item checked
; Requirement(s).: v3.3.12 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: This function works independently of _GUITreeViewEx_RegMsg
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_LoadTV($hTV, $sString, $sDelimiter = "|", $sLevel = "~", $sChecked = "#")

	Local $sTVItem, $iLevel, $bChecked

	; Ensure handle
	If Not IsHWnd($hTV) Then $hTV = GUICtrlGetHandle($hTV)
	; Array to hold current parent handles - base TreeView set to 0
	Local $aLevelParent[100] = [0]
	; Split string
	Local $aTVItems = StringSplit($sString, $sDelimiter)
	; Loop through items
	For $i = 1 To $aTVItems[0]
		; Get required level
		$sTVItem = StringReplace($aTVItems[$i], $sLevel, "")
		$iLevel = @extended
		; Check for checked flag
		$sTVItem = StringReplace($sTVItem, $sChecked, "")
		$bChecked = ((@extended) ? (True) : (False))
		; Create item using parent handle
		$aLevelParent[$iLevel + 1] = _GUICtrlTreeView_AddChild($hTV, $aLevelParent[$iLevel], $sTVItem)
		; Check if required
		If $bChecked Then _GUICtrlTreeView_SetChecked($hTV, $aLevelParent[$iLevel + 1], True)
	Next



EndFunc   ;==>_GUITreeViewEx_LoadTV

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_SaveTV
; Description ...: Saves the TreeView into a delimited string of item titles, level and check state
; Syntax.........: _GUITreeViewEx_LoadTV($hTV [, $sDelimiter = "|" [, $sLevel = "~"]])
; Parameters ....: $hTV        - Handle or ControlID of TreeView
;                  $sDelimiter - Character delimiting item titles (default = |)
;                  $sLevel     - Character indicating level status (default - ~)
;                  $sChecked   - Character indicating item checked
; Requirement(s).: v3.3.12 +
; Return values .: String containing TreeView content - format as _GUITreeViewEx_LoadTV
; Author ........: Melba23
; Modified ......:
; Remarks .......: This function works independently of _GUITreeViewEx_RegMsg
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_SaveTV($hTV, $sDelimiter = "|", $sLevel = "~", $sChecked = "#")

	Local $sString = "", $sText, $sLevelCount, $sCheck

	; Ensure handle
	If Not IsHWnd($hTV) Then $hTV = GUICtrlGetHandle($hTV)
	; Work through TreeView items
	Local $hHandle = _GUICtrlTreeView_GetFirstItem($hTV)
	While 1
		; Set level
		$sLevelCount = ""
		For $i = 1 To _GUICtrlTreeView_Level($hTV, $hHandle)
			$sLevelCount &= $sLevel
		Next
		; Get checked state
		$sCheck = ""
		If _GUICtrlTreeView_GetChecked($hTV, $hHandle) Then $sCheck = $sChecked
		; Get text
		$sText = _GUICtrlTreeView_GetText($hTV, $hHandle)
		; Add to string
		$sString &= $sLevelCount & $sCheck & $sText & $sDelimiter
		; Move to next item
		$hHandle = _GUICtrlTreeView_GetNext($hTV, $hHandle)
		; Exit if at end
		If $hHandle = 0 Then ExitLoop
	WEnd
	; Remove final delimiter
	Return StringTrimRight($sString, 1)

EndFunc   ;==>_GUITreeViewEx_SaveTV

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_InitTV
; Description ...: Parses the TreeView to create an array of current checkbox states
; Syntax.........: _GUITreeViewEx_InitTV($hTV)
; Parameters ....: $hTV - Handle or ControlID of TreeView
; Requirement(s).: v3.3 12 +
; Return values .: None
; Author ........: Melba23
; Modified ......: Gillesg to add ThreeState Treeview possibilities
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_InitTV($hTV, $ThreeState = False)
	; Ensure handle
	If Not IsHWnd($hTV) Then $hTV = GUICtrlGetHandle($hTV)

	_GUITreeViewEx_3stateTV($hTV, $ThreeState)
	; Basic check data array and item count
	Local $aParseTV[10][2], $iParseCount = 0

	; Work through TreeView items
	Local $hHandle = _GUICtrlTreeView_GetFirstItem($hTV)
	While 1
		; Add item to array
		$aParseTV[$iParseCount][0] = $hHandle
		$aParseTV[$iParseCount][1] = _GUICtrlTreeView_GetChecked($hTV, $hHandle)
		; increase count
		$iParseCount += 1
		; Enlarge array if required (minimizes ReDim usage)
		If $iParseCount > UBound($aParseTV) - 1 Then
			ReDim $aParseTV[$iParseCount * 2][2]
		EndIf
		; Move to next item
		$hHandle = _GUICtrlTreeView_GetNext($hTV, $hHandle)
		; Exit if at end
		If $hHandle = 0 Then ExitLoop
	WEnd
	; Remove any empty array elements
	ReDim $aParseTV[$iParseCount][2]

	; Resize main data array
	$g_GTVEx_aTVData[0][0] += 1
	ReDim $g_GTVEx_aTVData[$g_GTVEx_aTVData[0][0] + 1][2]
	; Store TreeView handle and check data
	$g_GTVEx_aTVData[$g_GTVEx_aTVData[0][0]][0] = $hTV
	$g_GTVEx_aTVData[$g_GTVEx_aTVData[0][0]][1] = $aParseTV

EndFunc   ;==>_GUITreeViewEx_InitTV

Func _GUITreeViewEx_3stateTV($hTV, $ThreeState = False)
	Local $TreeIndex = -1
	; Ensure handle
	If Not IsHWnd($hTV) Then $hTV = GUICtrlGetHandle($hTV)

	If $ThreeState == True Then
		$TreeIndex = _ArraySearch($g_GTVEX_ThreeState, $hTV)
		If $TreeIndex <> -1 Then
			;already ThreeState
			$g_GTVEX_ThreeState[$TreeIndex][1] = True
		Else
			Local $inewindex = _ArrayAdd($g_GTVEX_ThreeState, "|True")
			$g_GTVEX_ThreeState[0][0] += 1
			$g_GTVEX_ThreeState[$inewindex][0] = $hTV
		EndIf

		;will be extract from Exe
		__GTVEx_LoadStateImage($hTV, $CBSTYLE)
	Else
		$TreeIndex = _ArraySearch($g_GTVEX_ThreeState, $hTV)
		If $TreeIndex <> -1 Then
			;already ThreeState
			_ArrayDelete($g_GTVEX_ThreeState, $TreeIndex)
		EndIf
	EndIf
EndFunc   ;==>_GUITreeViewEx_3stateTV


; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_CloseTV
; Description ...: Removes the TreeView from the initialised list
; Syntax.........: _GUITreeViewEx_CloseTV($hTV)
; Parameters ....: $hTV - Handle or ControlID of TreeView
; Requirement(s).: v3.3 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_CloseTV($hTV)
	; Ensure handle
	If Not IsHWnd($hTV) Then $hTV = GUICtrlGetHandle($hTV)

	; Search array
	For $i = 1 To $g_GTVEx_aTVData[0][0]
		If $hTV = $g_GTVEx_aTVData[$i][0] Then
			_ArrayDelete($g_GTVEx_aTVData, $i)
			$g_GTVEx_aTVData[0][0] -= 1
			ExitLoop
		EndIf
	Next
	_GUITreeViewEx_3stateTV($hTV, False)

EndFunc   ;==>_GUITreeViewEx_CloseTV

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_RegMsg
; Description ...: Registers the _GUITreeViewEx_WM_NOTIFY_Handler handler
; Syntax.........: _GUITreeViewEx_RegMsg()
; Parameters ....: None
; Requirement(s).: v3.3.12 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If the script already has a WM_NOTIFY handler then call the _GUITreeViewEx_WM_NOTIFY_Handler from within the
;                  existing handler and do not use _GUITreeViewEx_RegMsg
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_RegMsg()

	; Register handler
	GUIRegisterMsg($WM_NOTIFY, "_GUITreeViewEx_WM_NOTIFY_Handler")

EndFunc   ;==>_GUITreeViewEx_RegMsg

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_WM_NOTIFY_Handler
; Description ...: _WM_NOTIFY_Handler handler for the UDF
; Syntax.........: _GUITreeViewEx_WM_NOTIFY_Handler($hWnd, $iMsg, $wParam, $lParam)
; Parameters ....: None
; Requirement(s).: v3.3.12 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If the script already has a WM_NOTIFY handler then call the _GUITreeViewEx_WM_NOTIFY_Handler from within the
;                  existing handler and do not use _GUITreeViewEx_RegMsg
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_WM_NOTIFY_Handler($hWnd, $iMsg, $wParam, $lParam)
	; to avoid complaint on Variable declared, but not used
	#forceref $hWnd, $iMsg, $wParam
	Local Static $hItemSelected = 0
	;Local Static
	Local $hItem, $cKey, $iState
	Local $tStruct, $hWndFrom
	Local $cChanged, $cNewState, $cOldState, $holdItem


	; Create NMTREEVIEW structure
	;Local $tStruct = DllStructCreate(
	;	"struct;hwnd hWndFrom;uint_ptr IDFrom;INT Code;endstruct;" & _
	;		"uint Action;" & _
	;	"struct;uint OldMask;handle OldhItem;uint OldState;uint OldStateMask;" & _
	;		"ptr OldText;int OldTextMax;int OldImage;int OldSelectedImage;int OldChildren;lparam OldParam;endstruct;" & _
	;	"struct;uint NewMask;handle NewhItem;uint NewState;uint NewStateMask;" & _
	;		"ptr NewText;int NewTextMax;int NewImage;int NewSelectedImage;int NewChildren;lparam NewParam;endstruct;" & _
	;	"struct;long PointX;long PointY;endstruct", $lParam)
	$tStruct = DllStructCreate($tagNMTREEVIEW, $lParam)

	$hWndFrom = DllStructGetData($tStruct, "hWndFrom")
	; Check TreeView initiated - Loop thru declared TreeView
	Local $i = _ArraySearch($g_GTVEx_aTVData, $hWndFrom, 1)

	If $i <> -1 Then
		If $hWndFrom = $g_GTVEx_aTVData[$i][0] Then
			Switch DllStructGetData($tStruct, "Code")
				; If item selection changed

				Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
					;TVN_SELCHANGEDW (Unicode) and TVN_SELCHANGEDA (ANSI)
					$holdItem = DllStructGetData($tStruct, "OldhItem")
					$hItem    = DllStructGetData($tStruct, "NewhItem")
					ConsoleWrite("for $TVN_SELCHANGEDW hitem= " & $hItem    & "  "& _GUICtrlTreeView_GetText($hWndFrom, $hItem) &@CRLF)
					ConsoleWrite("                   OldItem= " & $holdItem & "  "& _GUICtrlTreeView_GetText($hWndFrom, $holdItem) & @CRLF)

					$hItemSelected = $hItem
					; Set flag to selected item handle
					$g_GTVEx_hItemSelected = 0
					If $hItem Then $g_GTVEx_hItemSelected = $hItem
					; Store TreeView handle
					$g_GTVEx_aTVData[0][1] = $hWndFrom

				Case $TVN_KEYDOWN
					; Occurs before standard selection by the control
					$tStruct= DllStructCreate($tagNMTVKEYDOWN, $lParam)
					$cKey = DllStructGetData($tStruct, "vKey")
					;ConsoleWrite("$hItemSelected="&$hItemSelected&@CRLF)
					Consolewrite("for $TVN_KEYDOWN - vKey is "& $cKey& @CRLF)
					Consolewrite("                  Flags is "& DllStructGetData($tStruct, "Flags")& @CRLF)


					; find the selected
					$hItem = $hItemSelected
					If $cKey = $KB_SPACE Then
						;Consolewrite("in adjustement "&@CRLF)
						If $hItem Then
							$g_GTVEx_hItemSelected = $hItem
							$iState = _GUICtrlTreeView_GetCheckedState($hWndFrom, $g_GTVEx_hItemSelected)
							ConsoleWrite("status =" & $iState & " for node " & _GUICtrlTreeView_GetText($hWndFrom, $g_GTVEx_hItemSelected) & @CRLF)
							If $iState = 2 Then
								If _GUICtrlTreeView_GetChildCount($hWndFrom, $g_GTVEx_hItemSelected) = -1 Then
									consolewrite("no child"&@CRLF)
									_GUICtrlTreeView_SetChecked($hWndFrom, $g_GTVEx_hItemSelected, False)
								EndIf
							EndIf
						EndIf
						; Store TreeView handle
						$g_GTVEx_aTVData[0][1] = $hWndFrom
					EndIf
				Case $TVN_ITEMCHANGEDA, $TVN_ITEMCHANGEDW
					;TVN_ITEMCHANGEDW (Unicode) and TVN_ITEMCHANGEDA (ANSI)

					;create proper Struct
					$tStruct = DllStructCreate($tagNMTVITEMCHANGE, $lParam)
					$hItem=      DllStructGetData($tStruct,"hItem")
					$cNewState = DllStructGetData($tStruct, "StateNew")
					$cOldState = DllStructGetData($tStruct, "StateOld")
					ConsoleWrite("for $TVN_ITEMCHANGEDW hitem= " & $hitem & " " & _GUICtrlTreeView_GetText($hWndFrom, $hItem) & @CRLF)
					Consolewrite("                  $cChanged="&$cChanged&@CRLF)
					ConsoleWrite("                 $cNewState="&$cNewState&@CRLF)
					ConsoleWrite("                 $cOldState="&$cOldState&@CRLF)

					if $hItemSelected = $hItem Then
						consolewrite( "> may be modified because is the selected"&@CRLF)
						$iState = _GUICtrlTreeView_GetCheckedState($hWndFrom, $g_GTVEx_hItemSelected)
						if $iState = 2 then
							consolewrite( "> is modified"&@CRLF)
							_GUICtrlTreeView_SetChecked($hWndFrom, $g_GTVEx_hItemSelected, False)
						EndIf
					EndIf
					#cs
					$hItemSelected = $hItem
					; Set flag to selected item handle
					$g_GTVEx_hItemSelected = 0
					If $hItem Then $g_GTVEx_hItemSelected = $hItem
					; Store TreeView handle
					$g_GTVEx_aTVData[0][1] = $hWndFrom
					#ce

				;case else
					;If DllStructGetData($tStruct, "Code") < -400 Then
						;$hItem = DllStructGetData($tStruct, "NewhItem")
						;ConsoleWrite("msg " & DllStructGetData($tStruct, "Code") & " " & DllStructGetData($tStruct, "Action"))
						;If $hItem <> 0 Then ConsoleWrite(" item " & $hItem & "  " & _GUICtrlTreeView_GetText($hWndFrom, $hItem))
						;ConsoleWrite(@CRLF)
					;EndIf
			EndSwitch

		Else
			ConsoleWrite("not hwnd" & @CRLF)
		EndIf
		;Next
	EndIf
EndFunc   ;==>_GUITreeViewEx_WM_NOTIFY_Handler

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_AutoCheck
; Description ...: Checks if an item chaeckbox has been altered and adjust parent and children accordingly
; Syntax.........: _GUITreeViewEx_AutoCheck()
; Parameters ....: None
; Requirement(s).: v3.3.12 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: This function must be placed in the script idle loop
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_AutoCheck()

	Local $aTVCheckData, $bState, $iItemIndex, $iTVIndex, $iState

	; If an item has been selected
	If $g_GTVEx_hItemSelected Then

		; Read TreeView handle of the item and confirm initiated  and index
		Local $hTV = $g_GTVEx_aTVData[0][1]
		$iTVIndex = _ArraySearch($g_GTVEx_aTVData, $hTV, 1)

		If $iTVIndex <> -1 Then

			; Extract check data array
			$aTVCheckData = $g_GTVEx_aTVData[$iTVIndex][1]

			If _ArraySearch($g_GTVEX_ThreeState, $hTV) <> -1 Then
				$iState = _GUICtrlTreeView_GetCheckedState($hTV, $g_GTVEx_hItemSelected)
				consolewrite("STate of "& _GUICtrlTreeView_GetText($hTV, $g_GTVEx_hItemSelected) &" is " & $iState & @CRLF)
				If $iState = 2 Then
					If _GUICtrlTreeView_GetChildCount($hTV, $g_GTVEx_hItemSelected) = -1 Then
						; if no child unchecked
						consolewrite("no child"&@CRLF)
						_GUICtrlTreeView_SetChecked($hTV, $g_GTVEx_hItemSelected, False)
					Else
						consolewrite("with child do nothing"&@CRLF)
							; it has child look for expand status
						;If _GUICtrlTreeView_GetExpanded($hTV, $g_GTVEx_hItemSelected) Then
							;if expanded then change uncheck
						;	_GUICtrlTreeView_SetChecked($hTV, $g_GTVEx_hItemSelected, False)
						;EndIf
					EndIf
				EndIf
			EndIf

			; Determine checked state
			$bState = _GUICtrlTreeView_GetChecked($hTV, $g_GTVEx_hItemSelected)
			; Find item in array
			$iItemIndex = _ArraySearch($aTVCheckData, $g_GTVEx_hItemSelected)
			ConsoleWrite("$iItemIndex=" & $iItemIndex & @CRLF)
			; If checked state has altered
			If $iItemIndex <> -1 And $aTVCheckData[$iItemIndex][1] <> $bState Then
				; Store new state
				$aTVCheckData[$iItemIndex][1] = $bState
				; Adjust parents and children as required
				consolewrite("adjust parent of "& _GUICtrlTreeView_GetText($hTV, $g_GTVEx_hItemSelected)&@CRLF)
				__GTVEx_Adjust_Parents($hTV, $g_GTVEx_hItemSelected, $aTVCheckData, $bState)
				consolewrite("adjust child of "& _GUICtrlTreeView_GetText($hTV, $g_GTVEx_hItemSelected)&@CRLF)
				__GTVEx_Adjust_Children($hTV, $g_GTVEx_hItemSelected, $aTVCheckData, $bState)
			EndIf
			; Store amended array
			$g_GTVEx_aTVData[$iTVIndex][1] = $aTVCheckData

		EndIf
		; Clear selected flag
		$g_GTVEx_hItemSelected = 0
	EndIf

EndFunc   ;==>_GUITreeViewEx_AutoCheck

; #FUNCTION# =========================================================================================================
; Name...........: _GUITreeViewEx_Check_All
; Description ...: Check or clear all checkboxes in an initiated TreeView
; Syntax.........: _GUITreeViewEx_Check_All($hTV [, $bState = True])
; Parameters ....: $hTV    - Handle or ControlID of TreeView
;                  $bState - True (default) = set all checkboxes
;                            False          = clear all checkboxes
; Requirement(s).: v3.3.12 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUITreeViewEx_Check_All($hTV, $bState = True)

	; Ensure handle
	If Not IsHWnd($hTV) Then $hTV = GUICtrlGetHandle($hTV)

	; Confirm TreeView is initiated
	For $iIndex = 1 To $g_GTVEx_aTVData[0][0]
		If $hTV = $g_GTVEx_aTVData[$iIndex][0] Then
			; Extract check data
			Local $aTVData = $g_GTVEx_aTVData[$iIndex][1]
			; Loop through items
			For $i = 0 To UBound($aTVData) - 1
				; Adjust item
				_GUICtrlTreeView_SetChecked($hTV, $aTVData[$i][0], $bState)
				; Adjust array
				$aTVData[$i][1] = $bState
			Next
			; Store amended array
			$g_GTVEx_aTVData[$iIndex][1] = $aTVData
			; No point in looping further
			ExitLoop
		EndIf
	Next

EndFunc   ;==>_GUITreeViewEx_Check_All

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GTVEx_Adjust_Parents
; Description ...: Adjusts checkboxes above the one changed for none three state tree.
; Author ........: Melba23
; ===============================================================================================================================
Func __GTVEx_Adjust_Parents($hTV, $hPassedItem, ByRef $aTVCheckData, $bState = True)

	; Get handle of parent
	Local $hParent = _GUICtrlTreeView_GetParentHandle($hTV, $hPassedItem)
	If $hParent = 0 Then Return

	If _ArraySearch($g_GTVEX_ThreeState, $hTV) == -1 Then
		; Assume parent is to be adjusted
		Local $bAdjustParent = True
		; Find parent in array
		Local $iItemIndex = _ArraySearch($aTVCheckData, $hParent)

		; Need to confirm all siblings clear before clearing parent
		If $bState = False Then
			; Check on number of siblings
			Local $iCount = _GUICtrlTreeView_GetChildCount($hTV, $hParent)
			; If only 1 sibling then parent can be cleared - if more then need to look at them all
			If $iCount <> 1 Then
				; Number of siblings checked
				Local $iCheckCount = 0
				; Move through previous siblings
				Local $hSibling = $hPassedItem
				While $iCheckCount == 0
					$hSibling = _GUICtrlTreeView_GetPrevSibling($hTV, $hSibling)
					; If found
					If $hSibling Then
						; Is sibling checked
						If _GUICtrlTreeView_GetChecked($hTV, $hSibling) Then
							; Increase count if so
							$iCheckCount += 1
						EndIf
					Else
						; No point in continuing
						ExitLoop
					EndIf
				WEnd
				; Move through later siblings
				$hSibling = $hPassedItem
				While $iCheckCount == 0
					$hSibling = _GUICtrlTreeView_GetNextSibling($hTV, $hSibling)
					If $hSibling Then
						If _GUICtrlTreeView_GetChecked($hTV, $hSibling) Then
							$iCheckCount += 1
						EndIf
					Else
						ExitLoop
					EndIf
				WEnd
				; If at least one sibling checked then do not clear parent
				If $iCheckCount Then $bAdjustParent = False
			EndIf
		EndIf
		; If parent is to be adjusted
		If $bAdjustParent Then
			; Adjust the array
			$aTVCheckData[$iItemIndex][1] = $bState
			; Adjust the parent
			_GUICtrlTreeView_SetChecked($hTV, $hParent, $bState)
			; And now do the same for the generation above
			__GTVEx_Adjust_Parents($hTV, $hParent, $aTVCheckData, $bState)
		EndIf
	Else
		__GTVEx_Adjust_ParentsState($hTV, $hPassedItem, $aTVCheckData, $bState)
	EndIf

EndFunc   ;==>__GTVEx_Adjust_Parents

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GTVEx_Adjust_ParentsState
; Description ...: Adjusts checkboxes above the one changed on a ThreeState TreeView
; Author ........: Based on the works of Melba23. Addition Gillesg for Three State treeview
; ===============================================================================================================================
Func __GTVEx_Adjust_ParentsState($hTV, $hPassedItem, ByRef $aTVCheckData, $bState)

	; Get handle of parent
	Local $hParent = _GUICtrlTreeView_GetParentHandle($hTV, $hPassedItem)
	If $hParent = 0 Then Return
	; Find parent in array
	Local $iItemIndex = _ArraySearch($aTVCheckData, $hParent)
	; Number of siblings checked, intermidaite info
	Local $iCheckCount = 0, $iINTERMEDIATE = 0

	; Check on number of siblings
	Local $iCountsiblings = _GUICtrlTreeView_GetChildCount($hTV, $hParent)
	If $iCountsiblings == 1 Then
		_GUICtrlTreeView_SetCheckedState($hTV, $hParent, $bState)
		$aTVCheckData[$iItemIndex][1] = $bState
		__GTVEx_Adjust_ParentsState($hTV, $hParent, $aTVCheckData, $bState)
	ElseIf $iCountsiblings <> 1 Then
		; If only 1 sibling then parent should be set accordingly

		If $bState = 1 Or $bState = True Then $iCheckCount += 1
		If $bState == 2 Then $iINTERMEDIATE += 1

		; Move through previous siblings
		Local $hSibling = $hPassedItem
		Local $iSiblingState
		If $iINTERMEDIATE == 0 Then
			While 1
				$hSibling = _GUICtrlTreeView_GetPrevSibling($hTV, $hSibling)
				; If found
				If $hSibling Then
					; Which Status is the sibling ?
					$iSiblingState = _GUICtrlTreeView_GetCheckedState($hTV, $hSibling)
					If $iSiblingState = 1 Then $iCheckCount += 1
					If $iSiblingState = 2 Then
						$iINTERMEDIATE += 1
						ExitLoop
					EndIf
				Else
					; No point in continuing
					ExitLoop
				EndIf
			WEnd
		EndIf
		; Move through later siblings
		; if not intermediate
		If $iINTERMEDIATE == 0 Then
			$hSibling = $hPassedItem
			While 1
				$hSibling = _GUICtrlTreeView_GetNextSibling($hTV, $hSibling)
				If $hSibling Then
					; Which Status is the sibling ?
					$iSiblingState = _GUICtrlTreeView_GetCheckedState($hTV, $hSibling)
					If $iSiblingState = 1 Then $iCheckCount += 1
					If $iSiblingState = 2 Then
						$iINTERMEDIATE += 1
						ExitLoop
					EndIf
				Else
					ExitLoop
				EndIf
			WEnd
		EndIf

		If $iINTERMEDIATE > 0 Then
			_GUICtrlTreeView_SetCheckedState($hTV, $hParent, $GUI_INDETERMINATE)
			ConsoleWrite("> adjust Parent (" & @ScriptLineNumber & ") " & _GUICtrlTreeView_GetText($hTV, $hParent) & " set to " & $GUI_INDETERMINATE & @CRLF)
			$aTVCheckData[$iItemIndex][1] = True
			__GTVEx_Adjust_ParentsState($hTV, $hParent, $aTVCheckData, $GUI_INDETERMINATE)
		ElseIf $iCheckCount = 0 Then
			_GUICtrlTreeView_SetChecked($hTV, $hParent, False)
			ConsoleWrite("> adjust Parent (" & @ScriptLineNumber & ") " & _GUICtrlTreeView_GetText($hTV, $hParent) & " set to " & False & @CRLF)

			$aTVCheckData[$iItemIndex][1] = False
			__GTVEx_Adjust_ParentsState($hTV, $hParent, $aTVCheckData, False)
		ElseIf $iCheckCount = $iCountsiblings Then
			_GUICtrlTreeView_SetChecked($hTV, $hParent, True)
			$aTVCheckData[$iItemIndex][1] = True
			ConsoleWrite("> adjust Parent (" & @ScriptLineNumber & ") " & _GUICtrlTreeView_GetText($hTV, $hParent) & " set to " & True & @CRLF)
			__GTVEx_Adjust_ParentsState($hTV, $hParent, $aTVCheckData, True)
		Else
			_GUICtrlTreeView_SetCheckedState($hTV, $hParent, $GUI_INDETERMINATE)
			$aTVCheckData[$iItemIndex][1] = True
			__GTVEx_Adjust_ParentsState($hTV, $hParent, $aTVCheckData, $GUI_INDETERMINATE)
		EndIf
	EndIf
EndFunc   ;==>__GTVEx_Adjust_ParentsState

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GTVEx_Adjust_Children
; Description ...: Adjusts checkboxes below the one changed
; Author ........: Melba23
; ===============================================================================================================================
Func __GTVEx_Adjust_Children($hTV, $hPassedItem, ByRef $aTVCheckData, $bState = True)

	Local $iItemIndex

	; Get the handle of the first child
	Local $hChild = _GUICtrlTreeView_GetFirstChild($hTV, $hPassedItem)
	If $hChild = 0 Then Return
	While 1
		; Find child index
		$iItemIndex = _ArraySearch($aTVCheckData, $hChild)
		; Adjust the array
		$aTVCheckData[$iItemIndex][1] = $bState
		; Adjust the child
		_GUICtrlTreeView_SetChecked($hTV, $hChild, $bState)
		ConsoleWrite("> adjust Child (" & @ScriptLineNumber & ") " & _GUICtrlTreeView_GetText($hTV, $hChild) & " set to " & $bState & @CRLF)
		; And now do the same for the generation beow
		__GTVEx_Adjust_Children($hTV, $hChild, $aTVCheckData, $bState)
		; Now get next child
		$hChild = _GUICtrlTreeView_GetNextChild($hTV, $hChild)
		; Exit the loop if no more found
		If $hChild = 0 Then ExitLoop
	WEnd

EndFunc   ;==>__GTVEx_Adjust_Children

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: 	__GTVEx__LoadStateImage
; Description ...: 	Based on the work of Holger Kotsch to make a three State TreeView
;					Load the image list. Image list is composed of 4 bpm image of 16x16 nothing, unselect, Select, undetermine.
;					using of _GTVEx_ImageList_LoadImage
; Author ........:  Holger Kotsch
; ===============================================================================================================================
Func __GTVEx_LoadStateImage($hTreeView, $sFile)
	Local $hWnd = GUICtrlGetHandle($hTreeView)
	Local $mybmp
	If $hWnd = 0 Then $hWnd = $hTreeView
	Local $RT_RCDATA = 10

	Local $hImageList = 0

	If @Compiled Then
		$mybmp = _TempFile()
		__GTVEX_ResourceSaveToFile($mybmp, "THREESTATETREEVIEW", $RT_RCDATA, 0, 1)
		$sFile = $mybmp
	EndIf
	$hImageList = __GTVEx_ImageList_LoadImage(0, $sFile, 16, 1, $CLR_NONE, $IMAGE_BITMAP, BitOR($LR_LOADFROMFILE, $LR_LOADTRANSPARENT, $LR_CREATEDIBSECTION))
	If @Compiled Then FileDelete($mybmp)

	_SendMessage($hWnd, $TVM_SETIMAGELIST, $TVSIL_STATE, $hImageList)
	_WinAPI_InvalidateRect($hWnd, 0, 1)
EndFunc   ;==>__GTVEx_LoadStateImage


; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: 	_GTVEx_ImageList_LoadImage
; Description ...: 	Based on the work of Holger to make a three State TreeView
; Author ........:  Holger Kotsch
; ===============================================================================================================================
Func __GTVEx_ImageList_LoadImage($hInst, $sFile, $cx, $cGrow, $crMask, $uType, $uFlags)
	Local $hImageList = DllCall("comctl32.dll", "hwnd", "ImageList_LoadImage", _
			"hwnd", $hInst, _
			"str", $sFile, _
			"int", $cx, _
			"int", $cGrow, _
			"int", $crMask, _
			"int", $uType, _
			"int", $uFlags)
	Return $hImageList[0]
EndFunc   ;==>__GTVEx_ImageList_LoadImage


; #FUNCTION# =========================================================================================================
; Name...........: _GUICtrlTreeView_SetCheckedState
; Description ...: To set the selection status of a node in the treeState treeview
; Syntax.........: _GUICtrlTreeView_SetCheckedState($hWnd, $hItem, $bCheck = True)
; Parameters ....: $hTV        - Handle or ControlID of TreeView
;                  $hItem      - Handle to the node to set the checked status
;                  $bCheck     - Value for the status to be set
;                                Default : True - Node wil be checked
;                     Supported values: True, $GUI_CHECKED - To have the node checked
;                                       False, $GUI_UNCHECKED - To have the node unchecked
;                                       $GUI_INDETERMINATE - To have the node in between
; Requirement(s).: v3.3.12 +
; Return values .: None
; Author ........: Based on the work of Holger Kotsch (https://www.autoitscript.com/forum/topic/28464-tristate-gui-treeview/)
; Modified ......: Gillesg - adaptation also based on function _GUICtrlTreeView_SetCheckedd
; Remarks .......: This function works independently of _GUITreeViewEx_RegMsg
; Example........:
;=====================================================================================================================
Func _GUICtrlTreeView_SetCheckedState($hWnd, $hItem, $bCheck = True)
	If Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)

	If IsBool($bCheck) Then
		Return _GUICtrlTreeView_SetChecked($hWnd, $hItem, $bCheck)
	Else
		Switch $bCheck
			Case $GUI_CHECKED
				Return _GUICtrlTreeView_SetChecked($hWnd, $hItem, True)
			Case $GUI_UNCHECKED
				Return _GUICtrlTreeView_SetChecked($hWnd, $hItem, False)
			Case $GUI_INDETERMINATE
				;test if $hWnd is a ThreeState Tree.
				If _ArraySearch($g_GTVEX_ThreeState, $hWnd) <> -1 Then
					Local $tItem = DllStructCreate($tagTVITEMEX)
					DllStructSetData($tItem, "Mask", $TVIF_STATE)
					DllStructSetData($tItem, "hItem", $hItem)
					DllStructSetData($tItem, "State", BitShift($bCheck + 1, -12))
					DllStructSetData($tItem, "StateMask", 0xf000)
					Return __GUICtrlTreeView_SetItem($hWnd, $tItem)
				Else
					; if not SetChecked with True
					Return _GUICtrlTreeView_SetChecked($hWnd, $hItem, True)
				EndIf
		EndSwitch
	EndIf

EndFunc   ;==>_GUICtrlTreeView_SetCheckedState


; #FUNCTION# =========================================================================================================
; Name...........: _GUICtrlTreeView_GetCheckedState
; Description ...: To get the selection status of a node in the treeState treeview
; Syntax.........: _GUICtrlTreeView_GetCheckedState($hWnd, $hItem)
; Parameters ....: $hTV        - Handle or ControlID of TreeView
;                  $hItem      - Handle to the node to set the checked status
;                     Supported values: True, $GUI_CHECKED - To have the node checked
;                                       False, $GUI_UNCHECKED - To have the node unchecked
;                                       $GUI_INDETERMINATE - To have the node in between
; Requirement(s).: v3.3.12 +
; Return values .: correspond to the checked status of selection
;					  True, 1 for the node checked
;                     False, 0 for the node not checked
;                     2 for the node in between
;
; Author ........: Based on the work of Holger Kotsch (https://www.autoitscript.com/forum/topic/28464-tristate-gui-treeview/)
; Modified ......: Gillesg - adaptation also based on function _GUICtrlTreeView_SetCheckedd
; Remarks .......: This function works independently of _GUITreeViewEx_RegMsg
; Example........:
;=====================================================================================================================
Func _GUICtrlTreeView_GetCheckedState($hWnd, $hItem)
	If Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)

	Local $tItem = DllStructCreate($tagTVITEMEX)
	DllStructSetData($tItem, "Mask", $TVIF_STATE)
	DllStructSetData($tItem, "hItem", $hItem)
	__GUICtrlTreeView_GetItem($hWnd, $tItem)
	Return BitShift(DllStructGetData($tItem, "State"), 12) - 1
EndFunc   ;==>_GUICtrlTreeView_GetCheckedState

#comments-start

; Based on _ressource.au3
;Global Const $RT_BITMAP = 2
;Global Const $RT_RCDATA = 10
Func __GTVEX_ResourceSaveToFile($FileName, $ResName, $ResType = 10, $ResLang = 0, $CreatePath = 0, $DLL = -1) ; $RT_RCDATA = 10
	Local $ResStruct, $ResSize, $FileHandle

	If $CreatePath Then $CreatePath = 8 ; mode 8 = Create directory structure if it doesn't exist in FileOpen()

	; standard way
	$ResStruct = __GTVEX_ResourceGetAsBytes($ResName, $ResType, $ResLang, $DLL)
	If @error Then Return SetError(1, 0, 0)
	$ResSize = DllStructGetSize($ResStruct)

	$FileHandle = FileOpen($FileName, 2 + 16 + $CreatePath)
	If @error Then Return SetError(2, 0, 0)
	FileWrite($FileHandle, DllStructGetData($ResStruct, 1))
	If @error Then Return SetError(3, 0, 0)
	FileClose($FileHandle)
	If @error Then Return SetError(4, 0, 0)

	Return $ResSize
EndFunc   ;==>__GTVEX_ResourceSaveToFile

; _ResourceGetAsBytes() doesn't work for RT_BITMAP type
; because _ResourceGet() returns hBitmap instead of memory pointer in this case
Func __GTVEX_ResourceGetAsBytes($ResName, $ResType = 10, $ResLang = 0, $DLL = -1) ; $RT_RCDATA = 10
	Local $ResPointer, $ResSize

	$ResPointer = __GTVEX_ResourceGet($ResName, $ResType, $ResLang, $DLL)
	If @error Then Return SetError(1, 0, 0)
	$ResSize = @extended
	Return DllStructCreate("byte[" & $ResSize & "]", $ResPointer) ; returns struct with bytes
EndFunc   ;==>__GTVEX_ResourceGetAsBytes

Func __GTVEX_ResourceGet($ResName, $ResType = 10, $ResLang = 0, $DLL = -1) ; $RT_RCDATA = 10
	Local $RT_BITMAP = 2

	Local Const $IMAGE_BITMAP = 0
	Local $hInstance, $hBitmap, $InfoBlock, $GlobalMemoryBlock, $MemoryPointer, $ResSize

	If $DLL = -1 Then
		$hInstance = _WinAPI_GetModuleHandle("")
	Else
		$hInstance = _WinAPI_LoadLibraryEx($DLL, $LOAD_LIBRARY_AS_DATAFILE)
	EndIf
	If $hInstance = 0 Then Return SetError(1, 0, 0)

	If $ResType = $RT_BITMAP Then
		$hBitmap = _WinAPI_LoadImage($hInstance, $ResName, $IMAGE_BITMAP, 0, 0, 0)
		If @error Then Return SetError(2, 0, 0)
		Return $hBitmap ; returns handle to Bitmap
	EndIf

	If $ResLang <> 0 Then
		$InfoBlock = DllCall("kernel32.dll", "ptr", "FindResourceExW", "ptr", $hInstance, "long", $ResType, "wstr", $ResName, "short", $ResLang)
	Else
		$InfoBlock = DllCall("kernel32.dll", "ptr", "FindResourceW", "ptr", $hInstance, "wstr", $ResName, "long", $ResType)
	EndIf

	If @error Then Return SetError(3, 0, 0)
	$InfoBlock = $InfoBlock[0]
	If $InfoBlock = 0 Then Return SetError(4, 0, 0)

	$ResSize = DllCall("kernel32.dll", "dword", "SizeofResource", "ptr", $hInstance, "ptr", $InfoBlock)
	If @error Then Return SetError(5, 0, 0)
	$ResSize = $ResSize[0]
	If $ResSize = 0 Then Return SetError(6, 0, 0)

	$GlobalMemoryBlock = DllCall("kernel32.dll", "ptr", "LoadResource", "ptr", $hInstance, "ptr", $InfoBlock)
	If @error Then Return SetError(7, 0, 0)
	$GlobalMemoryBlock = $GlobalMemoryBlock[0]
	If $GlobalMemoryBlock = 0 Then Return SetError(8, 0, 0)

	$MemoryPointer = DllCall("kernel32.dll", "ptr", "LockResource", "ptr", $GlobalMemoryBlock)
	If @error Then Return SetError(9, 0, 0)
	$MemoryPointer = $MemoryPointer[0]
	If $MemoryPointer = 0 Then Return SetError(10, 0, 0)

	If $DLL <> -1 Then _WinAPI_FreeLibrary($hInstance)
	If @error Then Return SetError(11, 0, 0)

	SetExtended($ResSize)
	Return $MemoryPointer
EndFunc   ;==>__GTVEX_ResourceGet

#comments-end


