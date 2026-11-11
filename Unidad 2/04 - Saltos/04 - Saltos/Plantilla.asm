; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Saltos, los programas se ejecutan de manera sequencial, con los saltos podemos romper este flujo, como un if y/o 
; una función. Saltos directos con JMP. Los saltos con hacía etiquetas. Primero hacemos una comparación con CMP
; y luego un salto hacía la etiqueta ( JMP etiqueta: ).

INCLUDE Irvine32.inc

.code
main PROC

    ; Cargamos inicialmente el valor 5 en el registro acumulador EAX.
    mov eax, 5

    jmp continuar ; Salto incondicional que rompe el flujo secuencial y salta directamente a la etiqueta 'continuar'.

    mov eax, 10 ; Esta instruccion queda inalcanzable y nunca llega a ejecutarse:

continuar:
    ; Mostramos el estado actual de los registros de la CPU en pantalla.
    ; Se observa que EAX conserva el valor 5 (00000005h) y no 10 (0000000Ah), confirmando que la asignacion previa fue omitida.
    call DumpRegs

    ; Finalizamos la ejecucion del programa y devolvemos el control al sistema operativo.
    exit

main ENDP
END main