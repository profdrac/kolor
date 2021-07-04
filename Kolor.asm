.386
.model	flat, stdcall
option	casemap :none

;----------------------------------------------------------------------------------------
include		\masm32\include\windows.inc
include		\masm32\include\user32.inc
include		\masm32\include\gdi32.inc
includelib	\masm32\lib\user32.lib
includelib	\masm32\lib\gdi32.lib
;----------------------------------------------------------------------------------------

.data
KOLOR	struct
	tbackground	dd	0
	tfont		dd	0
	background	dd	0
	border		dd	0
	ebackground	dd	0
	efont		dd	0
KOLOR ends
szBtnText		db		16 DUP(0)
col				KOLOR	<0, 0, 0, 0, 0, 0>
;----------------------------------------------------------------------------------------

.data?
hCol_TBG	dd		?
hCol_BG		dd		?
hCol_BO		dd		?
hCol_EBG	dd		?
hPen		dd		?
hR1			dd		?
hR2			dd		?
BoldFont   	LOGFONT	<?>
;----------------------------------------------------------------------------------------

.code
;----------------------------------------------------------------------------------------
;Initialises colors and makes brushes and pens
;Parameters: 1. KOLOR struct
InitProc proc	clr:KOLOR
	mov		eax, clr.tbackground
	mov		col.tbackground, eax
	mov		eax, clr.tfont
	mov		col.tfont, eax
	mov		eax, clr.background
	mov		col.background, eax
	mov		eax, clr.border
	mov		col.border, eax
	mov		eax, clr.ebackground
	mov		col.ebackground, eax
	mov		eax, clr.efont
	mov		col.efont, eax
	invoke	CreateSolidBrush, col.tbackground
	mov		hCol_TBG, eax
	invoke	CreateSolidBrush, col.background
	mov		hCol_BG, eax
	invoke	CreateSolidBrush, col.border
	mov		hCol_BO, eax
	invoke	CreateSolidBrush, col.ebackground
	mov		hCol_EBG, eax
	invoke	CreatePen, PS_SOLID, 1, col.border
	mov		hPen, eax
	ret
InitProc endp

;----------------------------------------------------------------------------------------
;Creates region for the title-bar
;Parameters: Handle to window
RegionProc proc hWnd:HWND
	local r:RECT
	
	invoke	GetClientRect, hWnd, addr r
	invoke	CreateRectRgn, r.left, r.top, r.right, 26
	mov		hR1, eax
	invoke	CreateRectRgn, r.left, 28, r.right, r.bottom
	mov		hR2, eax
	invoke	CombineRgn, hR1, hR1, hR2, RGN_OR
	invoke	SetWindowRgn, hWnd, hR1, TRUE
	ret
RegionProc endp

;----------------------------------------------------------------------------------------
;Paints the window rectangle with colors and border
;Parameters:1. Handle to window 
;			2.Window-type: 0-With Titlebar, 1-Without titlebar
PaintProc proc hWnd:HWND, wType:DWORD
	local ps:PAINTSTRUCT
	local p:dword
	local op:dword
	local tb:dword
	local b:DWORD
	local ob:DWORD
	local r:RECT
	
	invoke	BeginPaint, hWnd, addr ps
	invoke	GetClientRect, hWnd, addr r
	invoke	CreatePen, PS_SOLID, 1, col.border
	mov		p, eax
	invoke	SelectObject, ps.hdc, p
	mov		op, eax
	.if wType == 0
		invoke	CreateSolidBrush, col.tbackground
		mov		tb, eax
		invoke	SelectObject, ps.hdc, tb
		mov		ob, eax
		invoke	Rectangle, ps.hdc, r.left, r.top, r.right, 26
	.endif
	invoke	CreateSolidBrush, col.background
	mov		b, eax
	invoke	SelectObject, ps.hdc, b
	mov		ob, eax
	.if wType == 0
		invoke	Rectangle, ps.hdc, r.left, 28, r.right, r.bottom
	.else
		invoke	Rectangle, ps.hdc, r.left, r.top, r.right, r.bottom
	.endif
	invoke	SelectObject, ps.hdc, ob
	invoke	SelectObject, ps.hdc, op
	invoke	DeleteObject, tb
	invoke	DeleteObject, b
	invoke	DeleteObject, p
	invoke	EndPaint, hWnd, addr ps
	ret
