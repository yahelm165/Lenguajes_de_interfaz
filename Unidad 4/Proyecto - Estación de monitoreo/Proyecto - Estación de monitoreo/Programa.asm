; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales
; Proyecto final de la unidad 4: Estacion de Monitoreo de Temperatura por USB.

; Monitorea periodicamente las unidades logicas de Windows mediante GetLogicalDrives. Cuando detecta una unidad
; USB nueva (tenga o no los archivos), o una unidad con "sensor.ini" en su raiz, lee el sitio y el intervalo,
; abre "lecturas.csv", muestra cada lectura en una posicion fija de la consola con colores por estado, y guarda
; los resultados en "resultados.csv" en la misma memoria USB.

INCLUDE Irvine32.inc

GetLogicalDrives PROTO STDCALL

; Constantes de configuracion.
FILA_ESTADO     = 5
ANCHO_ESTADO    = 76
MAX_LECTURAS    = 500
MAX_TEMP_LEN    = 16
TAM_BUFFER_INI  = 4096
TAM_BUFFER_CSV  = 16384
TAM_BUFFER_OUT  = 32768
TIEMPO_SONDEO   = 300
TIEMPO_ESTADO   = 900

; Colores de la consola para no estar declarandolos cada vez que los utilizo.
COLOR_ESPERA    = lightGray  + (black * 16)
COLOR_DETECTADA = cyan       + (black * 16)
COLOR_LEYENDO   = white      + (blue  * 16)
COLOR_LECTURA   = lightGreen + (black * 16)
COLOR_EXITO     = lightGreen + (black * 16)
COLOR_ERROR     = lightRed   + (black * 16)

.data
; Interfaz de la consola.
banner1         BYTE "  ESTACION DE MONITOREO DE TEMPERATURA (USB)", 0
banner2         BYTE "  Presione ESC para salir del programa", 0

; Mensajes de estado.
msgEsperando    BYTE "Esperando memoria USB...", 0
msgPrefijoUsb   BYTE "USB detectada: ", 0
msgSufijoUnidad BYTE ":\", 0
msgLeyendo      BYTE "Leyendo archivo...", 0
msgPrefijoLect  BYTE "Lectura ", 0
msgDosPuntos    BYTE ": ", 0
msgSufijoGrados BYTE " C", 0
msgTerminado    BYTE "Proceso terminado. Puede retirar la USB", 0
msgErrIni       BYTE "Error al abrir sensor.ini", 0
msgErrCsv       BYTE "Error al abrir lecturas.csv", 0
msgErrOut       BYTE "Error al escribir resultados.csv", 0
msgErrDrives    BYTE "No se pudieron consultar las unidades", 0

;  Rutas dinamicas en la raiz de la unidad detectada 
rutaIni         BYTE "A:\sensor.ini", 0
rutaCsv         BYTE "A:\lecturas.csv", 0
rutaOut         BYTE "A:\resultados.csv", 0

;  Claves de sensor.ini y encabezado de salida 
claveSitio      BYTE "SITIO=", 0
claveIntervalo  BYTE "INTERVALO_MS=", 0
encabezadoOut   BYTE "sitio,numero,temperatura_c", 13, 10, 0
sitioDefecto    BYTE "Sitio_Desconocido", 0

;  Variables de control de unidades 
mascaraActual   DWORD 0
mascaraPrevia   DWORD 0
mascaraTrabajo  DWORD 0
bitUnidadActiva DWORD 0
letraUnidad     BYTE 'A'
teclaEscSalir   BYTE 0

;  Configuracion de sesion 
nombreSitio     BYTE 64 DUP(0)
intervaloMs     DWORD 1000

; Variables de archivos
hArchivo        DWORD INVALID_HANDLE_VALUE
bytesLeidos     DWORD 0
bytesEscritos   DWORD 0
totalBytesOut   DWORD 0
numLecturas     DWORD 0

;  Buffers 
msgEstadoTemp   BYTE 128 DUP(0)
bufferIni       BYTE TAM_BUFFER_INI DUP(0)
bufferCsv       BYTE TAM_BUFFER_CSV DUP(0)
bufferOut       BYTE TAM_BUFFER_OUT DUP(0)
lecturas        BYTE (MAX_LECTURAS * MAX_TEMP_LEN) DUP(0)

