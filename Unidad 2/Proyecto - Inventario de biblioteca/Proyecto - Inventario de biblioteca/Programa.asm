; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales
; Proyecto final de la unidad 2: Inventario de una biblioteca.
; Archivo de datos: Inventario.txt


INCLUDE Irvine32.inc

; ----------------------------------------------------------------------------
; Constantes del sistema
; ----------------------------------------------------------------------------
MAX_LIBROS          EQU 10
TAM_CODIGO          EQU 8               ; "ABC-123" (7) + 0 (1)
TAM_NOMBRE          EQU 25              ; Maximo 24 chars + terminador 0 (1)
MAX_EXISTENCIA      EQU 100
MIN_PRECIO_CENT     EQU 1               ; $0.01 MXN
MAX_PRECIO_CENT     EQU 999999          ; $9,999.99 MXN
TAM_BUFFER_ENTRADA  EQU 64
TAM_BUFFER_NUM      EQU 32
TAM_BUFFER_ARCHIVO  EQU 2048

; ----------------------------------------------------------------------------
; Estructura de cada libro en memoria
; ----------------------------------------------------------------------------
Libro STRUCT
    codigo      BYTE TAM_CODIGO DUP(0)  ; 8 bytes: "ABC-123",0
    nombre      BYTE TAM_NOMBRE DUP(0)  ; 25 bytes: titulo,0
    pad         BYTE 3 DUP(0)           ; 3 bytes de alineacion (36 bytes)
    existencia  DWORD 0                 ; 4 bytes: 0..100
    precioCent  DWORD 0                 ; 4 bytes: 1..999999 centavos
    vendidos    DWORD 0                 ; 4 bytes: unidades vendidas en sesion
Libro ENDS                              ; Total = 48 bytes

.data
; ----------------------------------------------------------------------------
; Datos del inventario y estado de la sesion
; ----------------------------------------------------------------------------
inventario          Libro MAX_LIBROS DUP(<>)
numLibros           DWORD 0
ingresosSesion      DWORD 0
hayCambios          BYTE 0              ; 0 = sin cambios, 1 = cambios pendientes

nombreArchivo       BYTE "Inventario.txt", 0
manejadorArchivo    DWORD ?
bufferArchivo       BYTE TAM_BUFFER_ARCHIVO DUP(0)
bytesArchivo        DWORD 0

; Buffers de entrada/salida
bufferEntrada       BYTE TAM_BUFFER_ENTRADA DUP(0)
bufferNumero        BYTE TAM_BUFFER_NUM DUP(0)
bufferCodigoTemp    BYTE TAM_CODIGO DUP(0)
bufferNombreTemp    BYTE TAM_NOMBRE DUP(0)

; Textos de interfaz y menu
msgTitulo           BYTE "====================================================", 0Dh, 0Ah
                    BYTE "      SISTEMA DE INVENTARIO DE BIBLIOTECA (MXN)     ", 0Dh, 0Ah
                    BYTE "====================================================", 0Dh, 0Ah, 0
msgMenu             BYTE 0Dh, 0Ah
                    BYTE "1. Registrar libro", 0Dh, 0Ah
                    BYTE "2. Mostrar inventario", 0Dh, 0Ah
                    BYTE "3. Buscar libro por codigo", 0Dh, 0Ah
                    BYTE "4. Recibir mercancia", 0Dh, 0Ah
                    BYTE "5. Vender libro", 0Dh, 0Ah
                    BYTE "6. Mostrar resumen", 0Dh, 0Ah
                    BYTE "7. Mostrar libro mas vendido", 0Dh, 0Ah
                    BYTE "8. Guardar inventario en archivo", 0Dh, 0Ah
                    BYTE "9. Cargar inventario desde archivo", 0Dh, 0Ah
                    BYTE "0. Salir", 0Dh, 0Ah
                    BYTE "Seleccione una opcion: ", 0

; Prompts y etiquetas
promptNombre        BYTE "Ingrese nombre del libro (max 24 chars): ", 0
promptExistencia    BYTE "Ingrese existencia inicial (0-100): ", 0
promptPrecio        BYTE "Ingrese precio en MXN (ej. 7, 7.5, 185.50, 1599.99): ", 0
promptCodigo        BYTE "Ingrese codigo del libro (formato ABC-123): ", 0
promptCantidadRec   BYTE "Ingrese cantidad a recibir (> 0): ", 0
promptCantidadVen   BYTE "Ingrese cantidad a vender (> 0): ", 0
promptConfirmarSN   BYTE "Hay cambios sin guardar. Desea guardar antes de continuar? (S/N): ", 0
promptGuardarSalir  BYTE "Hay cambios sin guardar en Inventario.txt. Desea guardarlos antes de salir? (S/N): ", 0

msgEncabezadoTabla  BYTE 0Dh, 0Ah
                    BYTE "CODIGO   | NOMBRE                   | EXIST | VEND | PRECIO", 0Dh, 0Ah
                    BYTE "---------+--------------------------+-------+------+----------------", 0Dh, 0Ah, 0
msgSepCol           BYTE " | ", 0
msgSeparadorArch    BYTE " | ", 0
msgSaltoLinea       BYTE 0Dh, 0Ah, 0
msgEspacio          BYTE " ", 0
msgPeso             BYTE "$", 0
msgMXN              BYTE " MXN", 0

; Mensajes de exito / informacion
msgRegExitoso       BYTE "Libro registrado correctamente con codigo: ", 0
msgRecepExitosa     BYTE "Mercancia recibida. Nueva existencia: ", 0
msgVentaExitosa     BYTE "Venta realizada. Importe total: ", 0
msgGuardadoOk       BYTE "Inventario guardado correctamente en Inventario.txt.", 0Dh, 0Ah, 0
msgCargadoOk        BYTE "Inventario cargado correctamente desde Inventario.txt.", 0Dh, 0Ah, 0
msgSinArchivo       BYTE "No se encontro Inventario.txt. Se inicia catalogo vacio.", 0Dh, 0Ah, 0
msgCatalogoVacio    BYTE "El inventario esta vacio.", 0Dh, 0Ah, 0
msgSinVentas        BYTE "Aun no se han registrado ventas en esta sesion.", 0Dh, 0Ah, 0
msgDespedida        BYTE "Cerrando el sistema de biblioteca. Hasta luego.", 0Dh, 0Ah, 0

; Etiquetas de consulta y resumen
msgLblCodigo        BYTE "Codigo:      ", 0
msgLblNombre        BYTE "Nombre:      ", 0
msgLblExistencia    BYTE "Existencia:  ", 0
msgLblPrecio        BYTE "Precio:      ", 0
msgLblVendidos      BYTE "Vendidos:    ", 0
msgResumenTit       BYTE 0Dh, 0Ah, "--- RESUMEN DEL INVENTARIO ---", 0Dh, 0Ah, 0
msgResLibros        BYTE "Libros registrados:        ", 0
msgResUnidades      BYTE "Unidades disponibles:      ", 0
msgResValor         BYTE "Valor total inventario:    ", 0
msgResIngresos      BYTE "Ingresos de la sesion:     ", 0
msgMasVendidoTit    BYTE 0Dh, 0Ah, "--- LIBRO MAS VENDIDO DE LA SESION ---", 0Dh, 0Ah, 0

