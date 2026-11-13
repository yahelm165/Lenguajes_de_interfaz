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
    pad         BYTE 3 DUP(0)           ; 3 bytes de alineacion
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

; Punteros de retorno para subrutinas basadas en etiquetas
retLongitud         DWORD ?
retCopiar           DWORD ?
retComparar         DWORD ?
retSoloEsp          DWORD ?
retContPipe         DWORD ?
retCadAEnt          DWORD ?
retEntACad          DWORD ?
retEscEnt           DWORD ?
retCadACent         DWORD ?
retCentACad         DWORD ?
retEscCent          DWORD ?
retValCod           DWORD ?
retBuscar           DWORD ?
retGenCod           DWORD ?
retDetalle          DWORD ?
retEspacios         DWORD ?
retSolBuscar        DWORD ?
retAgrTxt           DWORD ?
retGuardar          DWORD ?
retLeerCampo        DWORD ?
retLimpPrecio       DWORD ?
retCargarBase       DWORD ?
retPregSN           DWORD ?

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
main PROC
    call Randomize

    ; Carga inicial silenciosa desde Inventario.txt
    mov retCargarBase, OFFSET Inicio_PostCarga
    jmp Rutina_CargarDesdeArchivoBase
Inicio_PostCarga:
    cmp eax, 0
    je Inicio_CargadoOk
    cmp eax, 1
    je Inicio_SinArchivo
    mov edx, OFFSET errArchivoLeer
    call WriteString
    jmp CicloMenu
Inicio_CargadoOk:
    mov edx, OFFSET msgCargadoOk
    call WriteString
    jmp CicloMenu
Inicio_SinArchivo:
    mov edx, OFFSET msgSinArchivo
    call WriteString

; ============================================================================
; Ciclo principal del menu
; ============================================================================
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

; ============================================================================
; Opcion 1: Registrar libro
; ============================================================================
OpRegistrar:
    mov eax, numLibros
    cmp eax, MAX_LIBROS
    jb RL_CapturarNombre
    mov edx, OFFSET errCapacidad
    call WriteString
    jmp CicloMenu

RL_CapturarNombre:
    mov edx, OFFSET promptNombre
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    mov retSoloEsp, OFFSET RL_PostSoloEsp
    jmp Rutina_CadenaSoloEspacios
RL_PostSoloEsp:
    cmp eax, 1
    jne RL_CheckPipe
    mov edx, OFFSET errDatoVacio
    call WriteString
    jmp RL_CapturarNombre

RL_CheckPipe:
    mov edx, OFFSET bufferEntrada
    mov retContPipe, OFFSET RL_PostCheckPipe
    jmp Rutina_ContienePipe
RL_PostCheckPipe:
    cmp eax, 0
    je RL_CopiarNombreTemp
    mov edx, OFFSET errCaracterPipe
    call WriteString
    jmp RL_CapturarNombre

RL_CopiarNombreTemp:
    mov esi, OFFSET bufferEntrada
    mov edi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    mov retCopiar, OFFSET RL_CapturarExistencia
    jmp Rutina_CopiarCadena

RL_CapturarExistencia:
    mov edx, OFFSET promptExistencia
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    mov retCadAEnt, OFFSET RL_PostExistencia
    jmp Rutina_CadenaAEntero
RL_PostExistencia:
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
    mov retCadACent, OFFSET RL_PostPrecio
    jmp Rutina_CadenaACentavos
RL_PostPrecio:
    jc RL_ErrPrecio
    push eax                            ; Guardar precioCent en pila
    jmp RL_GuardarRegistro

RL_ErrPrecio:
    mov edx, OFFSET errPrecioInvalido
    call WriteString
    jmp RL_CapturarPrecio

RL_GuardarRegistro:
    mov eax, numLibros
    mov ecx, SIZEOF Libro
    mul ecx
    mov esi, OFFSET inventario
    add esi, eax

    ; Generar codigo unico directamente en el registro
    lea edi, (Libro PTR [esi]).codigo
    mov retGenCod, OFFSET RL_PostGenCod
    jmp Rutina_GenerarCodigoUnico
