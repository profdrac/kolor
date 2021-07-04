.386
.model	flat, stdcall
option	casemap :none
;---------------------------------------------------------
include	    \masm32\include\windows.inc
include     \masm32\include\user32.inc
include     \masm32\include\kernel32.inc
include     \masm32\include\comctl32.inc
include     \masm32\include\masm32.inc
includelib	    \masm32\lib\comctl32.lib
includelib	    \masm32\lib\masm32.lib
includelib 	    \masm32\lib\user32.lib
includelib 	    \masm32\lib\kernel32.lib
includelib 	    \masm32\lib\comctl32.lib
;-------------------------------------------------------
DlgProc	PROTO	:DWORD, :DWORD, :DWORD, :DWORD
KeyProc	PROTO	:DWORD
;-------------------------------------------------------
.const
IDD_MAIN	equ		1000
IDB_EXIT    equ    	1001
IDC_NAME	equ 	405
IDC_SERIAL  equ		406
IDB_GEN    	equ 	404
IDB_ABT		equ		408
;-------------------------------------------------------
.data
szCaption	db		"Keygen", 0
szAbout		db		"pr0fdr4c - 28 May 2020", 10, 13
			db		"Keygen Template", 10, 13
			db		" ", 10, 13
			db		"Level - 0", 10, 13
			db		"Crypto - 0", 0
szError		db		"I need a name Captain", 0
szFormat	db		"%s-%d%d%d", 0
szName		db		20  dup(0)
szSerial	db		50  dup(0)
;-------------------------------------------------------
.data?
hInstance	dd		?
loTime		dd		10 	dup(?)
;-------------------------------------------------------
.code
start:
    invoke	GetModuleHandle, NULL
    mov		hInstance, eax
    invoke	InitCommonControls
    invoke  DialogBoxParam, hInstance, IDD_MAIN, 0, offset DlgProc, 0
    invoke  ExitProcess, eax
;---------------------------------------------------------
DlgProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov    eax, uMsg
    .if eax == WM_INITDIALOG
    	invoke    LoadIcon, hInstance, 2
        invoke    SendMessage, hWnd, WM_SETICON, 1, eax
        invoke	  SetWindowText, hWnd, addr szCaption
        invoke	  GetDlgItem, hWnd, IDC_NAME
        invoke	  SetFocus, eax
    .elseif eax == WM_COMMAND
        mov eax, wParam
        mov edx, eax
        shr edx, 16
        and eax, 0FFFFh
        .if eax == IDB_EXIT
            invoke  SendMessage, hWnd, WM_CLOSE, 0, 0
        .elseif eax == IDB_GEN
        	invoke	KeyProc, hWnd
        .elseif eax == IDB_ABT
        	invoke	MessageBox, hWnd, addr szAbout, addr szCaption, MB_OK
        .endif
    .elseif eax == WM_CLOSE
        invoke    EndDialog, hWnd, 0
    .endif
    xor    eax, eax
    ret  
DlgProc endp
;---------------------------------------------------------
KeyProc	proc hWnd:dword
	pushad
	invoke	GetDlgItemText, hWnd, IDC_NAME, addr szName, sizeof szName
    cmp eax, 1h
	jl	_bad
	invoke	GetLocalTime, addr loTime
	movzx	eax, word ptr [loTime+6]
	movzx	ebx, word ptr [loTime+2]
	movzx	ecx, word ptr [loTime]
	add		ecx, 4D2h
	invoke	wsprintf, addr szSerial, addr szFormat, addr szName, ecx, ebx, eax
	invoke  SetDlgItemText, hWnd, IDC_SERIAL, addr szSerial
	popad
	ret
	_bad:
	invoke  SetDlgItemText, hWnd, IDC_SERIAL, addr szError
	popad
	ret
KeyProc endp
;---------------------------------------------------------
end start