INCLUDE Irvine32.inc
option casemap:none

.data

.code
Sumar PROC PUBLIC primero:SDWORD, segundo:SDWORD ; SDWORD = Signed DWORD para indicarle a C que es un numero con signo.
	mov eax, primero
	add eax, segundo

	ret

Sumar ENDP
END