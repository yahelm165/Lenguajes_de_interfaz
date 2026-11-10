INCLUDE Irvine32.inc
.data

mensaje BYTE "Hola Mundo!", 0

.code
main PROC

MOV edx, OFFSET mensaje
CALL WriteString
CALL Crlf
EXIT

main ENDP
END main