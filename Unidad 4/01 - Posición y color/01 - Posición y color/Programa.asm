; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales
; Primera practica de la unidad 4. Aprendemos a cambiar la posición del cursor y el color de la consola por medio de 
; las rutinas Gotoxy y SetColorText de Irvine32.

INCLUDE Irvine32.inc

.data
aviso BYTE "Presione una tecla para continuar", 0
msgInicio BYTE "ABCD", 0
reemplazo BYTE "XY", 0

.code
main PROC
	
; Color a la consola
mov eax, yellow + (0001b*16) ; Podemos usar las palabras reservadas que nos da Irvine32 o darle el valor en binario o hexadecimal.
call setTextColor
call Clrscr

mov edx, offset aviso
call WriteString
call readChar

mov dl, 20  ; Registro DL para indicar la columna de inicio.
mov dh, 10  ; Registro DH para indicar la fila de inicio.
call Gotoxy

mov edx, offset msgInicio
call WriteString
call Crlf

mov dl, 21
mov dh, 10
call Gotoxy
call readChar

mov eax, red + (black*16) ; Color del valor a reemplazar.
call setTextColor

mov edx, offset reemplazo
call WriteString
call Crlf

mov eax, yellow + (blue*16) ; Reinicio del color de la consola al original, porque el segundo color sustituye
call setTextColor			; el de todos los que sigan.

exit

main ENDP
END main