RL_PostGenCod:

    ; Copiar nombre
    push esi
    lea edi, (Libro PTR [esi]).nombre
    mov esi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    mov retCopiar, OFFSET RL_PostCopNombre
    jmp Rutina_CopiarCadena
RL_PostCopNombre:
    pop esi

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
    jmp CicloMenu

; ============================================================================
; Opcion 2: Mostrar inventario
; ============================================================================
OpMostrar:
    mov ecx, numLibros
    cmp ecx, 0
    jne MI_ImprimirTabla
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    jmp CicloMenu

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
    mov retEspacios, OFFSET MI_PostEspCod
    jmp Rutina_EscribirEspacios
MI_PostEspCod:
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Nombre (alineado a 24 chars)
    lea edx, (Libro PTR [esi]).nombre
    call WriteString
    mov retLongitud, OFFSET MI_PostLenNom
    jmp Rutina_LongitudCadena
MI_PostLenNom:
    mov ecx, 24
    sub ecx, eax
    mov retEspacios, OFFSET MI_PostEspNom
    jmp Rutina_EscribirEspacios
MI_PostEspNom:
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Existencia (alineado a 5 chars)
    mov eax, (Libro PTR [esi]).existencia
    mov edi, OFFSET bufferNumero
    mov retEntACad, OFFSET MI_PostCadEx
    jmp Rutina_EnteroACadena
MI_PostCadEx:
    mov edx, OFFSET bufferNumero
    call WriteString
    mov retLongitud, OFFSET MI_PostLenEx
    jmp Rutina_LongitudCadena
MI_PostLenEx:
    mov ecx, 5
    sub ecx, eax
    mov retEspacios, OFFSET MI_PostEspEx
    jmp Rutina_EscribirEspacios
MI_PostEspEx:
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Vendidos (alineado a 4 chars)
    mov eax, (Libro PTR [esi]).vendidos
    mov edi, OFFSET bufferNumero
    mov retEntACad, OFFSET MI_PostCadVen
    jmp Rutina_EnteroACadena
MI_PostCadVen:
    mov edx, OFFSET bufferNumero
    call WriteString
    mov retLongitud, OFFSET MI_PostLenVen
    jmp Rutina_LongitudCadena
MI_PostLenVen:
    mov ecx, 4
    sub ecx, eax
    mov retEspacios, OFFSET MI_PostEspVen
    jmp Rutina_EscribirEspacios
MI_PostEspVen:
    mov edx, OFFSET msgSepCol
    call WriteString

    ; Precio formateado
    mov eax, (Libro PTR [esi]).precioCent
    mov retEscCent, OFFSET MI_PostPrecio
    jmp Rutina_EscribirCentavosMXN
MI_PostPrecio:
    call Crlf

    add esi, SIZEOF Libro
    pop ecx
    dec ecx
    jnz MI_Loop
    jmp CicloMenu

; ============================================================================
; Opcion 3: Buscar libro por codigo
; ============================================================================
OpBuscar:
    cmp numLibros, 0
    jne CL_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    jmp CicloMenu

CL_Buscar:
    mov retSolBuscar, OFFSET CL_PostBuscar
    jmp Rutina_SolicitarYBuscarCodigo
CL_PostBuscar:
    cmp eax, -1
    je CicloMenu
    call Crlf
    mov retDetalle, OFFSET CicloMenu
    jmp Rutina_MostrarDetalleLibro

; ============================================================================
; Opcion 4: Recibir mercancia
; ============================================================================
OpRecibir:
    cmp numLibros, 0
    jne RM_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    jmp CicloMenu

RM_Buscar:
    mov retSolBuscar, OFFSET RM_PostBuscar
    jmp Rutina_SolicitarYBuscarCodigo
RM_PostBuscar:
    cmp eax, -1
    je CicloMenu

    mov ebx, esi                        ; EBX = puntero al libro

RM_PedirCantidad:
    mov edx, OFFSET promptCantidadRec
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    mov retCadAEnt, OFFSET RM_PostCant
    jmp Rutina_CadenaAEntero
RM_PostCant:
    jc RM_ErrNum
    cmp eax, 0
    je RM_ErrCero

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
    mov retEscEnt, OFFSET RM_PostEsc
    jmp Rutina_EscribirEntero
