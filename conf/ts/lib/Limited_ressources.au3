#include-once

#include <WinAPIRes.au3>


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