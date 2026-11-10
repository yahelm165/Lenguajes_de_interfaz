INCLUDE Irvine32.inc

.code
main PROC
    ; 01 ADD y SUB
    mov eax, 50
    mov ebx, 20
    add eax, ebx
    sub eax, 15
    nop

    ; CF: Acarreo en una suma sin signo
    mov eax, 0
    mov al, 255
    add al, 1
    nop

    ; 3 OF Desbordamiento en una suma con signo
    mov eax, 0
    mov al, 127
    add al, 1
    nop

    ; 4 MUL Producto dentro de 32 bits
    mov eax, 25
    mov ebx, 3
    mul ebx     ; mul trabaja con el valor de eax, solo indico por qué lo multiplica

    ; 5 MUL Producto fuera de 32 bits
    mov eax, 65537
    mov ebx, 65537
    mul ebx

    ; IMUL Producto con signo
    mov eax, -5
    imul eax, eax, 3
    nop

    ; 7 DIV: Dividiendo valores pequeños sin signo
    mov eax, 125
    mov edx, 0
    mov ebx, 12
    div ebx
    nop

    ; IDIV y CDQ: División con signo
    mov eax, -125
    cdq         ; Le indica a EDX que trabajaremos con negativos
    mov ebx, 12
    idiv ebx
    nop

    exit
main ENDP
END main