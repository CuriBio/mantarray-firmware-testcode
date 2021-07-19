#ifndef MANTARRAY_UART_COMM_H_
#define MANTARRAY_UART_COMM_H_

#include <string.h>
#include <stdio.h>
#include "main.h"

typedef struct
{
	char uartBuffer[30];
	uint8_t uartBufLen;
} UART_Comm;

void serialSend(UART_HandleTypeDef* thisUART, char* message, uint8_t len);

#endif /* MANTARRAY_UART_COMM_H_ */
