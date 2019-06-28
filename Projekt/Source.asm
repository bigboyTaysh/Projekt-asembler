.386
.MODEL FLAT, STDCALL

GENERIC_READ            EQU		80000000h
GENERIC_WRITE           EQU		40000000h
OPEN_EXISTING           EQU		3
CREATE_ALWAYS           EQU		2
FILE_BEGIN				EQU		0h
FILE_END				EQU		2h
SRC1_REAL				EQU		2
DEST_MEM				EQU		0
SRC2_DIMM				EQU		2048

include grafika.inc
includelib fpu.lib

SetDlgItemTextA		PROTO :DWORD,:DWORD, :DWORD
SetDlgItemInt		PROTO :DWORD,:DWORD, :DWORD, :DWORD
SendDlgItemMessageA	PROTO :DWORD,:DWORD, :DWORD, :DWORD, :DWORD

GetStdHandle PROTO :DWORD
CloseHandle PROTO :DWORD
CreateFileA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteFile PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GetCurrentDirectoryA PROTO :DWORD, :DWORD
SetFilePointer PROTO :DWORD,:DWORD,:DWORD,:DWORD

lstrcatA PROTO :DWORD, :DWORD
lstrlenA PROTO :DWORD
floatff PROTO :DWORD, :DWORD

FpuAtoFL    PROTO :DWORD,:DWORD,:DWORD
FpuFLtoA    PROTO :DWORD,:DWORD,:DWORD,:DWORD

ExitProcess			PROTO :DWORD

.DATA

	hinst	DWORD	0
	hicon	DWORD	0
	hcur 	DWORD	0
	hmenu	DWORD	0

	tdlg1	BYTE		"DLG1",0
	ALIGN 4
	tmenu	BYTE		"MENU1",0
	ALIGN 4
	tOK	      BYTE		"OK",0
	ALIGN 4
	terr 	BYTE		32 dup(0)	; bufor komunikatu
	tnagl	BYTE		32 dup(0)	; bufor nag³ówka
	buffor	BYTE		128 dup(0)
	buffor1	BYTE		32 dup(0)
	buffor2	BYTE		128 dup(0)
	buffor3 BYTE		32 dup(0)
	buffor4 BYTE		512 dup(0)
	formatka BYTE "%i",0
	nBufferLength DWORD 255
	ukosnik BYTE '\', 0
	spacja BYTE ' ', 0
	pom BYTE 0
	fileHandle DWORD 0
	dlugosc DWORD 0
	dataToWriteLen DWORD 0
	dataWritten DWORD 0

	a11 REAL10	0.0
	a12 REAL10	0.0
	a13 REAL10	0.0
	a21 REAL10	0.0
	a22 REAL10	0.0
	a23 REAL10	0.0
	a31 REAL10	0.0
	a32 REAL10	0.0
	a33 REAL10	0.0

	na11 BYTE 32 dup(0)
	na12 BYTE 32 dup(0)
	na13 BYTE 32 dup(0)
	na21 BYTE 32 dup(0)
	na22 BYTE 32 dup(0)
	na23 BYTE 32 dup(0)
	na31 BYTE 32 dup(0)
	na32 BYTE 32 dup(0)
	na33 BYTE 32 dup(0)

	wynik1 REAL10 0.0
	wynik2 REAL10 0.0
	wynik3 REAL10 0.0
	wynik4 REAL10 0.0
	wynik5 REAL10 0.0
	wynik6 REAL10 0.0
	wynik7 REAL10 0.0
	wynik8 REAL10 0.0
	wynik REAL10 0.0

.CODE
minus MACRO x
		mov ecx, offset x
		mov al, [ecx]
		mov pom, al

		.IF pom != 2dh
			inc ecx
		.ENDIF

		mov eax, ecx
endm

clean MACRO bufor
	xor eax,eax ;Write Zero
	mov ecx,128 ;Size of the Array, in Bytes
	mov edi, offset bufor ;Location of Array start, in RAM
	cld
	rep stosb
endm

clean2 MACRO x
	fldz
	fstp x
endm

zamien MACRO x, y
	push x
	push formatka
	push y
	call wsprintfA
	add esp, 12
endm

wczytaj MACRO x,y
	INVOKE SendDlgItemMessageA, windowHandle, x, WM_GETTEXT, 32, offset buffor2
	;-------konwresja bufora na typ REAL10 i zapis w zmiennnej x
    invoke FpuAtoFL, ADDR buffor2, ADDR y, DEST_MEM ;ascii to float
	cmp eax, 0
endm

dodaj MACRO x,y,z,w
	finit
    fld x
	fld y
	faddp st(1), st(0)

	fld z
	faddp st(1), st(0)

	fstp w
endm

pomnoz MACRO x,y,z,w
	finit
    fld x
	fld y
	fmulp st(1), st(0)

	fld z
	fmulp st(1), st(0)

	fstp w
endm