; Mensajes de error
errOpcion           BYTE "Error: Opcion invalida. Intente de nuevo.", 0Dh, 0Ah, 0
errCapacidad        BYTE "Error: Capacidad maxima alcanzada (10 libros).", 0Dh, 0Ah, 0
errDatoVacio        BYTE "Error: El dato no puede estar vacio.", 0Dh, 0Ah, 0
errCaracterPipe     BYTE "Error: El nombre no puede contener el caracter '|'.", 0Dh, 0Ah, 0
errCodigoFormato    BYTE "Error: Formato invalido. Use 3 mayusculas, guion y 3 digitos (ABC-123).", 0Dh, 0Ah, 0
errCodigoNoExiste   BYTE "Error: No existe un libro con ese codigo.", 0Dh, 0Ah, 0
errNumeroInvalido   BYTE "Error: Ingrese un numero entero valido sin simbolos ni letras.", 0Dh, 0Ah, 0
errExistenciaRango  BYTE "Error: La existencia debe estar entre 0 y 100.", 0Dh, 0Ah, 0
errCantidadPositiva BYTE "Error: La cantidad debe ser un entero mayor a 0.", 0Dh, 0Ah, 0
errExcedeStockMax   BYTE "Error: La suma excede el maximo permitido de 100 unidades.", 0Dh, 0Ah, 0
errSinExistencias   BYTE "Error: Este libro no tiene existencias disponibles.", 0Dh, 0Ah, 0
errStockInsuf       BYTE "Error: Existencias insuficientes para la cantidad solicitada.", 0Dh, 0Ah, 0
errPrecioInvalido   BYTE "Error: Precio invalido. Rango: 0.01 a 9999.99 (hasta 2 decimales, solo digitos y punto).", 0Dh, 0Ah, 0
errDesbordamiento   BYTE "Error: Desbordamiento aritmetico en el calculo. Operacion rechazada.", 0Dh, 0Ah, 0
errArchivoCrear     BYTE "Error: No se pudo crear o escribir Inventario.txt.", 0Dh, 0Ah, 0
errArchivoLeer      BYTE "Error: No se pudo leer Inventario.txt o el formato es invalido.", 0Dh, 0Ah, 0
errRespuestaSN      BYTE "Error: Responda S (si) o N (no).", 0Dh, 0Ah, 0

.code
; ============================================================================
; Procedimiento: main
; Descripcion: Punto de entrada. Inicializa semilla aleatoria, intenta cargar
;              Inventario.txt y ejecuta el ciclo principal del menu.
; Entradas: Ninguna
; Salidas: Ninguna (termina con exit)
; Registros modificados: EAX, EDX, ECX
; ============================================================================
main PROC
    call Randomize
    call CargarInventarioSilencioso

CicloMenu:
    call Crlf
    mov edx, OFFSET msgTitulo
    call WriteString
    mov edx, OFFSET msgMenu
    call WriteString

    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    cmp eax, 1
    jne OpcionInvalida

    mov al, bufferEntrada[0]
    cmp al, '1'
    je OpRegistrar
    cmp al, '2'
    je OpMostrar
    cmp al, '3'
    je OpBuscar
    cmp al, '4'
    je OpRecibir
    cmp al, '5'
    je OpVender
    cmp al, '6'
    je OpResumen
    cmp al, '7'
    je OpMasVendido
    cmp al, '8'
    je OpGuardar
    cmp al, '9'
    je OpCargar
    cmp al, '0'
    je OpSalir

OpcionInvalida:
    mov edx, OFFSET errOpcion
    call WriteString
    jmp CicloMenu

OpRegistrar:
    call RegistrarLibro
    jmp CicloMenu
OpMostrar:
    call MostrarInventario
    jmp CicloMenu
OpBuscar:
    call ConsultarLibro
    jmp CicloMenu
OpRecibir:
    call RecibirMercancia
    jmp CicloMenu
OpVender:
    call VenderLibro
    jmp CicloMenu
OpResumen:
    call MostrarResumen
    jmp CicloMenu
OpMasVendido:
    call MostrarMasVendido
    jmp CicloMenu
OpGuardar:
    call GuardarInventario
    jmp CicloMenu
OpCargar:
    call CargarInventarioInteractivo
    jmp CicloMenu
OpSalir:
    call ConfirmarSalida
    mov edx, OFFSET msgDespedida
    call WriteString
    exit
main ENDP

; ============================================================================
; Procedimiento: LongitudCadena
; Descripcion: Calcula la longitud de una cadena terminada en 0 usando ESI.
; Entradas: EDX = direccion de la cadena
; Salidas: EAX = longitud (sin incluir terminador 0)
; Registros modificados: EAX
; ============================================================================
LongitudCadena PROC
    push esi
    mov esi, edx
    xor eax, eax
LC_Loop:
    cmp BYTE PTR [esi], 0
    je LC_Fin
    inc eax
    inc esi
    jmp LC_Loop
LC_Fin:
    pop esi
    ret
LongitudCadena ENDP

; ============================================================================
; Procedimiento: CopiarCadena
; Descripcion: Copia una cadena terminada en 0 usando ESI y EDI.
; Entradas: ESI = origen, EDI = destino, ECX = tamano maximo destino (incl. 0)
; Salidas: Cadena copiada en [EDI]
; Registros modificados: Ninguno
; ============================================================================
CopiarCadena PROC
    push eax
    push ecx
    push esi
    push edi

    cmp ecx, 0
    je CC_Fin
    dec ecx                             ; Reservar 1 byte para terminador 0

CC_Loop:
    cmp ecx, 0
    je CC_Terminar
    mov al, [esi]
    mov [edi], al
    cmp al, 0
    je CC_Fin
    inc esi
    inc edi
    dec ecx
    jmp CC_Loop

CC_Terminar:
    mov BYTE PTR [edi], 0

CC_Fin:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
CopiarCadena ENDP

; ============================================================================
; Procedimiento: CompararCadenas
; Descripcion: Compara dos cadenas terminadas en 0 usando ESI y EDI.
; Entradas: ESI = cadena 1, EDI = cadena 2
; Salidas: EAX = 1 si son iguales, 0 si son distintas
; Registros modificados: EAX
; ============================================================================
CompararCadenas PROC
    push ebx
    push esi
    push edi

Cmp_Loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne Cmp_Distintas
    cmp al, 0
    je Cmp_Iguales
    inc esi
    inc edi
    jmp Cmp_Loop

Cmp_Iguales:
    mov eax, 1
    jmp Cmp_Fin

Cmp_Distintas:
    xor eax, eax

Cmp_Fin:
    pop edi
    pop esi
    pop ebx
    ret
CompararCadenas ENDP

; ============================================================================
; Procedimiento: CadenaSoloEspacios
; Descripcion: Verifica si una cadena esta vacia o contiene solo espacios.
; Entradas: EDX = direccion de la cadena
; Salidas: EAX = 1 si esta vacia o solo espacios, 0 si tiene texto visible
; Registros modificados: EAX
; ============================================================================
CadenaSoloEspacios PROC
    push esi
    mov esi, edx
CSE_Loop:
    mov al, [esi]
    cmp al, 0
    je CSE_Vacia
    cmp al, ' '
    jne CSE_ConTexto
    inc esi
    jmp CSE_Loop
CSE_Vacia:
    mov eax, 1
    jmp CSE_Fin
CSE_ConTexto:
    xor eax, eax
CSE_Fin:
    pop esi
    ret
CadenaSoloEspacios ENDP

