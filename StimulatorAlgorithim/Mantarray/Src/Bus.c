#include "Bus.h"

InternalBus_t * internal_bus_create(GPIO_TypeDef *bus_line,uint16_t bus_pins,GPIO_TypeDef *cl_bus,uint16_t cl_pin,GPIO_TypeDef *ak_bus,uint16_t ak_pin)
{
	InternalBus_t * thisInternalBus = (InternalBus_t *) malloc(sizeof(InternalBus_t));
	if(thisInternalBus != NULL)
	{
		//assign desired value for clock pin and other bus  so this bus will now which pins assigned for clock ack and bus line it self
		//everything else in this lib should use this data for other settings
		thisInternalBus->bus = bus_line;
		thisInternalBus->bus_mask = bus_pins;
		thisInternalBus->BUS_BUSMASK32 = 0;
		thisInternalBus->BUS_BUSMODER = 0;
		thisInternalBus->BUS_BUSOSPEEDR = 0;

		thisInternalBus->bus_clk = cl_bus;
		thisInternalBus->bus_clk_mask = cl_pin;
		thisInternalBus->BUS_CLKMASK32 = 0;
		thisInternalBus->BUS_CLKMODER = 0;
		thisInternalBus->BUS_CLKOSPEEDR = 0;

		thisInternalBus->bus_ack = ak_bus;
		thisInternalBus->bus_ack_mask = ak_pin;
		thisInternalBus->BUS_ACKMASK32 = 0;
		thisInternalBus->BUS_ACKMODER = 0;
		thisInternalBus->BUS_ACKOSPEEDR = 0;

		uint32_t pinShifter = 0;
		for (pinShifter = 0; pinShifter < BUS_GPIO_PINS_PER_BUS; pinShifter++)
		{
			if (bus_pins & (1 << pinShifter))
			{
				thisInternalBus->BUS_BUSMASK32  |= (0b11 << (pinShifter * 2));
				thisInternalBus->BUS_BUSMODER   |= (0b01 << (pinShifter * 2));
				thisInternalBus->BUS_BUSOSPEEDR |= (0b11 << (pinShifter * 2));
			}
			if (cl_pin & (1 << pinShifter))
			{
				thisInternalBus->BUS_CLKMASK32  |= (0b11 << (pinShifter * 2));
				thisInternalBus->BUS_CLKMODER   |= (0b01 << (pinShifter * 2));
				thisInternalBus->BUS_CLKOSPEEDR |= (0b11 << (pinShifter * 2));
			}
			if (ak_pin & (1 << pinShifter))
			{
				thisInternalBus->BUS_ACKMASK32  |= (0b11 << (pinShifter * 2));
				thisInternalBus->BUS_ACKMODER   |= (0b01 << (pinShifter * 2));
				thisInternalBus->BUS_ACKOSPEEDR |= (0b11 << (pinShifter * 2));
			}
		}

		uint32_t temp = 0;
		//Set main bus output speed to very high
		temp = thisInternalBus->bus->OSPEEDR;
		temp &= ~thisInternalBus->BUS_BUSMASK32;
		temp |= thisInternalBus->BUS_BUSOSPEEDR;
		thisInternalBus->bus->OSPEEDR = temp;
		//Set main bus output type to output push-pull
		temp = thisInternalBus->bus->OTYPER;
		temp &= ~thisInternalBus->bus_mask;
		thisInternalBus->bus->OTYPER = temp;
		//Set main bus pullup/down resistors to none
		temp = thisInternalBus->bus->PUPDR;
		temp &= ~thisInternalBus->BUS_BUSMASK32;
		thisInternalBus->bus->PUPDR = temp;

		//Set Clock line, output speed to very high
		temp = thisInternalBus->bus_clk->OSPEEDR;
		temp &= ~thisInternalBus->BUS_CLKMASK32;
		temp |= thisInternalBus->BUS_CLKOSPEEDR;
		thisInternalBus->bus_clk->OSPEEDR = temp;
		//Set C bus output type to output push-pull
		temp = thisInternalBus->bus_clk->OTYPER;
		temp &= ~thisInternalBus->bus_clk_mask;
		thisInternalBus->bus_clk->OTYPER = temp;
		//Set C bus pullup/down resistors to none
		temp = thisInternalBus->bus_clk->PUPDR;
		temp &= ~thisInternalBus->BUS_CLKMASK32;
		thisInternalBus->bus_clk->PUPDR = temp;

		//Set Ack line, output speed to very high
		temp = thisInternalBus->bus_ack->OSPEEDR;
		temp &= ~thisInternalBus->BUS_ACKMASK32;
		temp |= thisInternalBus->BUS_ACKOSPEEDR;
		thisInternalBus->bus_ack->OSPEEDR = temp;
		//Set C bus output type to output push-pull
		temp = thisInternalBus->bus_ack->OTYPER;
		temp &= ~thisInternalBus->bus_ack_mask;
		thisInternalBus->bus_ack->OTYPER = temp;
		//Set C bus pullup/down resistors to none
		temp = thisInternalBus->bus_ack->PUPDR;
		temp &= ~thisInternalBus->BUS_ACKMASK32;
		thisInternalBus->bus_ack->PUPDR = temp;

		//by default we do not have to take the bus before any persmission from the master micro
		internal_bus_release(thisInternalBus);
	}
	else
	{
		//TODO  erro handler
	}
	return thisInternalBus;
}

