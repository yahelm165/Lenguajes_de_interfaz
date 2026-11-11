; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Este programa demuestra el manejo de cadenas de texto terminadas en nulo y el paso de parametros a procedimientos 
; mediante registros del procesador.

; Se emplea una convencion rapida basada en registros: se carga la direccion base del arreglo en EDX y la subrutina 
; inspecciona directamente el primer byte en RAM. Si el primer caracter es el delimitador nulo (ASCII 0), 
; significa que el usuario presiono Enter de inmediato o que la cadena no contiene caracteres validos, 
; devolviendo un valor booleano de estado (0 o 1) en EAX.

INCLUDE Irvine32.inc

.data
    prompt      BYTE "Ingresa una cadena (o presiona Enter para dejarla vacia): ", 0

    cadena      BYTE 100 DUP(0) ; Buffer de 100 bytes inicializado en ceros para el dato a leer por teclador
    
    ; Mensajes de respuesta formateados con retorno de carro (0Dh), salto de linea (0Ah) y terminador nulo (0).
    msgVacia    BYTE "Resultado: 0 - La cadena esta vacia.", 0dh, 0ah, 0
    msgLlena    BYTE "Resultado: 1 - La cadena tiene algo.", 0dh, 0ah, 0

.code
main PROC
    mov edx, OFFSET prompt
    call WriteString

    mov edx, OFFSET cadena
    mov ecx, SIZEOF cadena
    call ReadString

    ; Paso de parametros por registro:
    ; Cargamos en EDX la direccion base de la cadena para que el procedimiento acceda a ella en memoria.
    mov edx, OFFSET cadena
    call ValidarCadena

    ; Por convencion en x86, los procedimientos devuelven sus resultados enteros o booleanos en EAX.
    ; Verificamos si EAX retorno 0 (cadena vacia) o 1 (cadena con contenido).
    cmp eax, 0
    je EsVacia

    ; Flujo cuando EAX == 1:
    mov edx, OFFSET msgLlena
    call WriteString
    jmp Fin             ; Salto incondicional para evitar ejecutar el bloque de cadena vacia.

EsVacia:
    ; Flujo cuando EAX == 0:
    mov edx, OFFSET msgVacia
    call WriteString

Fin:
    exit
main ENDP

ValidarCadena PROC
    ; Leemos unicamente el primer byte (8 bits) desde la direccion en memoria apuntada por EDX:
    mov al, [edx]       

    ; Las cadenas leidas con ReadString son terminadas en nulo (byte 0).
    ; Si el usuario solo presiono Enter, el primer byte del buffer sera 0.
    cmp al, 0           
    je CadenaVacia      ; Si el primer byte es 0, saltamos a la seccion que retorna falso.

    ; Caso 1: La cadena tiene al menos un caracter
    mov eax, 1          ; Indicador booleano de exito.
    ret

CadenaVacia:
    ; Caso 2: La cadena comenzo directamente con el byte nulo
    mov eax, 0          ; Indicador booleano de cadena vacia o fracaso.
    ret
ValidarCadena ENDP

END main