RM_PostEsc:
    call Crlf
    jmp CicloMenu

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

; ============================================================================
; Opcion 5: Vender libro
; ============================================================================
OpVender:
    cmp numLibros, 0
    jne VL_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    jmp CicloMenu

VL_Buscar:
    mov retSolBuscar, OFFSET VL_PostBuscar
    jmp Rutina_SolicitarYBuscarCodigo
VL_PostBuscar:
    cmp eax, -1
    je CicloMenu

    mov ebx, esi                        ; EBX = puntero al libro
    cmp (Libro PTR [ebx]).existencia, 0
    jne VL_PedirCantidad
    mov edx, OFFSET errSinExistencias
    call WriteString
    jmp CicloMenu

VL_PedirCantidad:
    mov edx, OFFSET promptCantidadVen
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString

    mov edx, OFFSET bufferEntrada
    mov retCadAEnt, OFFSET VL_PostCant
    jmp Rutina_CadenaAEntero
VL_PostCant:
    jc VL_ErrNum
    cmp eax, 0
    je VL_ErrCero
    cmp eax, (Libro PTR [ebx]).existencia
    ja VL_ErrStock

    mov ecx, eax                        ; ECX = cantidad a vender
    mov eax, (Libro PTR [ebx]).precioCent
    mul ecx                             ; EDX:EAX = precioCent * cantidad
    cmp edx, 0
    jne VL_ErrOverflow

    mov edx, ingresosSesion
    add edx, eax
    jc VL_ErrOverflow

    ; Actualizacion atomica
    sub (Libro PTR [ebx]).existencia, ecx
    add (Libro PTR [ebx]).vendidos, ecx
    mov ingresosSesion, edx
    mov hayCambios, 1

    mov edx, OFFSET msgVentaExitosa
    call WriteString
    mov retEscCent, OFFSET VL_PostEsc
    jmp Rutina_EscribirCentavosMXN
VL_PostEsc:
    call Crlf
    jmp CicloMenu

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
    jmp CicloMenu

; ============================================================================
; Opcion 6: Mostrar resumen
; ============================================================================
OpResumen:
    mov edx, OFFSET msgResumenTit
    call WriteString

    xor ebx, ebx                        ; EBX = unidades disponibles
    xor edi, edi                        ; EDI = valor total en centavos
    mov ecx, numLibros
    cmp ecx, 0
    je MR_Imprimir

    mov esi, OFFSET inventario

MR_Loop:
    mov eax, (Libro PTR [esi]).existencia
    add ebx, eax

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
    jmp CicloMenu

MR_Imprimir:
    mov edx, OFFSET msgResLibros
    call WriteString
    mov eax, numLibros
    mov retEscEnt, OFFSET MR_PostLib
    jmp Rutina_EscribirEntero
MR_PostLib:
    call Crlf

    mov edx, OFFSET msgResUnidades
    call WriteString
    mov eax, ebx
    mov retEscEnt, OFFSET MR_PostUni
    jmp Rutina_EscribirEntero
MR_PostUni:
    call Crlf

    mov edx, OFFSET msgResValor
    call WriteString
    mov eax, edi
    mov retEscCent, OFFSET MR_PostVal
    jmp Rutina_EscribirCentavosMXN
MR_PostVal:
    call Crlf

    mov edx, OFFSET msgResIngresos
    call WriteString
    mov eax, ingresosSesion
    mov retEscCent, OFFSET MR_PostIng
    jmp Rutina_EscribirCentavosMXN
MR_PostIng:
    call Crlf
    jmp CicloMenu

; ============================================================================
; Opcion 7: Mostrar libro mas vendido
; ============================================================================
OpMasVendido:
    mov ecx, numLibros
    cmp ecx, 0
    jne MMV_Buscar
    mov edx, OFFSET msgCatalogoVacio
    call WriteString
    jmp CicloMenu

MMV_Buscar:
    mov esi, OFFSET inventario
    xor ebx, ebx                        ; Mayor vendido
    xor edx, edx                        ; Puntero al libro

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
    jmp CicloMenu

MMV_Mostrar:
    push edx
    mov edx, OFFSET msgMasVendidoTit
    call WriteString
    pop esi
    mov retDetalle, OFFSET CicloMenu
    jmp Rutina_MostrarDetalleLibro

