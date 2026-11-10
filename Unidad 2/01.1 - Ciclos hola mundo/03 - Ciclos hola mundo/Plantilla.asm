INCLUDE Irvine32.inc
.data

mensaje BYTE "Hola mundo!", 0

.code
main PROC

mov ecx, 10 ; Inicializamos nuestro ECX (Contador) en 10 para imprimir 10 veces el mensaje
mov edx, offset mensaje ; No necesitamos indicarle 10 veces el offset de mensaje, con una vez basta

ciclo:
	call WriteString
	call Crlf
	loop ciclo

exit

main ENDP
END main