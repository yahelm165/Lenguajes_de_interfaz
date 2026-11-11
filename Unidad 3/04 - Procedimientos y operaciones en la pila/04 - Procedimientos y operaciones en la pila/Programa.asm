; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Esta practica trata sobre la creacion y llamada de procedimientos (funciones) en ensamblador utilizando
; la pila (stack) para el paso de parametros. Un procedimiento existe una sola vez en memoria y se invoca
; en tiempo de ejecucion mediante CALL, guardando la direccion de retorno en la pila para luego volver con RET.

; Ademas, se aplica la convencion de llamar funciones creando un marco de pila (stack frame) con EBP. Esto permite
; acceder a los parametros enviados sin importar cuanto cambie ESP durante la ejecucion de la subrutina, y usando
; 'ret n' para que el propio procedimiento limpie los parametros de la pila al terminar (convencion stdcall).

INCLUDE Irvine32.inc

.code
main PROC
    ; Asignamos un valor previo a EBX para demostrar la preservacion de registros.
    ; Si el procedimiento es una buena subrutina, debe devolver EBX intacto al terminar.
    mov ebx, 999

    push 3              ; Quedara en [ebp+12]
    push 25             ; Quedara en [ebp+8]

    ; CALL empuja automaticamente a la pila la direccion de la siguiente instruccion (direccion de retorno)
    ; y salta a la etiqueta del procedimiento SumarPila.
    call SumarPila

    ; Al volver de la llamada, el resultado de la operacion queda almacenado en EAX por convencion.
    ; Ademas, EBX conserva su valor original (999) gracias al push/pop realizado dentro del procedimiento.
    nop 
    exit
main ENDP

SumarPila PROC

    push ebp            ; Guardamos el EBP del llamador en la pila para no perder su referencia previa.
    mov ebp, esp        ; Establecemos EBP como la base fija del marco actual de la pila.
                        ; Estructura de la pila en este punto:
                        ; [ebp]     = EBP anterior guardado
                        ; [ebp+4]   = Direccion de retorno (empujada por CALL)
                        ; [ebp+8]   = Ultimo parametro empujado (25)
                        ; [ebp+12]  = Penultimo parametro empujado (3)

    push ebx            ; Guardamos EBX en la pila para respetar el registro del llamador.

    ; Accedemos a los parametros mediante direccionamiento indirecto relativo a EBP:
    mov eax, [ebp+8]    ; Cargamos en EAX el valor 25.
    mov ebx, [ebp+12]   ; Cargamos en EBX el valor 3.
    add eax, ebx

    pop ebx             ; Restauramos el valor previo de EBX (vuelve a valer 999).
    pop ebp             ; Restauramos el puntero base original del llamador.

    ; RET 8 saca la direccion de retorno de la pila para volver a 'main' y ademas le suma 8 bytes a ESP.
    ; Esto limpia automaticamente los dos parametros de 32 bits (4 bytes cada uno) que habiamos metido con PUSH.
    ret 8
SumarPila ENDP

END main