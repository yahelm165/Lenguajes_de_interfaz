; Docente: Jose Luis Medina Jimenez - Materia: Lenguajes de Interfaz - Instituto Tecnologico de Culiacan
; Yahel Alejandro Montero Lopez - 21170401 - Ing. en Sistemas Computacionales

; Este programa tiene como proposito analizar y demostrar el comportamiento de las banderas de estado (Status Flags)
; del registro EFLAGS en la arquitectura x86, utilizando la instruccion CMP (Compare) y la instruccion TEST.

; La instruccion CMP realiza una resta no destructiva (destino - fuente): no almacena el resultado en el registro
; destino, pero actualiza las banderas segun el resultado aritmetico:
;   - Zero Flag (ZF): Se activa (1) si el resultado de la resta es 0 (ambos operandos son iguales).
;   - Sign Flag (SF): Se activa (1) si el bit mas significativo (MSB) del resultado es 1 (resultado negativo con signo).
;   - Carry Flag (CF): Se activa (1) si ocurre un acarreo o prestamo en operaciones sin signo (ej. destino < fuente).
;   - Overflow Flag (OF): Se activa (1) si ocurre un desbordamiento aritmetico con signo (rango con signo excedido).

; Por su parte, TEST realiza una operacion AND logica bit a bit entre dos operandos sin alterar sus valores,
; actualizando unicamente las banderas (ZF, SF, PF), dejando siempre CF y OF en 0.
; Para observar estos cambios en tiempo real se utiliza la subrutina DumpRegs de la biblioteca Irvine32.

INCLUDE Irvine32.inc

.data
.code
main PROC

; Caso 1: Zero Flag (ZF)
; Cuando dos operandos son exactamente iguales, la resta interna (eax - ebx) produce un valor de 0, la CPU activa ZF = 1.
mov eax, 5
mov ebx, 5
cmp eax, ebx
call DumpRegs       ; Muestra el estado de los registros y banderas (ver ZF=1).

mov eax, 10h        ; 10h = 16 en decimal
mov ebx, 10h        ; 10h = 16 en decimal
cmp eax, ebx        ; Se activa ZF=1 y podemos visualizarlos con DumpRegs
call DumpRegs       

; Caso 2: Sign Flag (SF)
; SF refleja el bit mas representativo (signo en complemento a dos) del resultado.
; En registros de 8 bits (AL/BL), el rango con signo va de -128 a +127.
mov eax, 0          ; Reiniciamos el valor de los registros para limpiar bits residuales
mov ebx, 0
mov al, -5          ; En binario (complemento a dos de 8 bits): FBh (11111011b)
mov bl, 1           ; 01h (00000001b)
cmp al, bl          ; Resta: (-5) - (1) = -6 (FAh / 11111010b).
                    ; Como el resultado es negativo con signo (su bit mas significativo es 1), se activa SF=1.
call DumpRegs

; Caso 3: Carry Flag (CF)
; La bandera de acarreo/prestamo detecta si una resta sin signo necesito pedir prestado.
; En una comparacion sin signo: si destino < fuente, la operacion requiere prestamo y enciende CF=1.
mov eax, 0          ; Reiniciamos el valor de los registros
mov ebx, 0
mov al, 2           ; Valor menor
mov bl, 11          ; Valor mayor
cmp al, bl          ; Evaluacion sin signo: 2 < 11 requiere un prestamo, por lo que se activa CF=1.
call DumpRegs

; Caso 4: Overflow Flag (OF)
; Ocurre desbordamiento cuando el resultado de una operacion aritmetica con signo excede el rango
; representable del tamano del operando. En 8 bits con signo, el rango valido es de -128 a +127.
mov eax, 0          ; Reiniciamos el valor de los registros
mov ebx, 0
mov al, -128        ; Valor minimo posible con signo en un BYTE: 80h (10000000b)
mov bl, 1           ; 01h
cmp al, bl          ; Resta: (-128) - (1) = -129.
                    ; -129 se sale del limite minimo de 8 bits (-128) y activa OF=1.
call DumpRegs

; Caso 5: TEST
; La instruccion TEST realiza una operacion logica AND bit a bit.
; No altera los operandos, solo actualiza las banderas.
; Si ningun bit coincide en 1, el resultado del AND es 0 y se activa ZF=1.
; Si al menos un bit coincide, el resultado es distinto de cero y ZF=0.
mov eax, 0          ; Reiniciamos el valor de los registros
mov eax, 5          ; 5 en binario:  00000101b
test eax, 1         ; Mascara:       00000001b
                    ; AND logico:    00000001b (resultado != 0)
                    ; Como el resultado tiene un bit activo (el bit 0), ZF=0. Sirve para probar si un numero es impar.
; 00000101
; 00000001
; AND lógico
; 00000001
; call DumpRegs

mov al, 10000000b   ; 80h en binario (el bit 7, que es el bit de signo, esta en 1)
test al, 10000000b  ; Operacion AND logica bit a bit:
                    ; 10000000b AND 10000000b = 10000000b
                    ; ¿Por que se activa Sign Flag (SF)?
                    ; La instruccion TEST copia el bit mas significativo (MSB) del resultado directamente
                    ; en la bandera SF. Dado que el resultado de 8 bits de esta operacion tiene su bit 7 en 1,
                    ; el procesador interpreta ese bit como un signo negativo y enciende SF=1.

call DumpRegs       ; En la salida se observara SF=1 y ZF=0 debido al bit 7 activo.

exit

main ENDP
END main