; ============================================================================
; Procedimiento: ContienePipe
; Descripcion: Verifica si una cadena contiene el caracter '|' (delimitador).
; Entradas: EDX = direccion de la cadena
; Salidas: EAX = 1 si contiene '|', 0 si no
; Registros modificados: EAX
; ============================================================================
ContienePipe PROC
    push esi
    mov esi, edx
CP_Loop:
    mov al, [esi]
    cmp al, 0
    je CP_No
    cmp al, '|'
    je CP_Si
    inc esi
    jmp CP_Loop
CP_Si:
    mov eax, 1
    jmp CP_Fin
CP_No:
    xor eax, eax
CP_Fin:
    pop esi
    ret
ContienePipe ENDP

; ============================================================================
; Procedimiento: CadenaAEntero
; Descripcion: Convierte una cadena ASCII decimal sin signo a DWORD.
;              Rechaza cadenas vacias, caracteres no digitos y desbordamientos.
; Entradas: EDX = direccion de la cadena
; Salidas: EAX = valor entero; CF = 0 si valido, CF = 1 si invalido
; Registros modificados: EAX, CF
; ============================================================================
CadenaAEntero PROC
    push ebx
    push ecx
    push edx
    push esi

    mov esi, edx
    cmp BYTE PTR [esi], 0
    je CAE_Error

    xor eax, eax
    mov ecx, 10

CAE_Loop:
    mov bl, [esi]
    cmp bl, 0
    je CAE_Ok

    cmp bl, '0'
    jb CAE_Error
    cmp bl, '9'
    ja CAE_Error

    sub bl, '0'
    movzx ebx, bl

    mul ecx                             ; EDX:EAX = EAX * 10
    cmp edx, 0
    jne CAE_Error

    add eax, ebx
    jc CAE_Error

    inc esi
    jmp CAE_Loop

CAE_Ok:
    clc
    jmp CAE_Fin

CAE_Error:
    xor eax, eax
    stc

CAE_Fin:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
CadenaAEntero ENDP

; ============================================================================
; Procedimiento: EnteroACadena
; Descripcion: Convierte un entero DWORD sin signo a cadena ASCII terminada en 0.
; Entradas: EAX = entero sin signo, EDI = buffer destino (minimo 12 bytes)
; Salidas: Cadena escrita en [EDI]
; Registros modificados: Ninguno
; ============================================================================
EnteroACadena PROC
    push eax
    push ebx
    push ecx
    push edx
    push edi

    cmp eax, 0
    jne EAC_NoCero
    mov BYTE PTR [edi], '0'
    mov BYTE PTR [edi + 1], 0
    jmp EAC_Fin

EAC_NoCero:
    xor ecx, ecx
    mov ebx, 10

EAC_DivLoop:
    xor edx, edx
    div ebx                             ; EAX = cociente, EDX = residuo
    add dl, '0'
    push edx
    inc ecx
    cmp eax, 0
    jne EAC_DivLoop

EAC_PopLoop:
    pop edx
    mov [edi], dl
    inc edi
    dec ecx
    jnz EAC_PopLoop

    mov BYTE PTR [edi], 0

EAC_Fin:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
EnteroACadena ENDP

; ============================================================================
; Procedimiento: EscribirEntero
; Descripcion: Muestra un entero sin signo en consola usando EnteroACadena y
;              WriteString (sin usar WriteDec).
; Entradas: EAX = entero sin signo
; Salidas: Ninguna (imprime en consola)
; Registros modificados: Ninguno
; ============================================================================
EscribirEntero PROC
    push edx
    push edi
    mov edi, OFFSET bufferNumero
    call EnteroACadena
    mov edx, OFFSET bufferNumero
    call WriteString
    pop edi
    pop edx
    ret
EscribirEntero ENDP

; ============================================================================
; Procedimiento: CadenaACentavos
; Descripcion: Convierte una cadena de precio en pesos MXN (ej. "7", "7.5",
;              "7.05", "185.50", "1599.99") a centavos enteros (1..999999).
;              Rechaza simbolos, letras, comas, negativos o mas de 2 decimales.
; Entradas: EDX = direccion de la cadena
; Salidas: EAX = centavos (1..999999); CF = 0 si valido, CF = 1 si invalido
; Registros modificados: EAX, CF
; ============================================================================
CadenaACentavos PROC
    push ebx
    push ecx
    push edx
    push esi

    mov esi, edx
    cmp BYTE PTR [esi], 0
    je CAC_Error

    xor eax, eax                        ; Acumulador parte entera (pesos)
    xor ecx, ecx                        ; Contador de digitos enteros

CAC_EnteraLoop:
    mov bl, [esi]
    cmp bl, 0
    je CAC_FinEnteraSinPunto
    cmp bl, '.'
    je CAC_Punto

    cmp bl, '0'
    jb CAC_Error
    cmp bl, '9'
    ja CAC_Error

    sub bl, '0'
    movzx ebx, bl
    imul eax, 10
    add eax, ebx
    cmp eax, 9999                       ; Limite maximo de pesos: 9999
    ja CAC_Error

    inc ecx
    inc esi
    jmp CAC_EnteraLoop

CAC_FinEnteraSinPunto:
    cmp ecx, 0
    je CAC_Error                        ; Cadena vacia
    imul eax, 100                       ; Convertir pesos a centavos
    jmp CAC_ValidarRango

CAC_Punto:
    cmp ecx, 0
    je CAC_Error                        ; No se permite iniciar con '.' (ej ".5")
    inc esi                             ; Saltar '.'

    ; Primer digito decimal (obligatorio)
    mov bl, [esi]
    cmp bl, '0'
    jb CAC_Error
    cmp bl, '9'
    ja CAC_Error
    sub bl, '0'
    movzx ebx, bl
    imul ebx, 10                        ; Decimas -> centavos (ej .5 -> 50)
    inc esi

    ; Segundo digito decimal (opcional)
    mov dl, [esi]
    cmp dl, 0
    je CAC_Combinar
    cmp dl, '0'
    jb CAC_Error
    cmp dl, '9'
    ja CAC_Error
    sub dl, '0'
    movzx edx, dl
    add ebx, edx
    inc esi

    ; No debe haber mas caracteres despues del segundo decimal
    cmp BYTE PTR [esi], 0
    jne CAC_Error

CAC_Combinar:
    imul eax, 100
    add eax, ebx

CAC_ValidarRango:
    cmp eax, MIN_PRECIO_CENT
    jb CAC_Error
    cmp eax, MAX_PRECIO_CENT
    ja CAC_Error

    clc
    jmp CAC_Fin

CAC_Error:
    xor eax, eax
    stc

CAC_Fin:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
CadenaACentavos ENDP

; ============================================================================
; Procedimiento: CentavosACadenaMXN
; Descripcion: Formatea centavos enteros en formato "$#,###.## MXN" con coma
;              en los miles y 2 decimales exactos.
; Entradas: EAX = centavos totales (DWORD), EDI = buffer destino (>= 28 bytes)
; Salidas: Cadena formateada en [EDI]
; Registros modificados: Ninguno
; ============================================================================
CentavosACadenaMXN PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov ebx, 100
    xor edx, edx
    div ebx                             ; EAX = pesos, EDX = centavos (0..99)
    push edx                            ; Guardar centavos en pila

    xor ecx, ecx                        ; Total de chars en pila para parte entera
    xor esi, esi                        ; Contador de digitos para insertar coma

    cmp eax, 0
    jne CCM_LoopEntera
    push '0'
    inc ecx
    jmp CCM_EscribirPrefijo