.code
; main - Ciclo principal de la estacion de monitoreo
main PROC
    call DibujarEncabezado

    mov edx, OFFSET msgEsperando
    mov al, COLOR_ESPERA
    call MostrarEstado

    ; Registrar mascara inicial para distinguir unidades nuevas (ej. ignorar C: y D:)
    invoke GetLogicalDrives
    mov mascaraPrevia, eax

cicloEspera:
    call VerificarEsc
    cmp teclaEscSalir, 1
    je finalizarPrograma

    ; Consultar mascara de bits de unidades disponibles
    invoke GetLogicalDrives
    cmp eax, 0
    je errorConsultaUnidades

    mov mascaraActual, eax

    ; Actualizar bits retirados para permitir detectar futuras reconexiones
    mov edx, mascaraPrevia
    and edx, mascaraActual
    mov mascaraPrevia, edx

    ; Detectar unidades nuevas: mascaraActual AND (NOT mascaraPrevia)
    mov eax, mascaraPrevia
    not eax
    and eax, mascaraActual
    cmp eax, 0
    jz buscarPerfilExistente            ; Si no hay unidad nueva, revisar si alguna ya conectada tiene sensor.ini

    mov mascaraTrabajo, eax
    mov letraUnidad, 'A'
    mov ebx, 1                          ; Mascara del bit actual (bit 0 = A:)

revisarUnidadNueva:
    test mascaraTrabajo, 1
    jz siguienteUnidadNueva

    ; Se detecto una nueva unidad USB (aunque no tenga sensor.ini ni lecturas.csv)
    mov eax, mascaraActual
    mov mascaraPrevia, eax
    mov bitUnidadActiva, ebx

    mov al, letraUnidad
    mov rutaIni[0], al
    mov rutaCsv[0], al
    mov rutaOut[0], al

    ; Intentar abrir sensor.ini en la raiz de la unidad nueva
    invoke CreateFile, OFFSET rutaIni, GENERIC_READ, FILE_SHARE_READ, NULL, \
                       OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE
    je usbSinPerfil

    mov hArchivo, eax
    call ProcesarSesionUSB
    cmp teclaEscSalir, 1
    je finalizarPrograma
    jmp esperarRetiro

usbSinPerfil:
    ; Mostrar que la USB fue detectada aunque falte sensor.ini / lecturas.csv
    mov edi, OFFSET msgEstadoTemp
    mov esi, OFFSET msgPrefijoUsb
    call CopiarCadena
    mov al, letraUnidad
    mov [edi], al
    inc edi
    mov esi, OFFSET msgSufijoUnidad
    call CopiarCadena
    mov BYTE PTR [edi], 0

    mov edx, OFFSET msgEstadoTemp
    mov al, COLOR_DETECTADA
    call MostrarEstado

    mov eax, TIEMPO_ESTADO
    call EsperarConEsc
    cmp teclaEscSalir, 1
    je finalizarPrograma

    mov edx, OFFSET msgErrIni
    mov al, COLOR_ERROR
    call MostrarEstado
    jmp esperarRetiro

siguienteUnidadNueva:
    shr mascaraTrabajo, 1
    shl ebx, 1
    inc letraUnidad
    cmp letraUnidad, 'Z'
    jbe revisarUnidadNueva

buscarPerfilExistente:
    ; Si ya habia una USB conectada antes de iniciar el programa con sensor.ini, detectarla tambien
    mov eax, mascaraActual
    mov mascaraTrabajo, eax
    mov letraUnidad, 'A'
    mov ebx, 1

