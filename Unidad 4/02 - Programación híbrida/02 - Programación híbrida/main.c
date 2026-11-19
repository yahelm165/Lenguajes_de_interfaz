#include <stdio.h>

// Establecer el procedimiento de la operación suma en ensamblador.
int _stdcall Sumar(int primero, int segundo);

int main(void) {
	int primero = 30;
	int segundo = 25;

	int resultado = Sumar(primero, segundo);
	printf("Resultado: %d", resultado);

	return 0; //Terminador 0 en C para que terminé el programa.
}