odejmij MACRO x,y,w
	finit
    fld x
	fld y
	fsubp st(1), st(0)

	fstp w
endm

wczytajzpliku MACRO fileHandle, dlugosc, x, y
	invoke floatff, fileHandle, offset dlugosc
	fstp x
	invoke FpuFLtoA, ADDR x, 2, ADDR buffor2, SRC1_REAL or SRC2_DIMM ;floa to ascii
	INVOKE SetDlgItemTextA, windowHandle, y, offset buffor2
endm

WndProc PROC uses EBX ESI EDI windowHandle:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

	.IF uMSG ==  WM_INITDIALOG
	INVOKE LoadIcon, hinst , 11
	mov hicon, EAX
	INVOKE SendMessageA , windowHandle , WM_SETICON , ICON_SMALL , hicon

	INVOKE LoadString, hinst, 4, OFFSET buffor, 32
	INVOKE SetDlgItemTextA, windowHandle, 21, offset buffor
	INVOKE LoadString, hinst, 5, OFFSET buffor, 128
	INVOKE SetDlgItemTextA, windowHandle, 22, offset buffor

		jmp	wmINITDIALOG
	.ENDIF

	.IF uMSG ==  WM_CLOSE
		jmp	wmCLOSE
	.ENDIF

	.IF uMSG ==  WM_COMMAND
		jmp	wmCOMMAND
	.ENDIF

	 mov	EAX, 0
	 jmp	konWNDPROC 

	wmINITDIALOG:
		INVOKE LoadMenu,hinst,OFFSET tmenu
		mov hmenu,EAX
		INVOKE SetMenu, windowHandle, hmenu 

		INVOKE LoadString, hinst,1,OFFSET buffor,32

		mov EAX, 1
		jmp	konWNDPROC 

	wmCLOSE:
		INVOKE DestroyMenu,hmenu
		INVOKE EndDialog, windowHandle, 0	
		 
		mov EAX, 1
		jmp	konWNDPROC

	wmCOMMAND:
		.IF wParam == 101
			jmp	wmCLOSE
		.ENDIF

		.IF wParam == 104
			jmp	wyczysc
		.ENDIF

		.IF wParam == 105
			jmp	obliczenia
		.ENDIF

		.IF wParam == 106
			jmp wczytywanieAdresu
		.ENDIF
		
		.IF wParam == 107
			jmp zapis
		.ENDIF

	konWNDPROC:	
		ret

	wyczysc:
		INVOKE SetDlgItemTextA, windowHandle, 1, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 2, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 3, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 4, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 5, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 6, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 7, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 8, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 9, offset buffor1
		INVOKE SetDlgItemTextA, windowHandle, 10, offset buffor1

		clean buffor
		clean buffor2 

		clean2 a11
		clean2 a13
		clean2 a21
		clean2 a22
		clean2 a23
		clean2 a31
		clean2 a32
		clean2 a33
		clean2 wynik1
		clean2 wynik2
		clean2 wynik3
		clean2 wynik4
		clean2 wynik5
		clean2 wynik6
		clean2 wynik7
		clean2 wynik8
		clean2 wynik

	jmp	konWNDPROC

	wczytywanieAdresu:
		clean buffor2

		INVOKE SendDlgItemMessageA, windowHandle, 11, WM_GETTEXT, 128, offset buffor2
		
		INVOKE GetCurrentDirectoryA, nBufferLength, OFFSET buffor
		INVOKE lstrcatA, OFFSET buffor, OFFSET ukosnik
		INVOKE lstrcatA, OFFSET buffor, OFFSET buffor2
		INVOKE CreateFileA, OFFSET buffor, GENERIC_READ OR GENERIC_WRITE, 0, 0, OPEN_EXISTING, 0, 0
		mov fileHandle, eax
		cmp eax, 0FFFFFFFFh
		jne wczytywanieLiczb
		jmp err

	zapis:
		mov dataToWriteLen, BYTE PTR 0
		clean buffor4
		clean buffor2
		clean na11
		clean na12
		clean na13
		clean na21
		clean na22
		clean na23
		clean na31
		clean na32
		clean na33

		clean2 a11
		clean2 a13
		clean2 a21
		clean2 a22
		clean2 a23
		clean2 a31
		clean2 a32
		clean2 a33
		
		wczytaj 1,a11
		wczytaj 2,a12
		wczytaj 3,a13
		wczytaj 4,a21
		wczytaj 5,a22
		wczytaj 6,a23
		wczytaj 7,a31
		wczytaj 8,a32
		wczytaj 9,a33


		invoke FpuFLtoA, ADDR a11, 2, ADDR na11, SRC1_REAL or SRC2_DIMM ;floa to ascii
		invoke FpuFLtoA, ADDR a12, 2, ADDR na12, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a13, 2, ADDR na13, SRC1_REAL or SRC2_DIMM
		invoke FpuFLtoA, ADDR a21, 2, ADDR na21, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a21, 2, ADDR na21, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a22, 2, ADDR na22, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a23, 2, ADDR na23, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a31, 2, ADDR na31, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a32, 2, ADDR na32, SRC1_REAL or SRC2_DIMM 
		invoke FpuFLtoA, ADDR a33, 2, ADDR na33, SRC1_REAL or SRC2_DIMM 


		INVOKE SendDlgItemMessageA, windowHandle, 11, WM_GETTEXT, 128, offset buffor2
		
		INVOKE GetCurrentDirectoryA, nBufferLength, OFFSET buffor
		INVOKE lstrcatA, OFFSET buffor, OFFSET ukosnik
		INVOKE lstrcatA, OFFSET buffor, OFFSET buffor2
		INVOKE CreateFileA, OFFSET buffor, GENERIC_READ OR GENERIC_WRITE, 0, 0, OPEN_EXISTING, 0, 0
		mov fileHandle, eax
		cmp eax, 0FFFFFFFFh
		je nowy
		jmp stary

	nowy: 
		INVOKE CreateFileA, OFFSET buffor, GENERIC_READ OR GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0

	stary:
		mov fileHandle, eax

		minus na11
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na12
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na13
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na21
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na22
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na23
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na31
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na32
		INVOKE lstrcatA, OFFSET buffor4, eax
		INVOKE lstrcatA, OFFSET buffor4, OFFSET spacja

		minus na33
		INVOKE lstrcatA, OFFSET buffor4, eax

		invoke lstrlenA, OFFSET buffor4
		mov dataToWriteLen, eax

		INVOKE WriteFile, fileHandle, OFFSET buffor4, dataToWriteLen, OFFSET dataWritten, 0

		INVOKE CloseHandle, fileHandle 
		jmp	konWNDPROC


	wczytywanieLiczb:
		clean buffor
		clean buffor2 

		clean2 a11
		clean2 a13
		clean2 a21
		clean2 a22
		clean2 a23
		clean2 a31
		clean2 a32
		clean2 a33
		clean2 wynik1
		clean2 wynik2
		clean2 wynik3
		clean2 wynik4
		clean2 wynik5
		clean2 wynik6
		clean2 wynik7
		clean2 wynik8
		clean2 wynik

		INVOKE SetFilePointer, fileHandle, 0, 0, FILE_END
		mov dlugosc, eax
		INVOKE SetFilePointer, fileHandle, 0, 0, FILE_BEGIN

		wczytajzpliku fileHandle, dlugosc, a11, 1
		wczytajzpliku fileHandle, dlugosc, a12, 2
		wczytajzpliku fileHandle, dlugosc, a13, 3
		wczytajzpliku fileHandle, dlugosc, a21, 4
		wczytajzpliku fileHandle, dlugosc, a22, 5
		wczytajzpliku fileHandle, dlugosc, a23, 6
		wczytajzpliku fileHandle, dlugosc, a31, 7
		wczytajzpliku fileHandle, dlugosc, a32, 8
		wczytajzpliku fileHandle, dlugosc, a33, 9

		INVOKE CloseHandle, fileHandle 
		
	jmp	konWNDPROC

	obliczenia:
		wczytaj 1,a11
		wczytaj 2,a12
		wczytaj 3,a13
		wczytaj 4,a21
		wczytaj 5,a22
		wczytaj 6,a23
		wczytaj 7,a31
		wczytaj 8,a32
		wczytaj 9,a33

		pomnoz a11,a22,a33,wynik1
		pomnoz a12,a23,a31,wynik2
		pomnoz a13,a21,a32,wynik3
		pomnoz a13,a22,a31,wynik4
		pomnoz a11,a23,a32,wynik5
		pomnoz a12,a21,a33,wynik6

		dodaj wynik1,wynik2,wynik3,wynik7
		dodaj wynik4,wynik5,wynik6,wynik8

		odejmij wynik7,wynik8,wynik

		invoke FpuFLtoA, ADDR wynik, 2, ADDR buffor2, SRC1_REAL or SRC2_DIMM ;floa to ascii

		INVOKE SetDlgItemTextA, windowHandle, 10, offset buffor2
		

	jmp	konWNDPROC

	err:
		INVOKE LoadString, hinst,3,OFFSET terr,32
		INVOKE MessageBoxA,0,OFFSET terr,OFFSET tnagl,0
	jmp	konWNDPROC

WndProc	ENDP


main PROC

	INVOKE GetModuleHandleA, 0
	mov	hinst, EAX
	
	INVOKE DialogBoxParamA, hinst,OFFSET tdlg1, 0, OFFSET WndProc, 0
	;tworzenie okna dialogowego

	.IF EAX == 0
			jmp	etkon
	.ENDIF

	.IF EAX == -1
		jmp	err0
	.ENDIF	

	err0:
		INVOKE LoadString, hinst,2,OFFSET terr,32
		INVOKE MessageBoxA,0,OFFSET terr,OFFSET tnagl,0

	etkon:

	INVOKE ExitProcess, 0

main ENDP

END