revisarUnidad:
    test mascaraTrabajo, 1
    jz siguienteUnidad

    ; Construir rutas para la letra actual
    mov al, letraUnidad
    mov rutaIni[0], al
    mov rutaCsv[0], al
    mov rutaOut[0], al

    ; Verificar si existe sensor.ini en la raiz de la unidad
    invoke CreateFile, OFFSET rutaIni, GENERIC_READ, FILE_SHARE_READ, NULL, \
                       OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE
    je siguienteUnidad                  ; Carece de perfil: seguir buscando

    ; Se encontro sensor.ini: iniciar sesion unica para esta conexion
    mov hArchivo, eax
    mov bitUnidadActiva, ebx

    call ProcesarSesionUSB
    cmp teclaEscSalir, 1
    je finalizarPrograma

    ; Mantener estado final o de error hasta que se retire la USB
esperarRetiro:
    call VerificarEsc
    cmp teclaEscSalir, 1
    je finalizarPrograma

    invoke GetLogicalDrives
    cmp eax, 0
    je esperarRetiroPausa

    test eax, bitUnidadActiva
    jnz esperarRetiroPausa

    ; La memoria fue retirada: limpiar estado y volver a esperar
    mov mascaraPrevia, eax
    mov bitUnidadActiva, 0
    mov edx, OFFSET msgEsperando
    mov al, COLOR_ESPERA
    call MostrarEstado
    jmp cicloEspera

esperarRetiroPausa:
    mov eax, TIEMPO_SONDEO
    call EsperarConEsc
    cmp teclaEscSalir, 1
    je finalizarPrograma
    jmp esperarRetiro

siguienteUnidad:
    shr mascaraTrabajo, 1
    shl ebx, 1
    inc letraUnidad
    cmp letraUnidad, 'Z'
    jbe revisarUnidad

    ; Ninguna unidad detectada: esperar y volver a sondear
    mov eax, TIEMPO_SONDEO
    call EsperarConEsc
    jmp cicloEspera

errorConsultaUnidades:
    mov edx, OFFSET msgErrDrives
    mov al, COLOR_ERROR
    call MostrarEstado
    mov eax, TIEMPO_SONDEO
    call EsperarConEsc
    jmp cicloEspera

finalizarPrograma:
    mov eax, COLOR_ESPERA
    call SetTextColor
    mov dl, 0
    mov dh, 7
    call Gotoxy
    exit
main ENDP

; ProcesarSesionUSB
; Ejecuta el flujo completo de una sesion cuando hArchivo tiene abierto sensor.ini. Cierra siempre los archivos 
; abiertos antes de retornar.

ProcesarSesionUSB PROC
    ;  1. Leer y parsear sensor.ini 
    mov bytesLeidos, 0
    invoke ReadFile, hArchivo, OFFSET bufferIni, TAM_BUFFER_INI - 1, \
                     OFFSET bytesLeidos, NULL
    push eax
    invoke CloseHandle, hArchivo
    mov hArchivo, INVALID_HANDLE_VALUE
    pop eax

    cmp eax, 0
    je falloLecturaIni
    mov ecx, bytesLeidos
    mov bufferIni[ecx], 0               ; Terminar en NUL segun bytes entregados

    call ParsearSensorIni
    jmp mostrarDetectada

falloLecturaIni:
    ; Valores por defecto si ReadFile fallo
    mov edi, OFFSET nombreSitio
    mov esi, OFFSET sitioDefecto
    call CopiarCadena
    mov BYTE PTR [edi], 0
    mov intervaloMs, 1000

