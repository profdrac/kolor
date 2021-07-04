.386
.model	flat, stdcall
option	casemap :none
;----------------------------------------------------------------------------------------
include		\masm32\include\windows.inc
include		\masm32\include\user32.inc
include		\masm32\include\kernel32.inc
include		\masm32\include\gdi32.inc
include		\masm32\include\Kolor.inc
includelib	\masm32\lib\user32.lib
includelib	\masm32\lib\kernel32.lib
includelib	\masm32\lib\gdi32.lib
includelib	\masm32\lib\Kolor.lib
;----------------------------------------------------------------------------------------
DlgProc		PROTO	:HWND, :UINT, :WPARAM, :LPARAM
InfoProc   	PROTO 	:HWND, :UINT, :WPARAM, :LPARAM
PatchProc	PROTO	:HWND
;----------------------------------------------------------------------------------------
.const
IDD_MAIN 			equ		1000
IDC_MAIN_STITLE 	equ		1001
IDC_MAIN_SPATCH		equ		1003
IDC_MAIN_BABOUT 	equ		1006
IDC_MAIN_BCLOSE 	equ		1007
IDC_MAIN_PATCH 		equ		1008
IDC_MAIN_ITITLE 	equ		1009
IDD_ABOUT 			equ		2000
IDC_ABOUT_SINFO 	equ		2004
IDC_ABOUT_BCLOSE 	equ		2005
;----------------------------------------------------------------------------------------
.data
col			KOLOR	<2072C4h, 0FFFFFFh, 8EB843h, 000000h, 38C1FFh, 000000h>
szTitle		db		"Patch Template", 0
sSerial		db		"Target:", 0
szInfo		db		10, "Kolor Patch Template", 10
			db		"by Prof. DrAcULA", 10
			db		"Released on: 01 June, 2020", 10, 10
			db		"Theme - Milking", 10, 10
			db		"Enjoy!", 0
;--Patch-data-----------------+
pFile		db		"patchme.txt", 0
BackupExt	db		".bak", 0
OldSize		dd		26
NewSize 	dd 		4
rOffset 	dd 		0, 1, 2, 3
NewBytes 	db 		44h, 65h, 61h, 6Eh
;--messages-------------------+
OpenError	db 		"Can't open file. Am I in the target's folder?", 0
ValError 	db 		"Wrong file size. Already patched?", 0
Success 	db 		"Target has been patched successfully!", 0
;----------------------------------------------------------------------------------------
.data?
hInstance	dd		?
TargetFile db MAX_PATH dup(?)
BackupFile 	db MAX_PATH dup(?)
hFile 		HANDLE ?
nBytesWritten dd ?
;----------------------------------------------------------------------------------------
.code
start:
	invoke	GetModuleHandle, NULL
	mov		hInstance, eax
	invoke	DialogBoxParam, hInstance, IDD_MAIN, 0, offset DlgProc, 0
	invoke	ExitProcess, 0
DlgProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	mov	eax, uMsg
	.if	eax == WM_INITDIALOG
		invoke	InitProc, col
		invoke	LoadIcon, hInstance, 200
		invoke	SendMessage, hWnd, WM_SETICON, 1, eax
		invoke	SetWindowText, hWnd, addr szTitle
		invoke	SetDlgItemText, hWnd, IDC_MAIN_STITLE, addr szTitle
		invoke	SetDlgItemText, hWnd, IDC_MAIN_SPATCH, addr pFile
		invoke	RegionProc, hWnd
	.elseif eax == WM_PAINT
		invoke	PaintProc, hWnd, 0
	.elseif eax == WM_CTLCOLORSTATIC
		invoke	GetDlgCtrlID, lParam
		.if eax == IDC_MAIN_STITLE
			invoke	StaticProc, hWnd, wParam, 0
		.else
			invoke	StaticProc, hWnd, wParam, 1
		.endif
    	ret
    .elseif eax == WM_DRAWITEM
    	.if wParam == IDC_MAIN_BABOUT||wParam == IDC_MAIN_BCLOSE
    		invoke	DrawProc, hWnd, lParam, 0
    	.else
    		invoke	DrawProc, hWnd, lParam, 1
    	.endif
	.elseif eax == WM_LBUTTONDOWN
		invoke	SendMessage, hWnd, WM_NCLBUTTONDOWN, 2, 0
	.elseif eax == WM_COMMAND
		mov	eax, wParam
    	mov edx, wParam
    	shr edx, 16
    	.if wParam == IDC_MAIN_PATCH
    		invoke	PatchProc, hWnd
    	.elseif wParam == IDC_MAIN_BABOUT
    		INVOKE DialogBoxParam, hInstance, IDD_ABOUT, hWnd, ADDR InfoProc, 0
    	.elseif wParam == IDC_MAIN_BCLOSE
    		invoke	OutitProc
    		invoke	EndDialog, hWnd, 0
    	.endif
	.elseif	eax == WM_CLOSE
		invoke	OutitProc
		invoke	EndDialog, hWnd, 0
	.endif
	xor	eax, eax
	ret
