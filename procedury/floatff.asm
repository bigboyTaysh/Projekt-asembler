.386
.model flat, stdcall

SRC2_DIMM		EQU   2048
SRC1_REAL		EQU   2

FpuAtoFL    PROTO :DWORD,:DWORD,:DWORD
ReadFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

.data
	a REAL10 0.0
	spacja dd 32
	dataToRead DWORD 0
	dataRad DWORD 0
	nBufferLength DWORD 255
	buffer BYTE 255 dup(0)
	pom DWORD 0
	pom2 DWORD 0
	bufor BYTE 128 dup(0)

.code


clean MACRO bufor

	xor eax,eax ;Write Zero
	mov ecx,128 ;Size of the Array, in Bytes
	mov edi, offset bufor ;Location of Array start, in RAM
	cld
	rep stosb

endm

floatff PROC fileHandle:DWORD,dlugosc:DWORD
	push   EBX 
	push   ECX 
	push   EDX 
	push   ESI 
	push   EDI 
	
	mov pom2, BYTE PTR 0

	petla3:
	mov eax, dlugosc
	mov ebx, [eax]
	cmp ebx, 0
	je liczba
	dec ebx
	mov [eax], ebx

	INVOKE ReadFile, fileHandle, OFFSET dataToRead, 1, OFFSET dataRad, 0
	mov EAX, dataToRead
	mov EBX, spacja

	cmp EAX, EBX 
	je liczba

	mov EBX, offset bufor
	mov EDI, pom2
	mov EAX, dataToRead
	mov [EBX+EDI], EAX

	mov ebx, pom2
	add ebx, 1
	mov pom2, ebx

	loop petla3

	liczba:
	invoke FpuAtoFL, ADDR bufor, ADDR a, 0 ;ascii to float

	fld a

	clean bufor

	pop   EDI 
	pop   ESI 
	pop   EDX 
	pop   ECX 
	pop   EBX 

	ret
	
floatff endp
END