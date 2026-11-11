; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Demostracion de estructuras condicionales (tipo if-else) usando la instruccion CMP
; y el salto condicional JE (Jump if Equal), el cual salta si la bandera Zero Flag (ZF) es 1.

INCLUDE Irvine32.inc

.data
msgIguales    BYTE "Son iguales", 0
msgDiferentes BYTE "Son diferentes", 0

.code
main PROC

mov eax, 10
mov ebx, 10
cmp eax, ebx                 ; Resta 10 - 10 = 0 -> ZF se activa en 1
je iguales                   ; Si ZF = 1 (son iguales), salta a la etiqueta 'iguales'

; Bloque 'else': se ejecuta si no fueron iguales
mov edx, offset msgDiferentes
call WriteString
jmp fin                      ; Salto incondicional para evitar entrar al bloque 'iguales'

iguales:
	; Bloque 'if': se ejecuta cuando la comparacion dio igualdad
	mov edx, offset msgIguales
	call WriteString

fin:
	call Crlf
	exit

main ENDP
END main