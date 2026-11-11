; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Este programa representa la estructura basica de una aplicacion en modo protegido de 32 bits (x86) 
; utilizando la biblioteca Irvine32. Muestra el clasico mensaje "Hola Mundo!" en la consola de comandos.

; A nivel de arquitectura, demuestra la separacion fundamental entre el segmento de datos (.data), 
; donde se reserva y aloja la memoria estatica para variables y literales terminadas en nulo (ASCII 0), 
; y el segmento de codigo (.code), donde residen las instrucciones ejecutables que interactuan con 
; los registros de proposito general y las subrutinas de la biblioteca de Irvine.

INCLUDE Irvine32.inc

.data
    ; Declaracion de una cadena de caracteres en memoria como un arreglo de bytes (BYTE).
    ; El delimitador nulo (0 al final) es indispensable, ya que la subrutina WriteString 
    ; lee caracter por caracter en RAM hasta encontrar un byte con valor 00h para detenerse.
    mensaje BYTE "Hola Mundo!", 0

.code
main PROC
    ; Paso de parametros por registro para la rutina de salida estandar:
    ; Se carga en el registro EDX la direccion de memoria efectiva (OFFSET) donde inicia el arreglo de bytes.
    mov edx, OFFSET mensaje

    ; Invoca la subrutina de Irvine32 encargada de imprimir en la consola la cadena apuntada por EDX.
    call WriteString

    ; Realiza un salto de linea enviando los caracteres de retorno de carro y avance de linea (CR/LF).
    call Crlf

    ; Invoca internamente la API de Windows (ExitProcess) para terminar el proceso de manera segura.
    exit

main ENDP

; Directiva que finaliza la lectura del codigo fuente e indica al ensamblador y enlazador 
; que el punto de entrada de la ejecucion es el procedimiento 'main'.
END main