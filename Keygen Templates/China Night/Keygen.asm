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
KeyProc		PROTO	:HWND
;----------------------------------------------------------------------------------------
.const
IDD_MAIN 			equ		1000
IDC_MAIN_STITLE 	equ		1001
IDC_MAIN_SNAME 		equ		1002
IDC_MAIN_SSERIAL	equ		1003
IDC_MAIN_ENAME 		equ		1004
IDC_MAIN_ESERIAL 	equ		1005
IDC_MAIN_BABOUT 	equ		1006
IDC_MAIN_BCLOSE 	equ		1007
IDC_MAIN_BGEN 		equ		1008
IDC_MAIN_ITITLE 	equ		1009
IDD_ABOUT 			equ		2000
IDC_ABOUT_STITLE 	equ		2003
IDC_ABOUT_SINFO 	equ		2004
IDC_ABOUT_BCLOSE 	equ		2005
;----------------------------------------------------------------------------------------
.data
col			KOLOR	<291F2Fh, 0C4A6C3h, 010101h, 0C4A6C3h, 291F2Fh, 9CDAEEh>
szTitle		db		"Kolor Keygen Template", 0
sName		db		"NAME:", 0
sSerial		db		"SERIAL:", 0
szInfo		db		10, "Kolor Keygen Template", 10
			db		"by Prof. DrAcULA", 10
			db		"Released on: 01 June, 2020", 10, 10
			db		"Theme- China Night", 10, 10
			db		"Enjoy!", 0
;---------------------------------------------+
szError		db		"I need a name Captain", 0
szFormat	db		"%s-%d%d%d", 0
szName		db		20  dup(0)
szSerial	db		50  dup(0)
;----------------------------------------------------------------------------------------
.data?
hInstance	dd		?
loTime		dd		10 	dup(?)
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
		invoke	SetDlgItemText, hWnd, IDC_MAIN_SNAME, addr sName
		invoke	SetDlgItemText, hWnd, IDC_MAIN_SSERIAL, addr sSerial
	.elseif eax == WM_PAINT
		invoke	PaintProc, hWnd, 1
	.elseif eax == WM_CTLCOLORSTATIC
		invoke	GetDlgCtrlID, lParam
		.if eax == IDC_MAIN_ESERIAL
			invoke	StaticProc, hWnd, wParam, 1
		.elseif eax == IDC_MAIN_SNAME||eax == IDC_MAIN_SSERIAL
			invoke	StaticProc, hWnd, wParam, 2
		.endif
    	ret
    .elseif eax == WM_CTLCOLOREDIT
    	invoke	EditProc, wParam
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
    	.if wParam == IDC_MAIN_BGEN
    		invoke	KeyProc, hWnd
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
KeyProc	proc hWnd:HWND
	pushad
	invoke	GetDlgItemText, hWnd, IDC_MAIN_ENAME, addr szName, sizeof szName
    cmp eax, 1h
	jl	_bad
	invoke	GetLocalTime, addr loTime
	movzx	eax, word ptr [loTime+6]
	movzx	ebx, word ptr [loTime+2]
	movzx	ecx, word ptr [loTime]
	add		ecx, 4D2h
	invoke	wsprintf, addr szSerial, addr szFormat, addr szName, ecx, ebx, eax
	invoke  SetDlgItemText, hWnd, IDC_MAIN_ESERIAL, addr szSerial
	popad
	ret
	_bad:
	invoke  SetDlgItemText, hWnd, IDC_MAIN_ESERIAL, addr szError
	popad
	ret
KeyProc endp
;---------------------------------------------------------------------------------------
end start