CCM_LoopEntera:
    xor edx, edx
    mov ebx, 10
    div ebx                             ; EAX = cociente, EDX = digito
    add dl, '0'
    push edx
    inc ecx
    inc esi

    cmp eax, 0
    je CCM_EscribirPrefijo
    cmp esi, 3
    jne CCM_LoopEntera

    push ','
    inc ecx
    xor esi, esi
    jmp CCM_LoopEntera

CCM_EscribirPrefijo:
    mov BYTE PTR [edi], '$'
    inc edi

CCM_PopEntera:
    pop edx
    mov [edi], dl
    inc edi
    dec ecx
    jnz CCM_PopEntera

    mov BYTE PTR [edi], '.'
    inc edi

    ; Recuperar centavos (0..99)
    pop eax
    xor edx, edx
    mov ebx, 10
    div ebx                             ; EAX = decenas, EDX = unidades
    add al, '0'
    add dl, '0'
    mov [edi], al
    mov [edi + 1], dl
    add edi, 2

    mov BYTE PTR [edi], ' '
    mov BYTE PTR [edi + 1], 'M'
    mov BYTE PTR [edi + 2], 'X'
    mov BYTE PTR [edi + 3], 'N'
    mov BYTE PTR [edi + 4], 0

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
CentavosACadenaMXN ENDP

; ============================================================================
; Procedimiento: EscribirCentavosMXN
; Descripcion: Muestra un monto en centavos formateado como "$#,###.## MXN"
;              usando WriteString.
; Entradas: EAX = centavos (DWORD)
; Salidas: Ninguna
; Registros modificados: Ninguno
; ============================================================================
EscribirCentavosMXN PROC
    push edx
    push edi
    mov edi, OFFSET bufferNumero
    call CentavosACadenaMXN
    mov edx, OFFSET bufferNumero
    call WriteString
    pop edi
    pop edx
    ret
EscribirCentavosMXN ENDP

; ============================================================================
; Procedimiento: ValidarFormatoCodigo
; Descripcion: Verifica que una cadena cumpla el formato exacto "ABC-123"
;              (3 letras mayusculas, guion medio, 3 digitos).
; Entradas: EDX = direccion de la cadena
; Salidas: CF = 0 si es valido, CF = 1 si es invalido
; Registros modificados: CF
; ============================================================================
ValidarFormatoCodigo PROC
    push eax
    push ecx
    push esi

    mov esi, edx
    mov ecx, 3
VFC_Letras:
    mov al, [esi]
    cmp al, 'A'
    jb VFC_Error
    cmp al, 'Z'
    ja VFC_Error
    inc esi
    dec ecx
    jnz VFC_Letras

    cmp BYTE PTR [esi], '-'
    jne VFC_Error
    inc esi

    mov ecx, 3
VFC_Digitos:
    mov al, [esi]
    cmp al, '0'
    jb VFC_Error
    cmp al, '9'
    ja VFC_Error
    inc esi
    dec ecx
    jnz VFC_Digitos

    cmp BYTE PTR [esi], 0
    jne VFC_Error

    clc
    jmp VFC_Fin

VFC_Error:
    stc

VFC_Fin:
    pop esi
    pop ecx
    pop eax
    ret
ValidarFormatoCodigo ENDP

; ============================================================================
; Procedimiento: BuscarLibroPorCodigo
; Descripcion: Recorre el arreglo inventario usando ESI buscando un codigo.
; Entradas: EDX = direccion del codigo a buscar
; Salidas: EAX = indice (0..numLibros-1) si se encuentra, o -1 si no existe.
;          ESI = direccion del registro Libro si se encuentra.
; Registros modificados: EAX, ESI
; ============================================================================
BuscarLibroPorCodigo PROC
    push ebx
    push ecx
    push edi

    mov ecx, numLibros
    cmp ecx, 0
    je BLC_NoEncontrado

    mov esi, OFFSET inventario
    xor ebx, ebx                        ; Indice actual

BLC_Loop:
    push esi
    mov edi, edx
    call CompararCadenas                ; Compara [ESI] (codigo) con [EDI]
    pop esi
    cmp eax, 1
    je BLC_Encontrado

    add esi, SIZEOF Libro
    inc ebx
    dec ecx
    jnz BLC_Loop

BLC_NoEncontrado:
    mov eax, -1
    jmp BLC_Fin

BLC_Encontrado:
    mov eax, ebx

BLC_Fin:
    pop edi
    pop ecx
    pop ebx
    ret
BuscarLibroPorCodigo ENDP

; ============================================================================
; Procedimiento: GenerarCodigoUnico
; Descripcion: Genera un codigo aleatorio con formato ABC-123 y verifica que
;              no exista en el inventario.
; Entradas: EDI = buffer de 8 bytes destino
; Salidas: Codigo unico escrito en [EDI]
; Registros modificados: Ninguno
; ============================================================================
GenerarCodigoUnico PROC
    push eax
    push ecx
    push edx
    push esi
    push edi

GCU_Intentar:
    mov esi, edi

    ; 3 letras mayusculas (A-Z)
    mov ecx, 3
GCU_Letras:
    mov eax, 26
    call RandomRange
    add al, 'A'
    mov [esi], al
    inc esi
    dec ecx
    jnz GCU_Letras

    mov BYTE PTR [esi], '-'
    inc esi

    ; 3 digitos (0-9)
    mov ecx, 3
GCU_Digitos:
    mov eax, 10
    call RandomRange
    add al, '0'
    mov [esi], al
    inc esi
    dec ecx
    jnz GCU_Digitos

    mov BYTE PTR [esi], 0

    ; Verificar unicidad
    mov edx, edi
    call BuscarLibroPorCodigo
    cmp eax, -1
    jne GCU_Intentar                    ; Si ya existe, generar otro

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
GenerarCodigoUnico ENDP

; ============================================================================
; Procedimiento: MostrarDetalleLibro
; Descripcion: Imprime en formato vertical todos los campos de un libro.
; Entradas: ESI = puntero al Libro en inventario
; Salidas: Ninguna
; Registros modificados: Ninguno
; ============================================================================
MostrarDetalleLibro PROC
    push eax
    push edx

    mov edx, OFFSET msgLblCodigo
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf

    mov edx, OFFSET msgLblNombre
    call WriteString
    lea edx, (Libro PTR [esi]).nombre
    call WriteString
    call Crlf

    mov edx, OFFSET msgLblExistencia
    call WriteString
    mov eax, (Libro PTR [esi]).existencia
    call EscribirEntero
    call Crlf

    mov edx, OFFSET msgLblPrecio
    call WriteString
    mov eax, (Libro PTR [esi]).precioCent
    call EscribirCentavosMXN
    call Crlf

    mov edx, OFFSET msgLblVendidos
    call WriteString
    mov eax, (Libro PTR [esi]).vendidos
    call EscribirEntero
    call Crlf

    pop edx
    pop eax
    ret
MostrarDetalleLibro ENDP

; ============================================================================
; Procedimiento: EscribirEspacios
; Descripcion: Imprime ECX espacios en consola usando WriteString.
; Entradas: ECX = cantidad de espacios
; Salidas: Ninguna
; Registros modificados: Ninguno
; ============================================================================
EscribirEspacios PROC
    push ecx
    push edx
    cmp ecx, 0
    jle EE_Fin
    mov edx, OFFSET msgEspacio
EE_Loop:
    call WriteString
    dec ecx
    jnz EE_Loop
EE_Fin:
    pop edx
    pop ecx
    ret
