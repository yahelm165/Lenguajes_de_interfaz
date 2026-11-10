INCLUDE Irvine32.inc
.data

msgIguales BYTE "Son iguales", 0
msgDiferentes BYTE "Son diferentes", 0

.code
main PROC

mov eax, 10
mov ebx, 10
cmp eax, ebx ; ZF se va a activar = 1
je iguales
mov edx, offset msgDiferentes
call WriteString
jmp fin

iguales:
	mov edx, offset msgIguales
	call WriteString

fin:
	call Crlf
	exit

main ENDP
END main