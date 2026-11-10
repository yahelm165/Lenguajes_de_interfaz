INCLUDE Irvine32.inc
.data

msgMayor byte "El segundo es mayor", 0
msgMenor byte "El segundo es menor", 0
msgIguales byte "Son iguales", 0
numero DWORD ?
msgPrimero byte "Escribe el primer número: ", 0
msgSegundo byte "Escribe el segundo número: ", 0

.code
main PROC

mov edx, offset msgPrimero
call WriteString
call ReadDec
mov numero, eax ; ReadDec automaticamente guarda el valor en EAX, así que lo vamos a guardar en la variable numero para luego compararlo con el otro número
call Crlf

mov edx, offset msgSegundo
call WriteString
call ReadDec  ; Leemos el segundo numero y se queda guardado en el registro EAX
call Crlf

cmp numero, eax
ja segundoMenor ; Utilizamos jmp Above y Below porque son números sin signo, si fuesen con signo usaríamos jmp Greater y Less
jb segundoMayor

mov edx, offset msgIguales ; Si no es mayor ni menor, entonces son iguales
call WriteString
call Crlf
jmp fin

segundoMenor:
	mov edx, offset msgMenor
	call WriteString
	call Crlf
	jmp fin

segundoMayor:
	mov edx, offset msgMayor
	call WriteString
	call Crlf
	
fin:
	exit

main ENDP
END main