EscribirEspacios ENDP

; ============================================================================
; Procedimiento: RegistrarLibro
; Descripcion: Opcion 1. Da de alta un nuevo libro validando capacidad (<= 10),
;              nombre no vacio (<= 24 chars), existencia (0..100), precio
;              (0.01..9999.99 MXN) y generando un codigo ABC-123 unico.
; Entradas: Ninguna (usa variables globales)
; Salidas: Nuevo libro en inventario si todo es valido
; Registros modificados: EAX, EBX, ECX, EDX, ESI, EDI
; ============================================================================
RegistrarLibro PROC
    mov eax, numLibros
    cmp eax, MAX_LIBROS
    jb RL_CapturarNombre
    mov edx, OFFSET errCapacidad
    call WriteString
    ret

RL_CapturarNombre:
    mov edx, OFFSET promptNombre
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    call CadenaSoloEspacios
    cmp eax, 1
    jne RL_CheckPipe
    mov edx, OFFSET errDatoVacio
    call WriteString
    jmp RL_CapturarNombre

RL_CheckPipe:
    mov edx, OFFSET bufferEntrada
    call ContienePipe
    cmp eax, 0
    je RL_CopiarNombreTemp
    mov edx, OFFSET errCaracterPipe
    call WriteString
    jmp RL_CapturarNombre

RL_CopiarNombreTemp:
    mov esi, OFFSET bufferEntrada
    mov edi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    call CopiarCadena

RL_CapturarExistencia:
    mov edx, OFFSET promptExistencia
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    call CadenaAEntero
    jc RL_ErrNumExist
    cmp eax, MAX_EXISTENCIA
    ja RL_ErrRangoExist
    mov ebx, eax                        ; EBX = existencia validada
    jmp RL_CapturarPrecio

RL_ErrNumExist:
    mov edx, OFFSET errNumeroInvalido
    call WriteString
    jmp RL_CapturarExistencia

RL_ErrRangoExist:
    mov edx, OFFSET errExistenciaRango
    call WriteString
    jmp RL_CapturarExistencia

RL_CapturarPrecio:
    mov edx, OFFSET promptPrecio
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    call CadenaACentavos
    jc RL_ErrPrecio
    push eax                            ; Guardar precioCent validado en pila
    jmp RL_GuardarRegistro

RL_ErrPrecio:
    mov edx, OFFSET errPrecioInvalido
    call WriteString
    jmp RL_CapturarPrecio

RL_GuardarRegistro:
    ; Calcular direccion del nuevo elemento con ESI
    mov eax, numLibros
    mov ecx, SIZEOF Libro
    mul ecx
    mov esi, OFFSET inventario
    add esi, eax

    ; Generar codigo unico directamente en el registro
    lea edi, (Libro PTR [esi]).codigo
    call GenerarCodigoUnico

    ; Copiar nombre
    push esi
    lea edi, (Libro PTR [esi]).nombre
    mov esi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    call CopiarCadena
    pop esi

    ; Guardar existencia, precio y vendidos = 0
    mov (Libro PTR [esi]).existencia, ebx
    pop eax                             ; Recuperar precioCent de pila
    mov (Libro PTR [esi]).precioCent, eax
    mov (Libro PTR [esi]).vendidos, 0

    inc numLibros
    mov hayCambios, 1

    mov edx, OFFSET msgRegExitoso
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf
    ret
RegistrarLibro ENDP

; ============================================================================
; Procedimiento: MostrarInventario
; Descripcion: Opcion 2. Muestra todos los libros en tabla alineada usando ESI.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, ECX, EDX, ESI
; ============================================================================
MostrarInventario PROC
    mov ecx, numLibros
    cmp ecx, 0
    jne MI_ImprimirTabla
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    ret

MI_ImprimirTabla:
    mov edx, OFFSET msgEncabezadoTabla
    call WriteString

    mov esi, OFFSET inventario

MI_Loop:
    push ecx

    ; Codigo (7 chars + 1 espacio = 8)
    mov edx, esi
    call WriteString
    mov ecx, 1
    call EscribirEspacios
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Nombre (alineado a 24 chars)
    lea edx, (Libro PTR [esi]).nombre
    call WriteString
    call LongitudCadena
    mov ecx, 24
    sub ecx, eax
    call EscribirEspacios
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Existencia (alineado a 5 chars)
    mov eax, (Libro PTR [esi]).existencia
    mov edi, OFFSET bufferNumero
    call EnteroACadena
    mov edx, OFFSET bufferNumero
    call WriteString
    call LongitudCadena
    mov ecx, 5
    sub ecx, eax
    call EscribirEspacios
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Vendidos (alineado a 4 chars)
    mov eax, (Libro PTR [esi]).vendidos
    mov edi, OFFSET bufferNumero
    call EnteroACadena
    mov edx, OFFSET bufferNumero
    call WriteString
    call LongitudCadena
    mov ecx, 4
    sub ecx, eax
    call EscribirEspacios
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Precio formateado
    mov eax, (Libro PTR [esi]).precioCent
    call EscribirCentavosMXN
    call Crlf

    add esi, SIZEOF Libro
    pop ecx
    dec ecx
    jnz MI_Loop
    ret
MostrarInventario ENDP

; ============================================================================
; Procedimiento: SolicitarYBuscarCodigo
; Descripcion: Auxiliar para pedir un codigo, validar su formato ABC-123 y
;              buscarlo en el inventario.
; Entradas: Ninguna
; Salidas: EAX = indice o -1 si no se encontro/cancelo; ESI = puntero al libro
; Registros modificados: EAX, ECX, EDX, ESI
; ============================================================================
SolicitarYBuscarCodigo PROC
    mov edx, OFFSET promptCodigo
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    call ValidarFormatoCodigo
    jc SYB_FormatoInv

    mov edx, OFFSET bufferEntrada
    call BuscarLibroPorCodigo
    cmp eax, -1
    jne SYB_Fin
    mov edx, OFFSET errCodigoNoExiste
    call WriteString
    jmp SYB_Fin

SYB_FormatoInv:
    mov edx, OFFSET errCodigoFormato
    call WriteString
    mov eax, -1

SYB_Fin:
    ret
SolicitarYBuscarCodigo ENDP

; ============================================================================
; Procedimiento: ConsultarLibro
; Descripcion: Opcion 3. Busca un libro por codigo y muestra su detalle.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, ECX, EDX, ESI
; ============================================================================
ConsultarLibro PROC
    cmp numLibros, 0
    jne CL_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    ret

CL_Buscar:
    call SolicitarYBuscarCodigo
    cmp eax, -1
    je CL_Fin
    call Crlf
    call MostrarDetalleLibro
CL_Fin:
    ret
ConsultarLibro ENDP

; ============================================================================
; Procedimiento: RecibirMercancia
; Descripcion: Opcion 4. Suma unidades (> 0) a un libro sin superar 100.
; Entradas: Ninguna
; Salidas: Actualiza existencia y hayCambios si procede
; Registros modificados: EAX, EBX, ECX, EDX, ESI
; ============================================================================
RecibirMercancia PROC
    cmp numLibros, 0
    jne RM_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    ret

RM_Buscar:
    call SolicitarYBuscarCodigo
    cmp eax, -1
    je RM_Fin

    mov ebx, esi                        ; EBX = puntero al libro

