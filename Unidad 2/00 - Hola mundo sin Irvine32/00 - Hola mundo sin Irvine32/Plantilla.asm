.386
.model flat, stdcall
option casemap:none

; Prototipos de las funciones de la API de Windows (kernel32)
GetStdHandle PROTO, nStdHandle:DWORD
WriteConsoleA PROTO, 
    hConsoleOutput:DWORD, 
    lpBuffer:PTR BYTE, 
    nNumberOfCharsToWrite:DWORD, 
    lpNumberOfCharsWritten:PTR DWORD, 
    lpReserved:DWORD
ExitProcess PROTO, uExitCode:DWORD

; Constante para la salida estándar
STD_OUTPUT_HANDLE EQU -11

.data
    mensaje BYTE "Hola Mundo", 13, 10 ; El 13 es carriage line y 10 es feedline
    longitud EQU ($ - mensaje)        ; Longitud nos permite conocer automáticamente la cantidad de bytes que ocupa el mensaje
    caracteresEscritos DWORD ?

.code
main PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE ; Llamamos la función GetStdHandle con el valor de la constante símbolica STD
    mov ebx, eax    ; Guardamos el handle retornado en EAX dentro de EBX

    ; 2. Escribir el texto en la consola
    INVOKE WriteConsoleA,
        ebx,                    ; Handle de la consola
        ADDR mensaje,           ; Puntero a la cadena
        longitud,               ; Longitud del mensaje
        ADDR caracteresEscritos,; Puntero donde se guarda el núm. de caracteres escritos
        0                       ; Parámetro reservado (NULL)

    
    INVOKE ExitProcess, 0       ; Finalizar el proceso con código de salida 0
main ENDP

END main