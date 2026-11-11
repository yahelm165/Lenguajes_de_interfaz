; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Programa basico sobre ciclos en ensamblador a traves de saltos y la subrutina loop.

INCLUDE Irvine32.inc
.data
.code
main PROC

mov ecx, 5
jecxz fin_ciclo ; Hara el salto a la etiqueta fin_ciclo cuando el registro ECX sea igual a 0.

ciclo:
	mov eax, ecx ; Se pasa el valor numerico de ECX a EAX porque WriteDec solo puede imprimir el valor de EAX.
	call WriteDec ; Imprime el valor de EAX en consola.
	call Crlf ; Carriage return.
	loop ciclo ; loop cicla la etiqueta que le digamos con el valor de ECX, en este caso 5 y también se encarga de hacer el decremento de ECX.

fin_ciclo: exit ; Cuando el registro ECX sea 0 hara el salto a esta etiqueta y terminara el programa.

main ENDP
END main