; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Esta actividad nos sirvió para saber declarar y utilizar de manera básica procedimientos (o funciones) en assembly.

INCLUDE Irvine32.inc

.data
    mensajeInicio        BYTE "Inicio de programa", 0
    mensajeProcedimiento BYTE "Estoy dentro del procedimiento", 0
    mensajeFin           BYTE "Fin del programa", 0

.code
main PROC
    ; Imprimir mensaje de inicio
    mov edx, OFFSET mensajeInicio
    call WriteString
    call Crlf

    ; Primera llamada al procedimiento
    call mensajeAviso

    ; Segunda llamada al procedimiento
    mov eax, 10
    call mensajeAviso
    mov eax, 20

    ; Imprimir mensaje de finalizacion
    mov edx, OFFSET mensajeFin
    call WriteString
    call Crlf

    exit
main ENDP

mensajeAviso PROC ; Declaración del procedimiento mensajeAviso con seguido de la palabra reservada PROC
    mov edx, OFFSET mensajeProcedimiento
    call WriteString
    call Crlf
    ret ;RET nos devuelve a la parte del código donde se hizo la llamada al procedimiento
mensajeAviso ENDP

; END main siempre va al puro final del archivo y nuestros procedimientos deben de ir antes de el
END main