; ============================================================================
; Opcion 8: Guardar inventario
; ============================================================================
OpGuardar:
    mov retGuardar, OFFSET CicloMenu
    jmp Rutina_GuardarInventario

; ============================================================================
; Opcion 9: Cargar inventario desde archivo
; ============================================================================
OpCargar:
    cmp hayCambios, 1
    jne CII_Cargar
    mov edx, OFFSET promptConfirmarSN
    mov retPregSN, OFFSET CII_PostPreg
    jmp Rutina_PreguntarSiNo
CII_PostPreg:
    cmp eax, 1
    jne CII_Cargar
    mov retGuardar, OFFSET CII_Cargar
    jmp Rutina_GuardarInventario

CII_Cargar:
    mov retCargarBase, OFFSET CII_PostCargar
    jmp Rutina_CargarDesdeArchivoBase
CII_PostCargar:
    cmp eax, 0
    je CII_Ok
    cmp eax, 1
    je CII_NoExiste
    mov edx, OFFSET errArchivoLeer
    call WriteString
    jmp CicloMenu
CII_Ok:
    mov edx, OFFSET msgCargadoOk
    call WriteString
    jmp CicloMenu
CII_NoExiste:
    mov edx, OFFSET msgSinArchivo
    call WriteString
    jmp CicloMenu

; ============================================================================
; Opcion 0: Salir
; ============================================================================
OpSalir:
    cmp hayCambios, 1
    jne FinPrograma
    mov edx, OFFSET promptGuardarSalir
    mov retPregSN, OFFSET CS_PostPreg
    jmp Rutina_PreguntarSiNo
CS_PostPreg:
    cmp eax, 1
    jne FinPrograma
    mov retGuardar, OFFSET FinPrograma
    jmp Rutina_GuardarInventario

FinPrograma:
    mov edx, OFFSET msgDespedida
    call WriteString
    exit

; ============================================================================
; SUBRUTINAS INTERNAS POR ETIQUETAS (sin PROC/ENDP ni MACRO/ENDM)
; ============================================================================

; --- LongitudCadena: EDX = cadena -> EAX = longitud ---
Rutina_LongitudCadena:
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
    jmp retLongitud

; --- CopiarCadena: ESI = origen, EDI = destino, ECX = max bytes ---
Rutina_CopiarCadena:
    push eax
    push ecx
    push esi
    push edi
    cmp ecx, 0
    je CC_Fin
    dec ecx
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
    jmp retCopiar

; --- CompararCadenas: ESI = s1, EDI = s2 -> EAX = 1 igual, 0 distinta ---
Rutina_CompararCadenas:
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
    jmp retComparar

; --- CadenaSoloEspacios: EDX = cadena -> EAX = 1 vacia/espacios, 0 texto ---
Rutina_CadenaSoloEspacios:
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
    jmp retSoloEsp

; --- ContienePipe: EDX = cadena -> EAX = 1 si tiene '|', 0 si no ---
Rutina_ContienePipe:
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
    jmp retContPipe

; --- CadenaAEntero: EDX = cadena -> EAX = valor, CF=0 ok / CF=1 error ---
Rutina_CadenaAEntero:
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
    mul ecx
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
    jmp retCadAEnt

; --- EnteroACadena: EAX = entero, EDI = buffer destino ---
Rutina_EnteroACadena:
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
    div ebx
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
    jmp retEntACad

; --- EscribirEntero: EAX = entero ---
Rutina_EscribirEntero:
    push edx
    push edi
    mov edi, OFFSET bufferNumero
    mov retEntACad, OFFSET EE_PostConv
    jmp Rutina_EnteroACadena
EE_PostConv:
    mov edx, OFFSET bufferNumero
    call WriteString
    pop edi
    pop edx
    jmp retEscEnt

; --- CadenaACentavos: EDX = cadena -> EAX = centavos, CF=0 ok / CF=1 error ---
Rutina_CadenaACentavos:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, edx
    cmp BYTE PTR [esi], 0
    je CAC_Error
    xor eax, eax
    xor ecx, ecx
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
    cmp eax, 9999
    ja CAC_Error
    inc ecx
    inc esi
    jmp CAC_EnteraLoop
