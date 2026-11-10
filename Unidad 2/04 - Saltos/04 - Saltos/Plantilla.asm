; Saltos, los programas se ejecutan de manera sequencial, con los saltos podemos romper este flujo, como un if y/o una función
; Saltos directos con JMP. Los saltos con hacía etiquetas. Primero hacemos una comparación con CMP y luego un salto
; hacía la etiqueta ( JMP etiqueta: )

INCLUDE Irvine32.inc
.code
main PROC

mov eax, 5
jmp continuar
mov eax, 10

continuar:
	call DumpRegs
	exit

; Podemos ver que gracias al salto hacía la etiqueta continuar nos saltamos el código de la línea 11, porque el registro en efecto guardó el número 5
main ENDP
END main