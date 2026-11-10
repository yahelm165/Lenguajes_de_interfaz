INCLUDE Irvine32.inc

MostrarMensaje MACRO msg
	mov edx, offset msg
	call WriteString
	call Crlf
ENDM MostrarMesaje

MostrarMultiplicacion MACRO a, b
	mov eax, a
	mov ebx, b
	imul ebx
	call WriteInt
	call Crlf
ENDM MostrarMultiplicacion

;Hacer otro macro de una multiplicación y mostrarla, supongo

.data

mensajeBienvenida BYTE "Bienvenido al sistema de inventario", 0
mensajeSalida BYTE "Hasta luego, gracias por usar nuestro sistema de inventario", 0

.code
main PROC

MostrarMensaje mensajeBienvenida
MostrarMensaje mensajeSalida

MostrarMultiplicacion 15, 2

exit

main ENDP
END main