CAC_FinEnteraSinPunto:
    cmp ecx, 0
    je CAC_Error
    imul eax, 100
    jmp CAC_ValidarRango
CAC_Punto:
    cmp ecx, 0
    je CAC_Error
    inc esi
    mov bl, [esi]
    cmp bl, '0'
    jb CAC_Error
    cmp bl, '9'
    ja CAC_Error
    sub bl, '0'
    movzx ebx, bl
    imul ebx, 10
    inc esi
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
    jmp retCadACent

; --- CentavosACadenaMXN: EAX = centavos, EDI = buffer destino ---
Rutina_CentavosACadenaMXN:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ebx, 100
    xor edx, edx
    div ebx
    push edx
    xor ecx, ecx
    xor esi, esi
    cmp eax, 0
    jne CCM_LoopEntera
    push '0'
    inc ecx
    jmp CCM_EscribirPrefijo
CCM_LoopEntera:
    xor edx, edx
    mov ebx, 10
    div ebx
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
    pop eax
    xor edx, edx
    mov ebx, 10
    div ebx
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
    jmp retCentACad

; --- EscribirCentavosMXN: EAX = centavos ---
Rutina_EscribirCentavosMXN:
    push edx
    push edi
    mov edi, OFFSET bufferNumero
    mov retCentACad, OFFSET ECM_PostConv
    jmp Rutina_CentavosACadenaMXN
ECM_PostConv:
    mov edx, OFFSET bufferNumero
    call WriteString
    pop edi
    pop edx
    jmp retEscCent

; --- ValidarFormatoCodigo: EDX = codigo -> CF=0 ok / CF=1 error ---
Rutina_ValidarFormatoCodigo:
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
    jmp retValCod

; --- BuscarLibroPorCodigo: EDX = codigo -> EAX = indice/-1, ESI = ptr ---
Rutina_BuscarLibroPorCodigo:
    push ebx
    push ecx
    push edi
    mov ecx, numLibros
    cmp ecx, 0
    je BLC_NoEncontrado
    mov esi, OFFSET inventario
    xor ebx, ebx
BLC_Loop:
    push esi
    mov edi, edx
    mov retComparar, OFFSET BLC_PostCmp
    jmp Rutina_CompararCadenas
BLC_PostCmp:
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
    jmp retBuscar

; --- GenerarCodigoUnico: EDI = buffer destino (8 bytes) ---
Rutina_GenerarCodigoUnico:
    push eax
    push ecx
    push edx
    push esi
    push edi
GCU_Intentar:
    mov esi, edi
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
    mov edx, edi
    mov retBuscar, OFFSET GCU_PostBuscar
    jmp Rutina_BuscarLibroPorCodigo
GCU_PostBuscar:
    cmp eax, -1
    jne GCU_Intentar
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    jmp retGenCod

; --- MostrarDetalleLibro: ESI = ptr al Libro ---
Rutina_MostrarDetalleLibro:
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
    mov retEscEnt, OFFSET MDL_PostEx
    jmp Rutina_EscribirEntero
MDL_PostEx:
    call Crlf
    mov edx, OFFSET msgLblPrecio
    call WriteString
    mov eax, (Libro PTR [esi]).precioCent
    mov retEscCent, OFFSET MDL_PostPre
    jmp Rutina_EscribirCentavosMXN
MDL_PostPre:
    call Crlf
    mov edx, OFFSET msgLblVendidos
    call WriteString
    mov eax, (Libro PTR [esi]).vendidos
    mov retEscEnt, OFFSET MDL_PostVen
    jmp Rutina_EscribirEntero
MDL_PostVen:
    call Crlf
    pop edx
    pop eax
    jmp retDetalle

; --- EscribirEspacios: ECX = cantidad ---
Rutina_EscribirEspacios:
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
    jmp retEspacios

; --- SolicitarYBuscarCodigo -> EAX = indice/-1, ESI = ptr ---
Rutina_SolicitarYBuscarCodigo:
    mov edx, OFFSET promptCodigo
    call WriteString
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    call ReadString
    mov edx, OFFSET bufferEntrada
    mov retValCod, OFFSET SYB_PostVal
    jmp Rutina_ValidarFormatoCodigo