mostrarDetectada:
    ;  2. Mostrar: USB detectada: <SITIO>. (cian sobre negro) 
    mov edi, OFFSET msgEstadoTemp
    mov esi, OFFSET msgPrefijoUsb
    call CopiarCadena
    mov esi, OFFSET nombreSitio
    call CopiarCadena
    mov BYTE PTR [edi], '.'
    mov BYTE PTR [edi + 1], 0

    mov edx, OFFSET msgEstadoTemp
    mov al, COLOR_DETECTADA
    call MostrarEstado

    mov eax, TIEMPO_ESTADO
    call EsperarConEsc
    cmp teclaEscSalir, 1
    je salirSesion

    ;  3. Abrir y leer lecturas.csv (blanco sobre azul) 
    mov edx, OFFSET msgLeyendo
    mov al, COLOR_LEYENDO
    call MostrarEstado

    mov eax, TIEMPO_ESTADO
    call EsperarConEsc
    cmp teclaEscSalir, 1
    je salirSesion

    invoke CreateFile, OFFSET rutaCsv, GENERIC_READ, FILE_SHARE_READ, NULL, \
                       OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE
    je errorAbrirCsv

    mov hArchivo, eax
    mov bytesLeidos, 0
    invoke ReadFile, hArchivo, OFFSET bufferCsv, TAM_BUFFER_CSV - 1, \
                     OFFSET bytesLeidos, NULL
    push eax
    invoke CloseHandle, hArchivo
    mov hArchivo, INVALID_HANDLE_VALUE
    pop eax

    cmp eax, 0
    je errorAbrirCsv
    mov ecx, bytesLeidos
    cmp ecx, 0
    je errorAbrirCsv
    mov bufferCsv[ecx], 0               ; Procesar solo bytes entregados

    call ParsearLecturasCsv
    cmp numLecturas, 0
    je errorAbrirCsv

    ;  4. Mostrar lecturas una por intervalo (verde claro sobre negro) 
    mov ecx, 0                          ; Indice base 0

cicloLecturas:
    push ecx
    inc ecx                             ; Numero consecutivo desde 1

    mov edi, OFFSET msgEstadoTemp
    mov esi, OFFSET msgPrefijoLect
    call CopiarCadena

    mov eax, ecx
    call EnteroACadena

    mov esi, OFFSET msgDosPuntos
    call CopiarCadena

    ; Calcular direccion de lecturas[indice * MAX_TEMP_LEN]
    pop eax
    push eax
    mov ebx, MAX_TEMP_LEN
    mul ebx
    lea esi, lecturas[eax]
    call CopiarCadena

    mov esi, OFFSET msgSufijoGrados
    call CopiarCadena
    mov BYTE PTR [edi], 0

    mov edx, OFFSET msgEstadoTemp
    mov al, COLOR_LECTURA
    call MostrarEstado

    mov eax, intervaloMs
    call EsperarConEsc
    pop ecx
    cmp teclaEscSalir, 1
    je salirSesion

    inc ecx
    cmp ecx, numLecturas
    jb cicloLecturas

    ;  5. Construir y guardar resultados.csv 
    call ConstruirBufferSalida

    invoke CreateFile, OFFSET rutaOut, GENERIC_WRITE, 0, NULL, \
                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    cmp eax, INVALID_HANDLE_VALUE
    je errorEscribirOut

    mov hArchivo, eax
    mov bytesEscritos, 0
    invoke WriteFile, hArchivo, OFFSET bufferOut, totalBytesOut, \
                      OFFSET bytesEscritos, NULL
    push eax
    invoke CloseHandle, hArchivo
    mov hArchivo, INVALID_HANDLE_VALUE
    pop eax

    cmp eax, 0
    je errorEscribirOut
    mov eax, bytesEscritos
    cmp eax, totalBytesOut
    jne errorEscribirOut

    ;  Exito: Proceso terminado 
    mov edx, OFFSET msgTerminado
    mov al, COLOR_EXITO
    call MostrarEstado
    jmp salirSesion

errorAbrirCsv:
    mov edx, OFFSET msgErrCsv
    mov al, COLOR_ERROR
    call MostrarEstado
    jmp salirSesion

errorEscribirOut:
    mov edx, OFFSET msgErrOut
    mov al, COLOR_ERROR
    call MostrarEstado

salirSesion:
    ret
ProcesarSesionUSB ENDP

; DibujarEncabezado - Imprime el marco fijo superior de la consola

DibujarEncabezado PROC
    mov eax, COLOR_ESPERA
    call SetTextColor
    call Clrscr

    mov dl, 0
    mov dh, 1
    call Gotoxy
    mov edx, OFFSET banner1
    call WriteString

    mov dl, 0
    mov dh, 2
    call Gotoxy
    mov edx, OFFSET banner2
    call WriteString

    ret
DibujarEncabezado ENDP

; MostrarEstado - Imprime un mensaje en la fila fija y limpia el resto
; Entrada: EDX = puntero a cadena NUL-terminada, AL = atributo de color

