INCLUDE Irvine32.inc

.data
    ; Mensajes para el usuario
    msgInicial        BYTE "Introduce el string: ", 0
    msgExito          BYTE "String correcto: ", 0
    msgErrorLongitud  BYTE "Error: Longitud incorrecta, debe ser 7.", 0
    msgErrorLetra     BYTE "Error: Los primeros 3 caracteres deben ser letras (A-Z).", 0
    msgErrorSeparador BYTE "Error: El separador debe ser '-'.", 0
    msgErrorNumero    BYTE "Error: Los ultimos 3 caracteres deben ser digitos (0-9).", 0

    ; Buffer de entrada: 8 bytes para leer hasta 7 caracteres + terminador nulo
    cadenaEntrada     BYTE 8 DUP(0)

.code
main PROC
    ; 1. Solicitar la cadena
    mov edx, OFFSET msgInicial
    call WriteString

    ; 2. Leer la cadena por consola
    mov edx, OFFSET cadenaEntrada
    mov ecx, SIZEOF cadenaEntrada    ; Tamaño máximo a leer (8 bytes)
    call ReadString                 ; Devuelve en EAX el número de caracteres leídos

    ; 3. Validar longitud exacta de 7 caracteres
    cmp eax, 7
    jne ErrorLongitud

    ; Inicializar puntero/índice
    mov esi, 0

    ; ---------------------------------------------------------
    ; 4. Validar las 3 letras (posiciones 0, 1, 2)
    ; ---------------------------------------------------------
ValidarLetras:
    mov al, cadenaEntrada[esi]
    cmp al, 'A'
    jb  ErrorLetra                  ; Si es menor a 'A', no es letra mayúscula
    cmp al, 'Z'
    ja  ErrorLetra                  ; Si es mayor a 'Z', no es letra mayúscula
    
    inc esi
    cmp esi, 3
    jl  ValidarLetras               ; Repetir para los índices 0, 1 y 2

    ; ---------------------------------------------------------
    ; 5. Validar el separador '-' (posición 3)
    ; ---------------------------------------------------------
ValidarSeparador:
    mov al, cadenaEntrada[esi]
    cmp al, '-'
    jne ErrorSeparador
    inc esi                         ; Avanzar al índice 4

    ; ---------------------------------------------------------
    ; 6. Validar los 3 dígitos (posiciones 4, 5, 6)
    ; ---------------------------------------------------------
ValidarDigitos:
    mov al, cadenaEntrada[esi]
    cmp al, '0'
    jb  ErrorNumero                 ; Si es menor a '0', no es dígito
    cmp al, '9'
    ja  ErrorNumero                 ; Si es mayor a '9', no es dígito
    
    inc esi
    cmp esi, 7
    jl  ValidarDigitos              ; Repetir para los índices 4, 5 y 6

    ; ---------------------------------------------------------
    ; 7. Si todo es correcto, imprimir éxito y la cadena
    ; ---------------------------------------------------------
Exito:
    mov edx, OFFSET msgExito
    call WriteString

    mov edx, OFFSET cadenaEntrada
    call WriteString
    call Crlf
    jmp Fin

; -------------------------------------------------------------
; Rutinas de manejo de errores
; -------------------------------------------------------------
ErrorLongitud:
    mov edx, OFFSET msgErrorLongitud
    call WriteString
    call Crlf
    jmp Fin

ErrorLetra:
    mov edx, OFFSET msgErrorLetra
    call WriteString
    call Crlf
    jmp Fin

ErrorSeparador:
    mov edx, OFFSET msgErrorSeparador
    call WriteString
    call Crlf
    jmp Fin

ErrorNumero:
    mov edx, OFFSET msgErrorNumero
    call WriteString
    call Crlf

Fin:
    exit
main ENDP
END main