SYB_PostVal:
    jc SYB_FormatoInv
    mov edx, OFFSET bufferEntrada
    mov retBuscar, OFFSET SYB_PostBuscar
    jmp Rutina_BuscarLibroPorCodigo
SYB_PostBuscar:
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
    jmp retSolBuscar

; --- AgregarTextoABuffer: ESI = origen, EDI = cursor destino ---
Rutina_AgregarTextoABuffer:
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
    jmp retAgrTxt

; --- GuardarInventario ---
Rutina_GuardarInventario:
    mov edi, OFFSET bufferArchivo
    mov ecx, numLibros
    cmp ecx, 0
    je GI_EscribirArchivo
    mov esi, OFFSET inventario
GI_Loop:
    push ecx
    push esi
    mov retAgrTxt, OFFSET GI_PostCod
    jmp Rutina_AgregarTextoABuffer
GI_PostCod:
    push esi
    mov esi, OFFSET msgSeparadorArch
    mov retAgrTxt, OFFSET GI_PostSep1
    jmp Rutina_AgregarTextoABuffer
GI_PostSep1:
    pop esi
    push esi
    lea esi, (Libro PTR [esi]).nombre
    mov retAgrTxt, OFFSET GI_PostNom
    jmp Rutina_AgregarTextoABuffer
GI_PostNom:
    pop esi
    push esi
    mov esi, OFFSET msgSeparadorArch
    mov retAgrTxt, OFFSET GI_PostSep2
    jmp Rutina_AgregarTextoABuffer
GI_PostSep2:
    pop esi
    push edi
    mov eax, (Libro PTR [esi]).existencia
    mov edi, OFFSET bufferNumero
    mov retEntACad, OFFSET GI_PostEnt
    jmp Rutina_EnteroACadena
GI_PostEnt:
    pop edi
    push esi
    mov esi, OFFSET bufferNumero
    mov retAgrTxt, OFFSET GI_PostEx
    jmp Rutina_AgregarTextoABuffer
GI_PostEx:
    pop esi
    push esi
    mov esi, OFFSET msgSeparadorArch
    mov retAgrTxt, OFFSET GI_PostSep3
    jmp Rutina_AgregarTextoABuffer
GI_PostSep3:
    pop esi
    push edi
    mov eax, (Libro PTR [esi]).precioCent
    mov edi, OFFSET bufferNumero
    mov retCentACad, OFFSET GI_PostCent
    jmp Rutina_CentavosACadenaMXN
GI_PostCent:
    pop edi
    push esi
    mov esi, OFFSET bufferNumero
    mov retAgrTxt, OFFSET GI_PostPre
    jmp Rutina_AgregarTextoABuffer
GI_PostPre:
    pop esi
    push esi
    mov esi, OFFSET msgSaltoLinea
    mov retAgrTxt, OFFSET GI_PostCRLF
    jmp Rutina_AgregarTextoABuffer
GI_PostCRLF:
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
    jmp retGuardar
GI_Error:
    mov edx, OFFSET errArchivoCrear
    call WriteString
    jmp retGuardar

; --- LeerCampoHastaPipeOCRLF: ESI = cursor, EDI = dst, ECX = max -> EAX = 1/0 ---
Rutina_LeerCampoHastaPipeOCRLF:
    push ebx
    push ecx
    push edi
    mov ebx, edi
    dec ecx
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
    inc esi
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
    jmp retLeerCampo

; --- LimpiarPrecioArchivo: EDX = origen, EDI = destino ---
Rutina_LimpiarPrecioArchivo:
    push eax
    push ecx
    push esi
    push edi
    mov esi, edx
    mov ecx, edi
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
    je LPA_Saltar
    jmp LPA_Fin
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
    jmp retLimpPrecio

; --- CargarDesdeArchivoBase -> EAX = 0 ok, 1 no existe, 2 error ---
Rutina_CargarDesdeArchivoBase:
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
    mov numLibros, 0
    mov hayCambios, 0
    mov esi, OFFSET bufferArchivo
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
    mov retLeerCampo, OFFSET CDAB_PostCod
    jmp Rutina_LeerCampoHastaPipeOCRLF