MostrarEstado PROC
    push ebx
    push ecx
    push edx
    push esi

    mov bl, al                          ; Guardar color solicitado
    mov esi, edx                        ; Guardar puntero al mensaje

    mov dl, 0
    mov dh, FILA_ESTADO
    call Gotoxy

    movzx eax, bl
    call SetTextColor

    mov edx, esi
    call WriteString

    ; Contar longitud escrita para limpiar caracteres sobrantes
    mov ecx, 0
contarLen:
    cmp BYTE PTR [esi + ecx], 0
    je limpiarResto
    inc ecx
    jmp contarLen

limpiarResto:
    mov eax, COLOR_ESPERA
    call SetTextColor

    mov al, ' '
cicloEspacios:
    cmp ecx, ANCHO_ESTADO
    jae finMostrarEstado
    call WriteChar
    inc ecx
    jmp cicloEspacios

finMostrarEstado:
    mov dl, 0
    mov dh, FILA_ESTADO + 1
    call Gotoxy

    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
MostrarEstado ENDP

; VerificarEsc - Revisa sin bloquear si el usuario presiono ESC (ASCII 27)

VerificarEsc PROC
    call ReadKey
    jz noHayTecla
    cmp al, 27
    jne noHayTecla
    mov teclaEscSalir, 1
noHayTecla:
    ret
VerificarEsc ENDP

; EsperarConEsc - Espera EAX milisegundos en bloques cortos revisando ESC

EsperarConEsc PROC
    push ebx
    mov ebx, eax
    cmp ebx, 0
    jle finEsperarEsc

cicloDelay:
    call VerificarEsc
    cmp teclaEscSalir, 1
    je finEsperarEsc

    cmp ebx, 100
    jbe ultimoTramo
    invoke Sleep, 100
    sub ebx, 100
    jmp cicloDelay

ultimoTramo:
    invoke Sleep, ebx
    call VerificarEsc

finEsperarEsc:
    pop ebx
    ret
EsperarConEsc ENDP

; ParsearSensorIni - Extrae SITIO e INTERVALO_MS de bufferIni

ParsearSensorIni PROC
    ; Inicializar valores por defecto
    mov edi, OFFSET nombreSitio
    mov esi, OFFSET sitioDefecto
    call CopiarCadena
    mov BYTE PTR [edi], 0
    mov intervaloMs, 1000

    mov esi, OFFSET bufferIni

iniSiguienteLinea:
    ; Saltar espacios, tabuladores y saltos de linea
    mov al, [esi]
    cmp al, 0
    je iniFin
    cmp al, ' '
    je iniAvanzarChar
    cmp al, 9
    je iniAvanzarChar
    cmp al, 13
    je iniAvanzarChar
    cmp al, 10
    je iniAvanzarChar
    jmp iniRevisarLinea

iniAvanzarChar:
    inc esi
    jmp iniSiguienteLinea

iniRevisarLinea:
    ; Ignorar secciones [sensor] y comentarios
    cmp al, '['
    je iniSaltarLinea
    cmp al, ';'
    je iniSaltarLinea
    cmp al, '#'
    je iniSaltarLinea

    ; Probar clave SITIO=
    mov edx, OFFSET claveSitio
    call CoincidePrefijoSinCaso
    cmp eax, 1
    jne probarIntervalo

    add esi, 6                          ; Longitud de "SITIO="
    call SaltarEspaciosHoriz
    mov edi, OFFSET nombreSitio
    mov ecx, 0
copiarSitio:
    mov al, [esi]
    cmp al, 0
    je finCopiarSitio
    cmp al, 13
    je finCopiarSitio
    cmp al, 10
    je finCopiarSitio
    cmp ecx, 62
    jae finCopiarSitio
    mov [edi + ecx], al
    inc ecx
    inc esi
    jmp copiarSitio

finCopiarSitio:
    ; Recortar espacios finales
recortarSitio:
    cmp ecx, 0
    je cerrarSitio
    mov al, [edi + ecx - 1]
    cmp al, ' '
    je retrocederSitio
    cmp al, 9
    je retrocederSitio
    jmp cerrarSitio
retrocederSitio:
    dec ecx
    jmp recortarSitio
