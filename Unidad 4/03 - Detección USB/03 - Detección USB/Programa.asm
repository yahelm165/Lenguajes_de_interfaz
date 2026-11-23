; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales
; Práctica 3 y final de la unidad 4. En la que detectamos por medio de la función de windows: GetLogicalDrives
; para obtener una mascara de 32 bits, que indica las unidades disponibles en la pc.

INCLUDE Irvine32.inc
GetLogicalDrives PROTO STDCALL ; Devuelve la mascara y la guarda en EAX

.data

titulo BYTE "Unidades disponibles", 0
aviso BYTE "Conecte o retire una USB y presione una tecla", 0
salir BYTE "Presione Esc para  terminar", 0
error BYTE "No se pudieron consultar las unidades", 0
unidad BYTE "A:\", 0
mascara DWORD ?

.code
main PROC
	
actualizar:
	call Clrscr

	mov edx, offset titulo
	call WriteString
	call Crlf

	invoke GetLogicalDrives ; Guarda el valor de las unidades disponibles en EAX.

	cmp eax, 0 ;
	je ErrorLectura
	mov mascara, eax
	mov unidad, 'A' ; Al no indicarle la posición en donde se va a guardar, lo guarda en el byte 0 por default.

revisar:
	test mascara, 1 ; Si es 0, el bit esta vacio y hay que avanzar al siguiente bit
	jz siguiente
	
	mov edx, offset unidad
	call WriteString
	call Crlf

siguiente: 
	shr mascara, 1
	inc unidad

	cmp unidad, 'Z'
	jbe revisar
	
	jmp esperar

errorLectura:
	mov edx, offset error
	call WriteString
	call Crlf

esperar: 
	mov edx, offset aviso
	call WriteString
	call Crlf

	mov edx, offset salir
	call WriteString
	call Crlf
	
	call ReadChar

	cmp al, 27 ; 27 es el codigo ASCII de Esc; utilizado para salir del programa
	je finalizar
	jmp actualizar
	
finalizar:
	exit

main ENDP
END main