RM_PedirCantidad:
    mov edx, OFFSET promptCantidadRec
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    call CadenaAEntero
    jc RM_ErrNum
    cmp eax, 0
    je RM_ErrCero

    ; Comprobar desbordamiento y limite maximo de 100 unidades
    mov ecx, (Libro PTR [ebx]).existencia
    add ecx, eax
    jc RM_ErrLimite
    cmp ecx, MAX_EXISTENCIA
    ja RM_ErrLimite

    mov (Libro PTR [ebx]).existencia, ecx
    mov hayCambios, 1

    mov edx, OFFSET msgRecepExitosa
    call WriteString
    mov eax, ecx
    call EscribirEntero
    call Crlf
    jmp RM_Fin

RM_ErrNum:
    mov edx, OFFSET errNumeroInvalido
    call WriteString
    jmp RM_PedirCantidad

RM_ErrCero:
    mov edx, OFFSET errCantidadPositiva
    call WriteString
    jmp RM_PedirCantidad

RM_ErrLimite:
    mov edx, OFFSET errExcedeStockMax
    call WriteString
    jmp RM_PedirCantidad

RM_Fin:
    ret
RecibirMercancia ENDP

; ============================================================================
; Procedimiento: VenderLibro
; Descripcion: Opcion 5. Comprueba existencias, calcula importe (precio * cant)
;              verificando desbordamiento, descuenta stock y suma ingresos.
; Entradas: Ninguna
; Salidas: Actualiza existencia, vendidos, ingresosSesion y hayCambios
; Registros modificados: EAX, EBX, ECX, EDX, ESI
; ============================================================================
VenderLibro PROC
    cmp numLibros, 0
    jne VL_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    ret

VL_Buscar:
    call SolicitarYBuscarCodigo
    cmp eax, -1
    je VL_Fin

    mov ebx, esi                        ; EBX = puntero al libro
    cmp (Libro PTR [ebx]).existencia, 0
    jne VL_PedirCantidad
    mov edx, OFFSET errSinExistencias
    call WriteString
    ret

VL_PedirCantidad:
    mov edx, OFFSET promptCantidadVen
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    call CadenaAEntero
    jc VL_ErrNum
    cmp eax, 0
    je VL_ErrCero
    cmp eax, (Libro PTR [ebx]).existencia
    ja VL_ErrStock

    mov ecx, eax                        ; ECX = cantidad a vender

    ; Calcular importe = precioCent * cantidad (verificar overflow)
    mov eax, (Libro PTR [ebx]).precioCent
    mul ecx                             ; EDX:EAX = precioCent * cantidad
    cmp edx, 0
    jne VL_ErrOverflow

    ; Verificar que ingresosSesion + importe no desborde 32 bits
    mov edx, ingresosSesion
    add edx, eax
    jc VL_ErrOverflow

    ; Aplicar cambios de forma atomica
    sub (Libro PTR [ebx]).existencia, ecx
    add (Libro PTR [ebx]).vendidos, ecx
    mov ingresosSesion, edx
    mov hayCambios, 1

    mov edx, OFFSET msgVentaExitosa
    call WriteString
    call EscribirCentavosMXN
    call Crlf
    jmp VL_Fin

VL_ErrNum:
    mov edx, OFFSET errNumeroInvalido
    call WriteString
    jmp VL_PedirCantidad

VL_ErrCero:
    mov edx, OFFSET errCantidadPositiva
    call WriteString
    jmp VL_PedirCantidad

VL_ErrStock:
    mov edx, OFFSET errStockInsuf
    call WriteString
    jmp VL_PedirCantidad

VL_ErrOverflow:
    mov edx, OFFSET errDesbordamiento
    call WriteString

VL_Fin:
    ret
VenderLibro ENDP

; ============================================================================
; Procedimiento: MostrarResumen
; Descripcion: Opcion 6. Presenta unidades disponibles, valor total del
;              inventario e ingresos acumulados de la sesion.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, EBX, ECX, EDX, ESI, EDI
; ============================================================================
MostrarResumen PROC
    mov edx, OFFSET msgResumenTit
    call WriteString

    xor ebx, ebx                        ; EBX = suma de unidades disponibles
    xor edi, edi                        ; EDI = valor total en centavos
    mov ecx, numLibros
    cmp ecx, 0
    je MR_Imprimir

    mov esi, OFFSET inventario

MR_Loop:
    mov eax, (Libro PTR [esi]).existencia
    add ebx, eax

    ; Subtotal = precioCent * existencia
    mul (Libro PTR [esi]).precioCent
    cmp edx, 0
    jne MR_Overflow
    add edi, eax
    jc MR_Overflow

    add esi, SIZEOF Libro
    dec ecx
    jnz MR_Loop
    jmp MR_Imprimir

MR_Overflow:
    mov edx, OFFSET errDesbordamiento
    call WriteString
    ret

MR_Imprimir:
    mov edx, OFFSET msgResLibros
    call WriteString
    mov eax, numLibros
    call EscribirEntero
    call Crlf

    mov edx, OFFSET msgResUnidades
    call WriteString
    mov eax, ebx
    call EscribirEntero
    call Crlf

    mov edx, OFFSET msgResValor
    call WriteString
    mov eax, edi
    call EscribirCentavosMXN
    call Crlf

    mov edx, OFFSET msgResIngresos
    call WriteString
    mov eax, ingresosSesion
    call EscribirCentavosMXN
    call Crlf
    ret
MostrarResumen ENDP

; ============================================================================
; Procedimiento: MostrarMasVendido
; Descripcion: Opcion 7. Recorre inventario con ESI para mostrar el libro con
;              mayor cantidad de unidades vendidas en la sesion.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, EBX, ECX, EDX, ESI
; ============================================================================
MostrarMasVendido PROC
    mov ecx, numLibros
    cmp ecx, 0
    jne MMV_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    ret

MMV_Buscar:
    mov esi, OFFSET inventario
    xor ebx, ebx                        ; Mayor cantidad vendida encontrada
    xor edx, edx                        ; Puntero al libro mas vendido

MMV_Loop:
    mov eax, (Libro PTR [esi]).vendidos
    cmp eax, ebx
    jbe MMV_Siguiente
    mov ebx, eax
    mov edx, esi

MMV_Siguiente:
    add esi, SIZEOF Libro
    dec ecx
    jnz MMV_Loop

    cmp ebx, 0
    jne MMV_Mostrar
    mov edx, OFFSET msgSinVentas
    call WriteString
    ret

MMV_Mostrar:
    push edx
    mov edx, OFFSET msgMasVendidoTit
    call WriteString
    pop esi
    call MostrarDetalleLibro
    ret
MostrarMasVendido ENDP

; ============================================================================
; Procedimiento: AgregarTextoABuffer
; Descripcion: Auxiliar para concatenar una cadena en bufferArchivo.
; Entradas: ESI = cadena origen, EDI = posicion actual en bufferArchivo
; Salidas: EDI actualizado apuntando al final (antes del 0)
; Registros modificados: EAX, EDI
; ============================================================================
AgregarTextoABuffer PROC
    push esi
ATB_Loop:
    mov al, [esi]
    cmp al, 0
    je ATB_Fin
    mov [edi], al
    inc esi
    inc edi
    jmp ATB_Loop
ATB_Fin:
    pop esi
    ret
AgregarTextoABuffer ENDP

