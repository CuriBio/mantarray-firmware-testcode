#include "UART_Comm.h"

#include "main.h"

#include <string.h>
#include <stdio.h>

void serialSend(UART_HandleTypeDef* thisUART, char* message, uint8_t len)
{
	//TODO Implement error functionalities
	HAL_UART_Transmit(thisUART, (uint8_t*) message, len, 100);
}
