; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Este programa demuestra la captura y salida de cadenas de texto por consola interactuando con las rutinas
; de la biblioteca Irvine32, asi como el manejo del valor de retorno generado por una lectura de teclado.

INCLUDE Irvine32.inc

.data
mensajeEntrada byte "Escribe tu nombre: ", 0
caracteresEscritos byte "Cantidad de caracteres: ", 0
nombre byte 20 dup(0) ; DUP de duplicate, para que llene los 20 bytes con 0s. 
					  ; Porque es una variable que tendrá valor en tiempo de ejecución.

.code
main PROC

mov edx, offset mensajeEntrada ; Movemos el offset de mensajeEntrada a EDX porque es el registro que usa WriteString
call WriteString			   ; para imprimir mensajes por consola.

mov edx, offset nombre ; Le indicamos a ReadString el offset de la memoria en la que tiene que guardar los caracteres.
mov ecx, sizeof nombre ; Le indicamos a ReadString el tamaño máximo que puede tener la cadena de caracteres.

call ReadString        ; Espera la entrada del usuario por consola. Al presionar Enter, almacena el texto en el buffer 'nombre',
                       ; anade un byte 0 al final y retorna en EAX la cantidad de caracteres ingresados (sin contar el 0).

					   ; Mostramos en pantalla el texto que el usuario acaba de escribir para verificar la lectura
mov edx, offset nombre ; Cargamos nuevamente en EDX la direccion del buffer con el texto ya capturado
call WriteString       ; Imprime la cadena almacenada en 'nombre'
call Crlf              ; Salto de linea

; Mostramos la etiqueta informativa de la longitud
mov edx, offset caracteresEscritos ; Cargamos el mensaje que describe la cantidad de caracteres
call WriteString                   ; Imprime "Cantidad de caracteres: "

; Imprimimos el conteo devuelto por ReadString
; NOTA: No modificamos EAX previamente, por lo que todavia conserva el valor de retorno devuelto por ReadString.
call WriteDec          ; Imprime en formato decimal sin signo el numero contenido en EAX
call Crlf

exit

main ENDP
END main