CDAB_PostCod:
    cmp eax, 1
    jne CDAB_ErrFormato
    mov edx, OFFSET bufferCodigoTemp
    mov retValCod, OFFSET CDAB_PostValCod
    jmp Rutina_ValidarFormatoCodigo
CDAB_PostValCod:
    jc CDAB_ErrFormato
    push esi
    mov edx, OFFSET bufferCodigoTemp
    mov retBuscar, OFFSET CDAB_PostDup
    jmp Rutina_BuscarLibroPorCodigo
CDAB_PostDup:
    pop esi
    cmp eax, -1
    jne CDAB_ErrFormato

    ; 2) Nombre
    mov edi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    mov retLeerCampo, OFFSET CDAB_PostNom
    jmp Rutina_LeerCampoHastaPipeOCRLF
CDAB_PostNom:
    cmp eax, 1
    jne CDAB_ErrFormato
    mov edx, OFFSET bufferNombreTemp
    mov retSoloEsp, OFFSET CDAB_PostEspNom
    jmp Rutina_CadenaSoloEspacios
CDAB_PostEspNom:
    cmp eax, 1
    je CDAB_ErrFormato

    ; 3) Existencia
    mov edi, OFFSET bufferNumero
    mov ecx, TAM_BUFFER_NUM
    mov retLeerCampo, OFFSET CDAB_PostEx
    jmp Rutina_LeerCampoHastaPipeOCRLF
CDAB_PostEx:
    cmp eax, 1
    jne CDAB_ErrFormato
    mov edx, OFFSET bufferNumero
    mov retCadAEnt, OFFSET CDAB_PostExNum
    jmp Rutina_CadenaAEntero
CDAB_PostExNum:
    jc CDAB_ErrFormato
    cmp eax, MAX_EXISTENCIA
    ja CDAB_ErrFormato
    push eax

    ; 4) Precio
    mov edi, OFFSET bufferEntrada
    mov ecx, TAM_BUFFER_ENTRADA
    mov retLeerCampo, OFFSET CDAB_PostPre
    jmp Rutina_LeerCampoHastaPipeOCRLF
CDAB_PostPre:
    mov edx, OFFSET bufferEntrada
    mov edi, OFFSET bufferNumero
    mov retLimpPrecio, OFFSET CDAB_PostLimp
    jmp Rutina_LimpiarPrecioArchivo
CDAB_PostLimp:
    mov edx, OFFSET bufferNumero
    mov retCadACent, OFFSET CDAB_PostCent
    jmp Rutina_CadenaACentavos
CDAB_PostCent:
    jc CDAB_ErrFormatoPop1
    push eax

    ; Insertar en inventario[numLibros]
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
    mov retCopiar, OFFSET CDAB_PostCopCod
    jmp Rutina_CopiarCadena
CDAB_PostCopCod:
    pop esi

    push esi
    lea edi, (Libro PTR [esi]).nombre
    mov esi, OFFSET bufferNombreTemp
    mov ecx, TAM_NOMBRE
    mov retCopiar, OFFSET CDAB_PostCopNom
    jmp Rutina_CopiarCadena
CDAB_PostCopNom:
    pop esi

    pop edx
    pop eax
    pop ebx
    mov (Libro PTR [esi]).precioCent, eax
    mov (Libro PTR [esi]).existencia, ebx
    mov (Libro PTR [esi]).vendidos, 0
    mov esi, edx

    inc numLibros
    jmp CDAB_LineaLoop

CDAB_ErrFormatoPop1:
    pop eax
CDAB_ErrFormato:
    mov numLibros, 0
    mov eax, 2
    jmp retCargarBase
CDAB_NoExiste:
    mov eax, 1
    jmp retCargarBase
CDAB_ErrLectura:
    mov eax, manejadorArchivo
    call CloseFile
    mov eax, 2
    jmp retCargarBase
CDAB_Exito:
    xor eax, eax
    jmp retCargarBase

; --- PreguntarSiNo: EDX = pregunta -> EAX = 1 si S, 0 si N ---
Rutina_PreguntarSiNo:
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
    jmp retPregSN

main ENDP
END main
