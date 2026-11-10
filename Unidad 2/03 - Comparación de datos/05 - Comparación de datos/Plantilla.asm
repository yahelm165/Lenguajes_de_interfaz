INCLUDE Irvine32.inc
.data
.code
main PROC

; Caso 1: Zero Flag
mov eax, 5
mov ebx, 5
cmp eax, ebx
call DumpRegs
mov eax, 10h
mov ebx, 10h
call DumpRegs

; Caso 2: Sing Flag
mov eax, 0 ; Reiniciamos el valor de los registros
mov ebx, 0
mov al, -5
mov bl, 1
cmp al, bl
call DumpRegs

; Caso 3: Carry Flag
mov eax, 0 ; Reiniciamos el valor de los registros
mov ebx, 0
mov al, 2
mov bl, 11
cmp al, bl
call DumpRegs

; Caso 4: OverFlow
mov eax, 0 ; Reiniciamos el valor de los registros
mov ebx, 0
mov al, -128
mov bl, 1
cmp al, bl
call DumpRegs

; Caso 5: TEST
mov eax, 0 ; Reiniciamos el valor de los registros
mov eax, 5
test eax, 1
; 00000101
; 00000001
; AND lógico
; 00000001
; call DumpRegs
mov al, 10000000b
test al, 10000000b
call DumpRegs ; Por qué se activa SignFlag?
exit

main ENDP
END main