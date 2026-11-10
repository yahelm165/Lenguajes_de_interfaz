INCLUDE Irvine32.inc
.data
.code
main PROC

mov ecx, 5
jecxz fin_ciclo ; Hara el salto a la etiqueta fin_ciclo cuando el registro ECX sea igual a 0

ciclo:
	mov eax, ecx ;
	call WriteDec ; Imprime el valor de EAX en consola
	call Crlf ; Carriage return
	loop ciclo ; loop cicla la etiqueta que le digamos con el valor de ECX, en este caso 5 y también se encarga de hacer el decremento de ECX

fin_ciclo: exit

main ENDP
END main