; ============================================================================
; Procedimiento: GuardarInventario
; Descripcion: Opcion 8. Serializa los libros a bufferArchivo con formato:
;              CODIGO | NOMBRE | EXISTENCIA | $PRECIO MXN\r\n
;              y los guarda en Inventario.txt.
; Entradas: Ninguna
; Salidas: Archivo Inventario.txt actualizado; hayCambios = 0 si tiene exito
; Registros modificados: EAX, ECX, EDX, ESI, EDI
; ============================================================================
GuardarInventario PROC
    mov edi, OFFSET bufferArchivo
    mov ecx, numLibros
    cmp ecx, 0
    je GI_EscribirArchivo

    mov esi, OFFSET inventario

GI_Loop:
    push ecx
    push esi

    ; 1) Codigo
    call AgregarTextoABuffer

    ; Separador
    push esi
    mov esi, OFFSET msgSeparadorArch
    call AgregarTextoABuffer
    pop esi

    ; 2) Nombre
    push esi
    lea esi, (Libro PTR [esi]).nombre
    call AgregarTextoABuffer
    pop esi

    ; Separador
    push esi
    mov esi, OFFSET msgSeparadorArch
    call AgregarTextoABuffer
    pop esi

    ; 3) Existencia
    push edi
    mov eax, (Libro PTR [esi]).existencia
    mov edi, OFFSET bufferNumero
    call EnteroACadena
    pop edi
    push esi
    mov esi, OFFSET bufferNumero
    call AgregarTextoABuffer
    pop esi

    ; Separador
    push esi
    mov esi, OFFSET msgSeparadorArch
    call AgregarTextoABuffer
    pop esi

    ; 4) Precio en formato "$#,###.## MXN"
    push edi
    mov eax, (Libro PTR [esi]).precioCent
    mov edi, OFFSET bufferNumero
    call CentavosACadenaMXN
    pop edi
    push esi
    mov esi, OFFSET bufferNumero
    call AgregarTextoABuffer
    pop esi

    ; Salto de linea CRLF
    push esi
    mov esi, OFFSET msgSaltoLinea
    call AgregarTextoABuffer
    pop esi

    pop esi
    add esi, SIZEOF Libro
    pop ecx
    dec ecx
    jnz GI_Loop

GI_EscribirArchivo:
    mov BYTE PTR [edi], 0
    sub edi, OFFSET bufferArchivo
    mov bytesArchivo, edi

    mov edx, OFFSET nombreArchivo
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je GI_Error

    mov manejadorArchivo, eax
    mov edx, OFFSET bufferArchivo
    mov ecx, bytesArchivo
    call WriteToFile
    mov eax, manejadorArchivo
    call CloseFile

    mov hayCambios, 0
    mov edx, OFFSET msgGuardadoOk
    call WriteString
    ret

GI_Error:
    mov edx, OFFSET errArchivoCrear
    call WriteString
    ret
GuardarInventario ENDP

; ============================================================================
; Procedimiento: LeerCampoHastaPipeOCRLF
; Descripcion: Lee desde ESI hasta encontrar '|', CR (0Dh), LF (0Ah) o 0.
;              Recorta espacios al inicio y al final del campo.
; Entradas: ESI = cursor actual en bufferArchivo, EDI = buffer destino,
;           ECX = tamano maximo de destino (incluyendo 0)
; Salidas: ESI avanzado despues del delimitador (si es '|', despues de '|');
;          EAX = 1 si encontro '|', 0 si fin de linea/archivo
; Registros modificados: EAX, ESI
; ============================================================================
LeerCampoHastaPipeOCRLF PROC
    push ebx
    push ecx
    push edi

    mov ebx, edi                        ; Guardar inicio del destino
    dec ecx                             ; Espacio para terminador 0

    ; Saltar espacios iniciales
LCPO_SaltarEspInicio:
    mov al, [esi]
    cmp al, ' '
    jne LCPO_Copiar
    inc esi
    jmp LCPO_SaltarEspInicio

LCPO_Copiar:
    mov al, [esi]
    cmp al, 0
    je LCPO_FinLinea
    cmp al, 0Dh
    je LCPO_FinLinea
    cmp al, 0Ah
    je LCPO_FinLinea
    cmp al, '|'
    je LCPO_FinPipe

    cmp ecx, 0
    je LCPO_IgnorarExceso
    mov [edi], al
    inc edi
    dec ecx
LCPO_IgnorarExceso:
    inc esi
    jmp LCPO_Copiar

LCPO_FinPipe:
    inc esi                             ; Avanzar despues de '|'
    mov eax, 1
    jmp LCPO_TrimFinal

LCPO_FinLinea:
    xor eax, eax

LCPO_TrimFinal:
    cmp edi, ebx
    jbe LCPO_Terminar
    cmp BYTE PTR [edi - 1], ' '
    jne LCPO_Terminar
    dec edi
    jmp LCPO_TrimFinal

LCPO_Terminar:
    mov BYTE PTR [edi], 0

    pop edi
    pop ecx
    pop ebx
    ret
LeerCampoHastaPipeOCRLF ENDP

; ============================================================================
; Procedimiento: LimpiarPrecioArchivo
; Descripcion: Convierte "$1,599.99 MXN" a "1599.99" quitando '$', comas y
;              el sufijo " MXN" para validarlo con CadenaACentavos.
; Entradas: EDX = cadena origen, EDI = buffer destino
; Salidas: Cadena limpia en [EDI]
; Registros modificados: Ninguno
; ============================================================================
LimpiarPrecioArchivo PROC
    push eax
    push ecx
    push esi
    push edi

    mov esi, edx
    mov ecx, edi                        ; Guardar inicio de destino
LPA_Loop:
    mov al, [esi]
    cmp al, 0
    je LPA_Fin
    cmp al, '$'
    je LPA_Saltar
    cmp al, ','
    je LPA_Saltar
    cmp al, ' '
    jne LPA_Copiar
    cmp edi, ecx
    je LPA_Saltar                       ; Ignorar espacios antes del numero
    jmp LPA_Fin                         ; Cortar al llegar a " MXN"
LPA_Copiar:
    mov [edi], al
    inc edi
LPA_Saltar:
    inc esi
    jmp LPA_Loop

LPA_Fin:
    mov BYTE PTR [edi], 0
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
LimpiarPrecioArchivo ENDP

; ============================================================================
; Procedimiento: CargarDesdeArchivoBase
; Descripcion: Abre Inventario.txt, lee su contenido y reconstruye el arreglo
;              inventario validando limites y duplicados.
; Entradas: Ninguna
; Salidas: EAX = 0 si exito, 1 si no existe archivo, 2 si error de lectura/formato
; Registros modificados: EAX, EBX, ECX, EDX, ESI, EDI
; ============================================================================
CargarDesdeArchivoBase PROC
    mov edx, OFFSET nombreArchivo
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je CDAB_NoExiste

    mov manejadorArchivo, eax
    mov edx, OFFSET bufferArchivo
    mov ecx, TAM_BUFFER_ARCHIVO - 1
    call ReadFromFile
    jc CDAB_ErrLectura
    mov bytesArchivo, eax

    mov ebx, OFFSET bufferArchivo
    mov BYTE PTR [ebx + eax], 0

    mov eax, manejadorArchivo
    call CloseFile

    ; Reiniciar inventario en memoria antes de parsear
    mov numLibros, 0
    mov hayCambios, 0
    mov esi, OFFSET bufferArchivo

    ; Saltar BOM UTF-8 (EF BB BF) si el editor de texto lo agrego
    cmp bytesArchivo, 3
    jb CDAB_LineaLoop
    cmp BYTE PTR [esi], 0EFh
    jne CDAB_LineaLoop
    cmp BYTE PTR [esi + 1], 0BBh
    jne CDAB_LineaLoop
    cmp BYTE PTR [esi + 2], 0BFh
    jne CDAB_LineaLoop
    add esi, 3