cerrarSitio:
    mov BYTE PTR [edi + ecx], 0
    jmp iniSaltarLinea

probarIntervalo:
    mov edx, OFFSET claveIntervalo
    call CoincidePrefijoSinCaso
    cmp eax, 1
    jne iniSaltarLinea

    add esi, 13                         ; Longitud de "INTERVALO_MS="
    call SaltarEspaciosHoriz
    call CadenaAEntero
    cmp eax, 0
    je iniSaltarLinea
    mov intervaloMs, eax

iniSaltarLinea:
    mov al, [esi]
    cmp al, 0
    je iniFin
    cmp al, 13
    je iniSiguienteLinea
    cmp al, 10
    je iniSiguienteLinea
    inc esi
    jmp iniSaltarLinea

iniFin:
    ret
ParsearSensorIni ENDP

; ParsearLecturasCsv - Lee temperaturas de bufferCsv omitiendo el encabezado

ParsearLecturasCsv PROC
    mov numLecturas, 0
    mov esi, OFFSET bufferCsv

    ; Omitir BOM UTF-8 (EF BB BF) si existe
    cmp bytesLeidos, 3
    jb iniciarCsv
    cmp BYTE PTR [esi], 0EFh
    jne iniciarCsv
    cmp BYTE PTR [esi + 1], 0BBh
    jne iniciarCsv
    cmp BYTE PTR [esi + 2], 0BFh
    jne iniciarCsv
    add esi, 3

iniciarCsv:
    mov ebx, 0                          ; 0 = falta encabezado, 1 = leyendo datos

csvSiguienteLinea:
    mov al, [esi]
    cmp al, 0
    je csvFin
    cmp al, ' '
    je csvAvanzar
    cmp al, 9
    je csvAvanzar
    cmp al, 13
    je csvAvanzar
    cmp al, 10
    je csvAvanzar
    jmp csvProcesarLinea

csvAvanzar:
    inc esi
    jmp csvSiguienteLinea

csvProcesarLinea:
    cmp ebx, 0
    jne csvLeerValor

    ; Primera linea no vacia: encabezado (temperatura_c)
    mov ebx, 1
    jmp csvSaltarRestoLinea

csvLeerValor:
    mov eax, numLecturas
    cmp eax, MAX_LECTURAS
    jae csvFin

    mov ecx, MAX_TEMP_LEN
    mul ecx
    lea edi, lecturas[eax]
    mov ecx, 0

csvCopiarTemp:
    mov al, [esi]
    cmp al, 0
    je csvFinTemp
    cmp al, 13
    je csvFinTemp
    cmp al, 10
    je csvFinTemp
    cmp al, ','
    je csvFinTemp
    cmp ecx, MAX_TEMP_LEN - 1
    jae csvFinTemp
    mov [edi + ecx], al
    inc ecx
    inc esi
    jmp csvCopiarTemp

csvFinTemp:
    cmp ecx, 0
    je csvRecorteListo
    mov al, [edi + ecx - 1]
    cmp al, ' '
    je csvRetrocederTemp
    cmp al, 9
    je csvRetrocederTemp
    jmp csvRecorteListo
csvRetrocederTemp:
    dec ecx
    jmp csvFinTemp

csvRecorteListo:
    mov BYTE PTR [edi + ecx], 0
    cmp ecx, 0
    je csvSaltarRestoLinea
    inc numLecturas

csvSaltarRestoLinea:
    mov al, [esi]
    cmp al, 0
    je csvFin
    cmp al, 13
    je csvSiguienteLinea
    cmp al, 10
    je csvSiguienteLinea
    inc esi
    jmp csvSaltarRestoLinea

csvFin:
    ret
ParsearLecturasCsv ENDP

; ConstruirBufferSalida - Genera el CSV de resultados en bufferOut

ConstruirBufferSalida PROC
    mov edi, OFFSET bufferOut
    mov esi, OFFSET encabezadoOut
    call CopiarCadena

    mov ecx, 0                          ; Indice base 0
