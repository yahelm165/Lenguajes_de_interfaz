; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Ejemplos de operaciones aritmeticas basicas (ADD, SUB, MUL, IMUL, DIV, IDIV),
; efecto en las banderas de acarreo/desbordamiento (CF y OF) y extension de signo (CDQ).

INCLUDE Irvine32.inc

.code
main PROC
    ; 01 ADD y SUB
    mov eax, 50
    mov ebx, 20
    add eax, ebx        ; EAX = 50 + 20 = 70
    sub eax, 15         ; EAX = 70 - 15 = 55
    nop

    ; 02 CF: Acarreo en una suma sin signo
    mov eax, 0
    mov al, 255         ; Valor maximo sin signo en 8 bits (FFh)
    add al, 1           ; AL = 00h, excede 255 -> activa Carry Flag (CF = 1)
    nop

    ; 03 OF: Desbordamiento en una suma con signo
    mov eax, 0
    mov al, 127         ; Valor maximo positivo con signo en 8 bits (7Fh)
    add al, 1           ; AL = 80h (-128), cambia el signo -> activa Overflow Flag (OF = 1)
    nop

    ; 04 MUL: Producto dentro de 32 bits (sin signo)
    mov eax, 25
    mov ebx, 3
    mul ebx             ; mul trabaja con el valor de eax, solo indico por qué lo multiplica (EDX:EAX = 75, EDX = 0)

    ; 05 MUL: Producto fuera de 32 bits (sin signo)
    mov eax, 65537
    mov ebx, 65537
    mul ebx             ; El resultado excede 32 bits: parte baja en EAX, parte alta en EDX (EDX != 0, CF=1, OF=1)

    ; 06 IMUL: Producto con signo (formato de 3 operandos)
    mov eax, -5
    imul eax, eax, 3    ; EAX = EAX * 3 = -15
    nop

    ; 07 DIV: Division entera sin signo (EDX:EAX / operando)
    mov eax, 125        ; Dividendo (parte baja)
    mov edx, 0          ; Limpiar parte alta obligatoriamente antes de dividir
    mov ebx, 12         ; Divisor
    div ebx             ; Cociente en EAX (10), Residuo en EDX (5)
    nop

    ; 08 IDIV y CDQ: Division entera con signo
    mov eax, -125       ; Dividendo negativo
    cdq                 ; Extiende el bit de signo de EAX hacia EDX (EDX = FFFFFFFFh)
    mov ebx, 12         ; Divisor
    idiv ebx            ; Cociente en EAX (-10), Residuo en EDX (-5)
    nop

    exit
main ENDP
END main