DlgProc endp
;----------------------------------------------------------------------------------------
InfoProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.if uMsg == WM_CTLCOLORSTATIC
		invoke	StaticProc, hWnd, wParam, 1
    	ret
	.elseif uMsg == WM_DRAWITEM
    	invoke	DrawProc, hWnd, lParam, 1
   	.elseif uMsg == WM_PAINT
    	invoke	PaintProc, hWnd, 1
  	.elseif uMsg == WM_INITDIALOG
  		invoke	SetWindowText, hWnd, addr szTitle
		invoke	SetDlgItemText, hWnd, IDC_ABOUT_SINFO, addr szInfo
    .elseif uMsg == WM_LBUTTONDOWN
		invoke	SendMessage, hWnd, WM_NCLBUTTONDOWN, 2, 0
  	.elseif uMsg == WM_COMMAND
    	.if wParam == IDC_ABOUT_BCLOSE
      		invoke	SendMessage, hWnd, WM_CLOSE, 0, 0
    	.endif
  	.elseif uMsg == WM_CLOSE
    	invoke EndDialog, hWnd, 0
  	.endif
  	xor eax, eax
  	ret
InfoProc ENDP
;----------------------------------------------------------------------------------------
PatchProc	proc hWnd:HWND
	pushad
	invoke GetDlgItemText, hWnd, IDC_MAIN_SPATCH, ADDR TargetFile, SIZEOF TargetFile
    invoke CreateFile, ADDR TargetFile, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax!=INVALID_HANDLE_VALUE
		mov hFile, eax
	    invoke GetFileSize, hFile, NULL
		.if eax == OldSize
			invoke lstrcpy, ADDR BackupFile, ADDR TargetFile
			invoke lstrcat, ADDR BackupFile, ADDR BackupExt
			invoke CopyFile, ADDR TargetFile, ADDR BackupFile, FALSE
	        xor ecx, ecx
	        mov eax, OFFSET rOffset
	        mov edx, OFFSET NewBytes
	        patch:
	        	pushad
	        	pushad
	        	push FILE_BEGIN
	        	push NULL
	        	push [eax+ecx*4]
	        	push hFile
	        	call SetFilePointer
	        	popad
	        	push NULL
	        	push offset nBytesWritten
	        	push 1
	        	add edx, ecx
	        	push edx
	        	push hFile
	        	call WriteFile
	        	popad
	        	inc ecx
	        	cmp ecx, SIZEOF NewBytes
	        	je endpatch
	        	jmp patch
	        endpatch:
	        	push FILE_BEGIN
	        	push NULL
	        	push NewSize
	        	push hFile
	        	call SetFilePointer
	        	push hFile
	        	call SetEndOfFile
	        	invoke	SetDlgItemText, hWnd, IDC_MAIN_SPATCH, addr Success
		.else
			invoke	SetDlgItemText, hWnd, IDC_MAIN_SPATCH, addr ValError
		.endif
      	invoke CloseHandle, hFile
    .else
    	invoke	SetDlgItemText, hWnd, IDC_MAIN_SPATCH, addr OpenError
    .endif
	popad
	ret
PatchProc endp
;---------------------------------------------------------------------------------------
end start