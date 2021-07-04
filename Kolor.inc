KOLOR	struct
	tbackground	dword	?
	tfont		dword	?
	background	dword	?
	border		dword	?
	ebackground	dword	?
	efont		dword	?
KOLOR ends

InitProc	PROTO	:KOLOR
RegionProc	PROTO	:HWND
PaintProc	PROTO	:HWND, :DWORD
DrawProc	PROTO	:HWND, :LPARAM, :DWORD
StaticProc	PROTO	:HWND, :WPARAM, :DWORD
EditProc	PROTO	:WPARAM
OutitProc	PROTO