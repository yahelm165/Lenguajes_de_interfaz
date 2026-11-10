
INCLUDE Irvine32.inc

.data
    ; Capacidad máxima del estacionamiento
    CAPACIDAD_TOTAL EQU 10

    ; Variable de estado (cantidad de autos actualmente adentro)
    autosActuales   DWORD 0

    ; Menú y opciones
    msgMenu         BYTE "==============================", 0dh, 0ah
                    BYTE "   SISTEMA DE ESTACIONAMIENTO ", 0dh, 0ah
                    BYTE "==============================", 0dh, 0ah
                    BYTE "1. Ingresar auto", 0dh, 0ah
                    BYTE "2. Salir auto", 0dh, 0ah
                    BYTE "3. Consultar estado", 0dh, 0ah
                    BYTE "4. Salir del programa", 0dh, 0ah
                    BYTE "Seleccione una opcion: ", 0

    ; Mensajes de estado
    msgVacio        BYTE "[ESTADO] El estacionamiento esta COMPLETAMENTE VACIO.", 0dh, 0ah, 0
    msgLleno        BYTE "[ESTADO] El estacionamiento esta COMPLETAMENTE LLENO.", 0dh, 0ah, 0
    msgDisponible1  BYTE "[ESTADO] Hay espacios disponibles: ", 0
    msgDisponible2  BYTE " lugares libres de ", 0
    msgOcupado      BYTE " (Ocupados: ", 0
    msgCierre       BYTE ")", 0dh, 0ah, 0

    ; Mensajes de acciones y validaciones
    msgEntradaExito BYTE "-> Auto ingresado con exito.", 0dh, 0ah, 0
    msgSalidaExito  BYTE "-> Auto salio con exito.", 0dh, 0ah, 0
    msgErrorLleno   BYTE "-> ACCION DENEGADA: No se puede ingresar, cupo lleno.", 0dh, 0ah, 0
    msgErrorVacio   BYTE "-> ACCION DENEGADA: No hay autos por retirar.", 0dh, 0ah, 0
    msgOpcionInval  BYTE "-> Opcion no valida, intente de nuevo.", 0dh, 0ah, 0
    msgDespedida    BYTE "Cerrando sistema de estacionamiento...", 0dh, 0ah, 0

.code
main PROC

bucleMenu:
    ; Mostrar separador y menú
    call Crlf
    mov edx, OFFSET msgMenu
    call WriteString

    ; Leer opción elegida por el usuario
    call ReadInt

    ; Bifurcaciones condicionales (saltos) según la opción elegida
    cmp eax, 1
    je opcionIngreso

    cmp eax, 2
    je opcionSalida

    cmp eax, 3
    je opcionConsultar

    cmp eax, 4
    je opcionSalir

    ; Si no coincide con ninguna opción válida
    mov edx, OFFSET msgOpcionInval
    call WriteString
    jmp bucleMenu

opcionIngreso:
    mov eax, autosActuales
    cmp eax, CAPACIDAD_TOTAL
    jge estacionamientoLlenoError   ; Si autosActuales >= CAPACIDAD_TOTAL, no entra

    inc autosActuales               ; Registrar entrada
    mov edx, OFFSET msgEntradaExito
    call WriteString
    call evaluarEstado              ; Imprime el estado actual tras el cambio
    jmp bucleMenu

estacionamientoLlenoError:
    mov edx, OFFSET msgErrorLleno
    call WriteString
    jmp bucleMenu

opcionSalida:
    mov eax, autosActuales
    cmp eax, 0
    jle estacionamientoVacioError   ; Si autosActuales <= 0, no puede salir nadie

    dec autosActuales               ; Registrar salida
    mov edx, OFFSET msgSalidaExito
    call WriteString
    call evaluarEstado              ; Imprime el estado actual tras el cambio
    jmp bucleMenu

estacionamientoVacioError:
    mov edx, OFFSET msgErrorVacio
    call WriteString
    jmp bucleMenu

opcionConsultar:
    call evaluarEstado
    jmp bucleMenu

opcionSalir:
    call Crlf
    mov edx, OFFSET msgDespedida
    call WriteString
    exit

main ENDP

;-------------------------------------------------------------------------
; evaluarEstado
; Evalúa el valor de autosActuales y muestra si está:
; - Totalmente vacío (0 autos)
; - Totalmente lleno (CAPACIDAD_TOTAL autos)
; - Con cupo disponible, calculando: Libres = CAPACIDAD_TOTAL - autosActuales
;-------------------------------------------------------------------------
evaluarEstado PROC
    push eax
    push edx

    call Crlf

    ; Caso 1: Verificar si está vacío
    mov eax, autosActuales
    cmp eax, 0
    je estadoVacio

    ; Caso 2: Verificar si está lleno
    cmp eax, CAPACIDAD_TOTAL
    je estadoLleno

    ; Caso 3: Hay espacio disponible intermedio
    mov edx, OFFSET msgDisponible1
    call WriteString

    ; Calcular espacios libres = CAPACIDAD_TOTAL - autosActuales
    mov eax, CAPACIDAD_TOTAL
    sub eax, autosActuales
    call WriteDec                   ; Muestra cuántos espacios quedan

    mov edx, OFFSET msgDisponible2
    call WriteString

    mov eax, CAPACIDAD_TOTAL
    call WriteDec                   ; Muestra el cupo total

    mov edx, OFFSET msgOcupado
    call WriteString

    mov eax, autosActuales
    call WriteDec                   ; Muestra los autos ocupando lugar

    mov edx, OFFSET msgCierre
    call WriteString
    jmp finEvaluacion

estadoVacio:
    mov edx, OFFSET msgVacio
    call WriteString
    jmp finEvaluacion

estadoLleno:
    mov edx, OFFSET msgLleno
    call WriteString

finEvaluacion:
    pop edx
    pop eax
    ret
evaluarEstado ENDP

END main