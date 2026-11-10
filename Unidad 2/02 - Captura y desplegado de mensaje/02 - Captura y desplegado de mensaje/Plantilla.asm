INCLUDE Irvine32.inc

.data
mensajeEntrada byte "Escribe tu nombre: ", 0
caracteresEscritos byte "Cantidad de caracteres: ", 0
nombre byte 20 dup(0) ; DUP de duplicate, para que llene los 20 bytes con 0s Porque es una variable que tendrá valor en tiempo de ejecución.

.code
main PROC

mov edx, offset mensajeEntrada ; Movemos el offset de mensajeEntrada a EDX porque es el registro que usa WriteString para imprimir mensajes por consola
call WriteString

mov edx, offset nombre ; Le indicamos a ReadString el offset de la memoria en la que tiene que guardar los caracteres
mov ecx, sizeof nombre ; Le indicamos a ReadString el tamaño máximo que puede tener la cadena de caracteres

call ReadString
mov edx, offset nombre 
call WriteString
call Crlf

mov edx, offset caracteresEscritos
call WriteString
call WriteDec
call Crlf

exit

main ENDP
END main