CDAB_LineaLoop:
    ; Saltar CR/LF y espacios vacios entre lineas
    mov al, [esi]
    cmp al, 0
    je CDAB_Exito
    cmp al, 0Dh
    je CDAB_SaltarChar
    cmp al, 0Ah
    je CDAB_SaltarChar
    cmp al, ' '
    je CDAB_SaltarChar
    jmp CDAB_ParsearLinea

CDAB_SaltarChar:
    inc esi
    jmp CDAB_LineaLoop

CDAB_ParsearLinea:
    cmp numLibros, MAX_LIBROS
    jae CDAB_Exito

    ; 1) Codigo
    mov edi, OFFSET bufferCodigoTemp
    mov ecx, TAM_CODIGO
    call LeerCampoHastaPipeOCRLF
    cmp eax, 1
    jne CDAB_ErrFormato

    mov edx, OFFSET bufferCodigoTemp
    call ValidarFormatoCodigo
    jc CDAB_ErrFormato

    push esi
    mov edx, OFFSET bufferCodigoTemp
    call BuscarLibroPorCodigo
    pop esi
    cmp eax, -1
    jne CDAB_ErrFormato                 ; Rechazar codigo duplicado

    ; 2) Nombre
    mov edi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    call LeerCampoHastaPipeOCRLF
    cmp eax, 1
    jne CDAB_ErrFormato

    mov edx, OFFSET bufferNombreTemp
    call CadenaSoloEspacios
    cmp eax, 1
    je CDAB_ErrFormato

    ; 3) Existencia
    mov edi, OFFSET bufferNumero
    mov ecx, TAM_BUFFER_NUM
    call LeerCampoHastaPipeOCRLF
    cmp eax, 1
    jne CDAB_ErrFormato

    mov edx, OFFSET bufferNumero
    call CadenaAEntero
    jc CDAB_ErrFormato
    cmp eax, MAX_EXISTENCIA
    ja CDAB_ErrFormato
    push eax                            ; Guardar existencia

    ; 4) Precio
    mov edi, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call LeerCampoHastaPipeOCRLF

    mov edx, OFFSET bufferEntrada
    mov edi, OFFSET bufferNumero
    call LimpiarPrecioArchivo

    mov edx, OFFSET bufferNumero
    call CadenaACentavos
    jc CDAB_ErrFormatoPop1
    push eax                            ; Guardar precioCent

    ; Insertar libro en inventario[numLibros]
    push esi
    mov eax, numLibros
    mov ecx, SIZEOF Libro
    mul ecx
    mov esi, OFFSET inventario
    add esi, eax

    push esi
    mov edi, esi
    mov esi, OFFSET bufferCodigoTemp
    mov ecx, TAM_CODIGO
    call CopiarCadena
    pop esi

    push esi
    lea edi, (Libro PTR [esi]).nombre
    mov esi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    call CopiarCadena
    pop esi

    pop edx                             ; Recuperar cursor_archivo
    pop eax                             ; Recuperar precioCent
    pop ebx                             ; Recuperar existencia
    mov (Libro PTR [esi]).precioCent, eax
    mov (Libro PTR [esi]).existencia, ebx
    mov (Libro PTR [esi]).vendidos, 0
    mov esi, edx                        ; Restaurar cursor_archivo en ESI

    inc numLibros
    jmp CDAB_LineaLoop

CDAB_ErrFormatoPop1:
    pop eax
CDAB_ErrFormato:
    mov numLibros, 0
    mov eax, 2
    ret

CDAB_NoExiste:
    mov eax, 1
    ret

CDAB_ErrLectura:
    mov eax, manejadorArchivo
    call CloseFile
    mov eax, 2
    ret

CDAB_Exito:
    xor eax, eax
    ret
CargarDesdeArchivoBase ENDP

; ============================================================================
; Procedimiento: CargarInventarioSilencioso
; Descripcion: Intenta cargar Inventario.txt al iniciar el programa.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, EBX, ECX, EDX, ESI, EDI
; ============================================================================
CargarInventarioSilencioso PROC
    call CargarDesdeArchivoBase
    cmp eax, 0
    je CIS_Ok
    cmp eax, 1
    je CIS_SinArchivo
    mov edx, OFFSET errArchivoLeer
    call WriteString
    ret
CIS_Ok:
    mov edx, OFFSET msgCargadoOk
    call WriteString
    ret
CIS_SinArchivo:
    mov edx, OFFSET msgSinArchivo
    call WriteString
    ret
CargarInventarioSilencioso ENDP

; ============================================================================
; Procedimiento: PreguntarSiNo
; Descripcion: Solicita confirmacion S/N al usuario mediante ReadString.
; Entradas: EDX = mensaje de pregunta
; Salidas: EAX = 1 si 'S'/'s', 0 si 'N'/'n'
; Registros modificados: EAX, ECX
; ============================================================================
PreguntarSiNo PROC
    push edx
PSN_Loop:
    pop edx
    push edx
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    cmp eax, 1
    jne PSN_Err
    mov al, bufferEntrada[0]
    cmp al, 'S'
    je PSN_Si
    cmp al, 's'
    je PSN_Si
    cmp al, 'N'
    je PSN_No
    cmp al, 'n'
    je PSN_No

PSN_Err:
    mov edx, OFFSET errRespuestaSN
    call WriteString
    jmp PSN_Loop

PSN_Si:
    mov eax, 1
    jmp PSN_Fin
PSN_No:
    xor eax, eax
PSN_Fin:
    pop edx
    ret
PreguntarSiNo ENDP

; ============================================================================
; Procedimiento: CargarInventarioInteractivo
; Descripcion: Opcion 9. Si hay cambios sin guardar, pregunta si desea
;              guardarlos antes de recargar desde Inventario.txt.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, EBX, ECX, EDX, ESI, EDI
; ============================================================================
CargarInventarioInteractivo PROC
    cmp hayCambios, 1
    jne CII_Cargar
    mov edx, OFFSET promptConfirmarSN
    call PreguntarSiNo
    cmp eax, 1
    jne CII_Cargar
    call GuardarInventario

CII_Cargar:
    call CargarDesdeArchivoBase
    cmp eax, 0
    je CII_Ok
    cmp eax, 1
    je CII_NoExiste
    mov edx, OFFSET errArchivoLeer
    call WriteString
    ret
CII_Ok:
    mov edx, OFFSET msgCargadoOk
    call WriteString
    ret
CII_NoExiste:
    mov edx, OFFSET msgSinArchivo
    call WriteString
    ret
CargarInventarioInteractivo ENDP

; ============================================================================
; Procedimiento: ConfirmarSalida
; Descripcion: Avisa al salir si hay cambios sin guardar y permite guardarlos
;              en Inventario.txt antes de cerrar.
; Entradas: Ninguna
; Salidas: Ninguna
; Registros modificados: EAX, EBX, ECX, EDX, ESI, EDI
; ============================================================================
ConfirmarSalida PROC
    cmp hayCambios, 1
    jne CS_Fin
    mov edx, OFFSET promptGuardarSalir
    call PreguntarSiNo
    cmp eax, 1
    jne CS_Fin
    call GuardarInventario
CS_Fin:
    ret
ConfirmarSalida ENDP

END main