cicloOut:
    cmp ecx, numLecturas
    jae finOut

    push ecx
    inc ecx                             ; Numero consecutivo desde 1

    ; sitio,
    mov esi, OFFSET nombreSitio
    call CopiarCadena
    mov BYTE PTR [edi], ','
    inc edi

    ; numero,
    mov eax, ecx
    call EnteroACadena
    mov BYTE PTR [edi], ','
    inc edi

    ; temperatura_c\r\n
    pop eax
    push eax
    mov ebx, MAX_TEMP_LEN
    mul ebx
    lea esi, lecturas[eax]
    call CopiarCadena

    mov BYTE PTR [edi], 13
    inc edi
    mov BYTE PTR [edi], 10
    inc edi

    pop ecx
    inc ecx
    jmp cicloOut

finOut:
    mov BYTE PTR [edi], 0
    sub edi, OFFSET bufferOut
    mov totalBytesOut, edi
    ret
ConstruirBufferSalida ENDP

; Subrutinas auxiliares de cadenas y conversion

; CopiarCadena: copia de ESI a EDI sin NUL final; avanza EDI al final
CopiarCadena PROC
    push eax
copiarLoop:
    mov al, [esi]
    cmp al, 0
    je copiarFin
    mov [edi], al
    inc esi
    inc edi
    jmp copiarLoop
copiarFin:
    pop eax
    ret
CopiarCadena ENDP

; EnteroACadena: convierte EAX (unsigned) a decimal en EDI, avanza EDI
EnteroACadena PROC
    push ebx
    push ecx
    push edx

    mov ebx, 10
    mov ecx, 0
    cmp eax, 0
    jne divLoop
    mov BYTE PTR [edi], '0'
    inc edi
    jmp enteroFin

divLoop:
    cmp eax, 0
    je popDigitos
    xor edx, edx
    div ebx
    add dl, '0'
    push edx
    inc ecx
    jmp divLoop

popDigitos:
    cmp ecx, 0
    je enteroFin
    pop eax
    mov [edi], al
    inc edi
    dec ecx
    jmp popDigitos

enteroFin:
    pop edx
    pop ecx
    pop ebx
    ret
EnteroACadena ENDP

; CadenaAEntero: convierte digitos decimales desde ESI -> EAX
CadenaAEntero PROC
    push ebx
    push edx
    xor eax, eax
    mov ebx, 10

convLoop:
    mov dl, [esi]
    cmp dl, '0'
    jb convFin
    cmp dl, '9'
    ja convFin
    sub dl, '0'
    movzx edx, dl
    imul eax, ebx
    add eax, edx
    inc esi
    jmp convLoop

convFin:
    pop edx
    pop ebx
    ret
CadenaAEntero ENDP

; SaltarEspaciosHoriz: avanza ESI sobre espacios y tabuladores
SaltarEspaciosHoriz PROC
espLoop:
    mov al, [esi]
    cmp al, ' '
    je espAvanzar
    cmp al, 9
    je espAvanzar
    ret
espAvanzar:
    inc esi
    jmp espLoop
SaltarEspaciosHoriz ENDP

; CoincidePrefijoSinCaso: compara cadena en ESI contra prefijo NUL en EDX
; Devuelve EAX = 1 si coincide, 0 si no coincide
CoincidePrefijoSinCaso PROC
    push esi
    push edi
    push ebx
    mov edi, edx

cmpLoop:
    mov bl, [edi]
    cmp bl, 0
    je cmpCoincide

    mov al, [esi]
    cmp al, 0
    je cmpNoCoincide

    ; Convertir ambos a mayuscula si son a..z
    cmp al, 'a'
    jb checkBl
    cmp al, 'z'
    ja checkBl
    sub al, 32
checkBl:
    cmp bl, 'a'
    jb cmpChars
    cmp bl, 'z'
    ja cmpChars
    sub bl, 32
cmpChars:
    cmp al, bl
    jne cmpNoCoincide
    inc esi
    inc edi
    jmp cmpLoop

cmpCoincide:
    mov eax, 1
    jmp cmpSalir
cmpNoCoincide:
    xor eax, eax
cmpSalir:
    pop ebx
    pop edi
    pop esi
    ret
CoincidePrefijoSinCaso ENDP

END main
