#include <stdlib.h>
#include <stdio.h>
#include "main.h"

#ifndef BUS_H_
#define BUS_H_

#define BUS_GPIO_PINS_PER_BUS        0x10

typedef struct
{
	GPIO_TypeDef * bus;
	uint16_t bus_mask;
	uint32_t BUS_BUSMASK32;
	uint32_t BUS_BUSMODER;
	uint32_t BUS_BUSOSPEEDR;

	GPIO_TypeDef * bus_clk;
	uint16_t bus_clk_mask;
	uint32_t BUS_CLKMASK32;
	uint32_t BUS_CLKMODER;
	uint32_t BUS_CLKOSPEEDR;

	GPIO_TypeDef * bus_ack;
	uint16_t bus_ack_mask;
	uint32_t BUS_ACKMASK32;
	uint32_t BUS_ACKMODER;
	uint32_t BUS_ACKOSPEEDR;
	


}InternalBus_t;

InternalBus_t * internal_bus_create(GPIO_TypeDef *bus_line,uint16_t bus_pins,GPIO_TypeDef *cl_bus,uint16_t cl_pin,GPIO_TypeDef *ak_bus,uint16_t ak_pin);
void internal_bus_write_data_frame(InternalBus_t *thisInternalBus,uint32_t *buffer,uint8_t buffer_len);
void internal_bus_utilize(InternalBus_t *thisInternalBus);
void internal_bus_release(InternalBus_t *thisInternalBus);

#endif /* BUS_H_ */
