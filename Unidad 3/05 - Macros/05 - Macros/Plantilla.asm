; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales
; La primera parte de este archivo se realizo en clase y la segunda se realizo como tarea.

; Esta tarea trato sobre la creacion y uso de macros en lenguaje ensamblador. Un macro es como una funcion,
; pero una funcion es un pedazo de codigo que se manda a llamar (por lo que no se inyecta o expande codigo nuevo, solo
; se reutiliza el que ya existe, con distintos parametros o no, dependiendo nuestro fin) desde cualquier parte del 
; codigo en tiempo de ejecucion. Mientras que un macro es una secuencia de instrucciones que se inyecta en el codigo 
; fuente en tiempo de compilacion.

INCLUDE Irvine32.inc

MostrarMensaje MACRO msg ; Para definir un macro definimos su nombre y luego ponemos la palabra reservada MACRO, 
	mov edx, offset msg  ; seguido del o los parametros que va a recibir el macro.
	call WriteString	 ; Contenido del macro
	call Crlf
ENDM MostrarMesaje ; Agregue el nombre del macro que estaba terminando porque me estaba dando problemas de compilacion.

MostrarMultiplicacion MACRO a, b ; Este macro realiza y muestra una multiplicacion de 2 numeros con signo con IMUL.
	mov eax, a					 ; También podría hacerse con imul eax, pero necesitariamos usar otro registro.
	imul eax, b
	call WriteInt
	call Crlf
ENDM MostrarMultiplicacion

.data
; Definimos en la memoria RAM los mensajes que utilizara como parametros nuestro macro MostrarMensaje.
mensajeBienvenida BYTE "Bienvenido al sistema de inventario", 0
mensajeSalida BYTE "Hasta luego, gracias por usar nuestro sistema de inventario", 0

.code
main PROC
; Mandamos a llamar nuestros macros con los parametros que definimos en la seccion .data.
MostrarMensaje mensajeBienvenida
MostrarMensaje mensajeSalida

MostrarMultiplicacion 15, -2

exit

main ENDP
END main