PaintProc endp

;----------------------------------------------------------------------------------------
;Draws and paints button
;Parameters: 1. Handle wo window 
;			 2. lParam of WM_DRAWITEM
;			 3. Type of button: 0-Button on titlebar, 1-other button
DrawProc proc hWnd:HWND, lParam:LPARAM, tit:DWORD
	push esi
  	mov esi, lParam
  	assume esi: ptr DRAWITEMSTRUCT
  	.if [esi].itemState & ODS_SELECTED
    	invoke	SelectObject, [esi].hdc, hCol_BG
  	.else
    	invoke	SelectObject, [esi].hdc, hCol_BO
  	.endif
  	invoke	SelectObject, [esi].hdc, hPen
  	invoke	SelectObject, [esi].hdc, hCol_BG
  	.if tit == 0
  	invoke	FillRect, [esi].hdc, addr [esi].rcItem, hCol_TBG
  	.else
  	invoke	FillRect, [esi].hdc, addr [esi].rcItem, hCol_BG
  	.endif
  	invoke 	RoundRect, [esi].hdc, [esi].rcItem.left, [esi].rcItem.top, [esi].rcItem.right, [esi].rcItem.bottom, 6, 6
  	.if [esi].itemState & ODS_SELECTED
    	invoke	OffsetRect, addr [esi].rcItem, 1, 1
  	.endif
  	invoke	GetDlgItemText, hWnd, [esi].CtlID, addr szBtnText, sizeof szBtnText
  	invoke  SetBkMode, [esi].hdc, TRANSPARENT
  	invoke  SetTextColor, [esi].hdc, col.border
  	invoke  DrawText, [esi].hdc, addr szBtnText, -1, addr [esi].rcItem, DT_CENTER or DT_VCENTER or DT_SINGLELINE
  	.if [esi].itemState & ODS_SELECTED
    	invoke	OffsetRect, addr [esi].rcItem, -1, -1
  	.endif
  	.if [esi].itemState & ODS_FOCUS
    	invoke	InflateRect, addr [esi].rcItem, -3, -3
  	.endif
	assume esi:nothing
  	pop esi
	ret
DrawProc endp

;----------------------------------------------------------------------------------------
;Paints static or read-only edit-box
;Parameters: 1. Handle to window 
;			 2. wParam of WM_CTLCOLORSTATIC
;			 3. Type: 0-Title, 1-Editbox, 2-Static on window
StaticProc proc	hWnd:HWND, wParam:WPARAM, sType:DWORD
	.if sType == 0
		invoke	SendMessage, hWnd, WM_GETFONT, 0, 0
      	invoke 	GetObject, eax, sizeof LOGFONT, addr BoldFont
      	mov 	BoldFont.lfWeight, FW_BOLD
      	invoke 	CreateFontIndirect, addr BoldFont
      	invoke	SelectObject, wParam, eax
      	invoke	SetBkMode, wParam, TRANSPARENT
      	invoke	SetTextColor, wParam, col.tfont
      	mov		eax, hCol_TBG
	.elseif sType == 1
      	invoke	SetBkMode, wParam, TRANSPARENT
      	invoke	SetTextColor, wParam, col.efont
      	mov		eax, hCol_EBG
	.elseif sType == 2
    	invoke	SetBkMode, wParam, TRANSPARENT
     	invoke	SetTextColor, wParam, col.border
     	mov		eax, hCol_BG
     .else
	.endif
	ret
StaticProc endp

;----------------------------------------------------------------------------------------
;Sets colors of edit-box
;Parameters: 1. wParam of WM_CTLCOLOREDIT
EditProc proc wParam:WPARAM
	invoke	SetBkMode, wParam, TRANSPARENT
    invoke	SetTextColor, wParam, col.efont
    mov 	eax, hCol_EBG
	ret
EditProc endp

;----------------------------------------------------------------------------------------
;Deletes color-brushes and pens and releases memory
;Parameters: None
OutitProc proc
	invoke	DeleteObject, hCol_TBG
	invoke	DeleteObject, hCol_BG
	invoke	DeleteObject, hCol_BO
	invoke	DeleteObject, hCol_EBG
	invoke	DeleteObject, hPen
	invoke	DeleteObject, addr hR1
	invoke	DeleteObject, addr hR2
	ret
OutitProc endp
;---------------------------------------------------------------------------------------
end