inline void internal_bus_write_data_frame(InternalBus_t *thisInternalBus, uint32_t *buffer, uint8_t buffer_len)
{
	//TODO Link data output to magnetometer memory instead

	internal_bus_utilize(thisInternalBus);

	//Send dataframe
	//TODO may need a data offset term if the bus pins do not begin at 0
	//ie. thisInternalBus->bus->BSRR = (uint32_t) ((thisInternalBus->bus_mask & (testData[0] << BUSOFFSET))  | ((thisInternalBus->bus_mask & ~(testData[0] << BUSOFFSET))  << 16));
	for(uint8_t buf_cnt=0 ; buf_cnt < buffer_len ; buf_cnt++)
	{
		thisInternalBus->bus_clk->BSRR = (uint32_t) thisInternalBus->bus_clk_mask;
		thisInternalBus->bus->BSRR = buffer[buf_cnt];
		thisInternalBus->bus_clk->BRR = thisInternalBus->bus_clk_mask;
	}

	internal_bus_release(thisInternalBus);
}

inline void internal_bus_utilize(InternalBus_t *thisInternalBus)
{
	uint32_t temp = 0;
	//Set Bus pins to output
	temp = thisInternalBus->bus->MODER;
	temp &= ~thisInternalBus->BUS_BUSMASK32;
	temp |= thisInternalBus->BUS_BUSMODER;
	thisInternalBus->bus->MODER = temp;

	//Set clock pin to output
	temp = thisInternalBus->bus_clk->MODER;
	temp &= ~thisInternalBus->BUS_CLKMASK32;
	temp |= thisInternalBus->BUS_CLKMODER;
	thisInternalBus->bus_clk->MODER = temp;

	//Set ack pin to output
	temp = thisInternalBus->bus_ack->MODER;
	temp &= ~thisInternalBus->BUS_ACKMASK32;
	temp |= thisInternalBus->BUS_ACKMODER;
	thisInternalBus->bus_ack->MODER = temp;

	thisInternalBus->bus_ack->BSRR = (uint32_t) thisInternalBus->bus_ack_mask;
}

inline void internal_bus_release(InternalBus_t *thisInternalBus)
{
	uint32_t temp = 0;
	//Set all bus pins to low and send complete
	thisInternalBus->bus->BRR = thisInternalBus->bus_mask;
	thisInternalBus->bus_ack->BRR = thisInternalBus->bus_ack_mask;

	//Set Bus pins to input
	temp = thisInternalBus->bus->MODER;
	temp &= ~thisInternalBus->BUS_BUSMASK32;
	thisInternalBus->bus->MODER = temp;

	//Set clock pin to input
	temp = thisInternalBus->bus_clk->MODER;
	temp &= ~thisInternalBus->BUS_CLKMASK32;
	thisInternalBus->bus_clk->MODER = temp;

	//Set ack pins to input
	temp = thisInternalBus->bus_ack->MODER;
	temp &= ~thisInternalBus->BUS_ACKMASK32;
	thisInternalBus->bus_ack->MODER = temp;
}
