#include "system.h"

extern SPI_HandleTypeDef hspi1;
extern I2C_HandleTypeDef hi2c2;
extern TIM_HandleTypeDef htim21;
extern System my_sys;

void module_system_init(System *thisSystem)
{
	/*
	my_sys.data_bus = internal_bus_create(GPIOB,  BUS0_Pin | BUS1_Pin | BUS2_Pin | BUS3_Pin | BUS4_Pin | BUS5_Pin | BUS6_Pin | BUS7_Pin,
											BUS_CLK_GPIO_Port, BUS_CLK_Pin,
											BUS_C1_GPIO_Port, BUS_C1_Pin);

	thisSystem->ph_global_timer = global_timer_create(&htim21);

	HAL_GPIO_WritePin(SPI_A_CS_GPIO_Port, SPI_A_CS_Pin, GPIO_PIN_SET);
	HAL_GPIO_WritePin(SPI_B_CS_GPIO_Port, SPI_B_CS_Pin, GPIO_PIN_SET);
	HAL_GPIO_WritePin(SPI_C_CS_GPIO_Port, SPI_C_CS_Pin, GPIO_PIN_SET);
	*/
	my_sys.i2c_line = I2C_interface_create(&hi2c2,100);
	my_sys.stimulator = stimulator_create(&hdac, &hadc, &htim21);
	/*
	// init sensors
	my_sys.sensors[0] = magnetometer_create(MAGNETOMETER_TYPE_MMC5983,&hspi1 , SPI_A_CS_GPIO_Port , SPI_A_CS_Pin , mag_int_a_GPIO_Port , mag_int_a_Pin);
	my_sys.sensors[1] = magnetometer_create(MAGNETOMETER_TYPE_MMC5983,&hspi1 , SPI_B_CS_GPIO_Port , SPI_B_CS_Pin , mag_int_b_GPIO_Port , mag_int_b_Pin);
	my_sys.sensors[2] = magnetometer_create(MAGNETOMETER_TYPE_MMC5983,&hspi1 , SPI_C_CS_GPIO_Port , SPI_C_CS_Pin , mag_int_c_GPIO_Port , mag_int_c_Pin);
	*/

}

void state_machine(System *thisSystem)
{
	uint32_t output_data[33];
	uint8_t b_read_permit =0;
	uint8_t byte_shifter = 0;
	uint8_t this_byte = 0;
	while(1)
	{
		if(b_read_permit)
		{
			for (uint8_t sensor_num = 0; sensor_num < NUM_SENSORS; sensor_num++)
			{
				if( (thisSystem->sensors[sensor_num]->sensor_status == MAGNETOMETER_OK) & thisSystem->sensors[sensor_num]->b_new_data_needed)
				{
					if(magnetometer_read(thisSystem->sensors[sensor_num]))
					{
						byte_shifter = 0;
						while (byte_shifter < 5)
						{
							//output_data[byte_shifter + sensor_num * 11] = *(((uint8_t*)&thisSystem->sensors[sensor_num]->time_stamp) + byte_shifter);
							this_byte = *(((uint8_t*)&thisSystem->sensors[sensor_num]->time_stamp) + byte_shifter);
							output_data[byte_shifter + sensor_num * 11] = (uint32_t)(thisSystem->data_bus->bus_mask & this_byte)  | ((thisSystem->data_bus->bus_mask & ~this_byte)  << 16);
							byte_shifter++;
						}

						while (byte_shifter < 11)
						{
							//output_data[byte_shifter + sensor_num * 11] = *(((uint8_t*)thisSystem->sensors[sensor_num]->Readings) + (byte_shifter - 5));
							this_byte = *(((uint8_t*)thisSystem->sensors[sensor_num]->Readings) + (byte_shifter - 5));
							output_data[byte_shifter + sensor_num * 11] = (uint32_t)(thisSystem->data_bus->bus_mask & this_byte)  | ((thisSystem->data_bus->bus_mask & ~this_byte)  << 16);
							byte_shifter++;
						}

						//Declare that new data is no longer needed
						thisSystem->sensors[sensor_num]->b_new_data_needed = 0;
						//Begin a new data conversion immediately
						MMC5983_register_write((MMC5983_t*)thisSystem->sensors[sensor_num]->magnetometer, MMC5983_INTERNALCONTROL0, MMC5983_CTRL0_TM_M);
						//Timestamp the new data conversion you ordered
						thisSystem->sensors[sensor_num]->time_stamp = get_global_timer(thisSystem->ph_global_timer);
						//thisSystem->sensors[sensor_num]->time_stamp++;

					} //Check if the magnetometer has new data ready
				} //Check if magnetometer is functional and if new data is needed
			} //Sensor loop
			b_read_permit =0;
		}
		//------------------------------------------
		if(my_sys.i2c_line->buffer_index)
		{
			NVIC_DisableIRQ(I2C2_IRQn);
			switch(my_sys.i2c_line->receiveBuffer[0])
			{
				//-------------------------------
				case I2C_PACKET_SEND_DATA_FRAME:
				{

					//TODO Link data output to magnetometer memory instead
					/*
					   internal_bus_write_data_frame(thisSystem->data_bus, output_data, 33);
					   my_sys.sensors[0]->b_new_data_needed = 1;
					   my_sys.sensors[1]->b_new_data_needed = 1;
					   my_sys.sensors[2]->b_new_data_needed = 1;
					 */

					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_BOOT0_LOW:
				{
					  //HAL_GPIO_WritePin(CHN_OUT_BT0_GPIO_Port, CHN_OUT_BT0_Pin, GPIO_PIN_RESET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_BOOT0_HIGH:
				{
					  //HAL_GPIO_WritePin(CHN_OUT_BT0_GPIO_Port, CHN_OUT_BT0_Pin, GPIO_PIN_SET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_RESET_LOW:
				{
					  //HAL_GPIO_WritePin(CHN_OUT_RST_GPIO_Port, CHN_OUT_RST_Pin, GPIO_PIN_RESET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_RESET_HIGH:
				{
					//HAL_GPIO_WritePin(CHN_OUT_RST_GPIO_Port, CHN_OUT_RST_Pin, GPIO_PIN_SET);
					break;
				}
				//---------this is a code for testing LED and making fun demo we can not have them in production release version
				//---------since it may make serious conflicts and issue with magnetometer reader and scheduler ----------------
				case I2C_PACKET_SET_RED_ON:
				{
					  //HAL_GPIO_WritePin(SPI_C_CS_GPIO_Port, SPI_C_CS_Pin, GPIO_PIN_RESET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_RED_OFF:
				{
					  //HAL_GPIO_WritePin(SPI_C_CS_GPIO_Port, SPI_C_CS_Pin, GPIO_PIN_SET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_GREEN_ON:
				{
					  //HAL_GPIO_WritePin(SPI_A_CS_GPIO_Port, SPI_A_CS_Pin, GPIO_PIN_RESET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_GREEN_OFF:
				{
					  //HAL_GPIO_WritePin(SPI_A_CS_GPIO_Port, SPI_A_CS_Pin, GPIO_PIN_SET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_BLUE_ON:
				{
					  //HAL_GPIO_WritePin(SPI_B_CS_GPIO_Port, SPI_B_CS_Pin, GPIO_PIN_RESET);
					break;
				}
				//-------------------------------
				case I2C_PACKET_SET_BLUE_OFF:
				{
					  //HAL_GPIO_WritePin(SPI_B_CS_GPIO_Port, SPI_B_CS_Pin, GPIO_PIN_SET);
					break;
				}
				case I2C_PACKET_RESET_GLOBAL_TIMER:
				{
					thisSystem->ph_global_timer->h_timer->Instance->CNT = 0;
					thisSystem->ph_global_timer->overflow_counter = 0;
					break;
				}

				//----------test cases---------------------
				case I2C_PACKET_SENSOR_TEST_ROUTINE:
				{
					if(my_sys.sensors[0]->sensor_status == MAGNETOMETER_FAULTY )
					{
						//HAL_GPIO_WritePin(SPI_A_CS_GPIO_Port, SPI_A_CS_Pin, GPIO_PIN_RESET);
						HAL_Delay(200);
						//HAL_GPIO_WritePin(SPI_A_CS_GPIO_Port, SPI_A_CS_Pin, GPIO_PIN_SET);
						HAL_Delay(250);
					}
					if(my_sys.sensors[1]->sensor_status == MAGNETOMETER_FAULTY )
					{
						//HAL_GPIO_WritePin(SPI_B_CS_GPIO_Port, SPI_B_CS_Pin, GPIO_PIN_RESET);
						HAL_Delay(200);
						//HAL_GPIO_WritePin(SPI_B_CS_GPIO_Port, SPI_B_CS_Pin, GPIO_PIN_SET);
						HAL_Delay(250);
					}
					if(my_sys.sensors[2]->sensor_status == MAGNETOMETER_FAULTY )
					{
						//HAL_GPIO_WritePin(SPI_C_CS_GPIO_Port, SPI_C_CS_Pin, GPIO_PIN_RESET);
						HAL_Delay(200);
						//HAL_GPIO_WritePin(SPI_C_CS_GPIO_Port, SPI_C_CS_Pin, GPIO_PIN_SET);
						HAL_Delay(250);
					}
				}
				break;
				case I2C_PACKET_BEGIN_MAG_CONVERSION:
				{
					b_read_permit =1;
				}
				break;
				case I2C_PACKET_SEND_STIM_DATA_FRAME:
				{
					if (IS_BIT_SET(thisSystem->stimulator.flags, NEW_DATA_READY_FLAG))
					{
						/* New data is ready so transmit data over internal bus */


						/* Once transfer is complete we can clear NEW_DATA_READY_FLAG*/
						uint16_t flags = thisSystem->stimulator.flags;
						thisSystem->stimulator.flags = BIT_CLR(flags, NEW_DATA_READY_FLAG);
					}
				}
				break;
				case I2C_PACKET_BEGIN_STIMULATION:
				{
					NVIC_DisableIRQ(I2C2_IRQn);
					my_sys.i2c_line->multibyte_rx = TRUE;
					uint16_t flags = thisSystem->stimulator.flags;
					if (IS_BIT_SET(flags, STIM_READY_FLAG))
					{
						/* If stimulator is ready we can begin stimulation.*/

						int16_t cmd_array[4] = { 3000, 5000, 0, 10000 }; // Send dummy command for now
						event_t event;
						event.name = STIM_RUN_CMD;
						memcpy(event.data, cmd_array, sizeof(cmd_array));
						event.data_size = sizeof(cmd_array);
						push_event(&(thisSystem->stimulator.event_queue), event);

					}
				}
				break;
			}
			//-------- if we get any data higher than 0x80  it mean it is a new address
			if ( thisSystem->i2c_line->receiveBuffer[0] > I2C_PACKET_SET_NEW_ADDRESS )
			{
				__HAL_I2C_DISABLE_IT(thisSystem->i2c_line->I2C_line, I2C_IT_RXI | I2C_IT_STOPI | I2C_IT_ADDRI);
				uint8_t i2c_new_address =  (uint8_t)my_sys.i2c_line->receiveBuffer[0] & 0x7f;
				thisSystem->i2c_line->I2C_line->Instance->OAR1 &= ~I2C_OAR1_OA1EN;
				thisSystem->i2c_line->I2C_line->Instance->OAR1 = (I2C_OAR1_OA1EN | ( i2c_new_address << 1) );
				__HAL_I2C_ENABLE_IT(thisSystem->i2c_line->I2C_line, I2C_IT_RXI | I2C_IT_STOPI | I2C_IT_ADDRI);
			}
		my_sys.i2c_line->buffer_index =0;
		}

		/* Stimulator State Machine Start */
		stimulator_state_machine(&((&my_sys)->stimulator));
	}

		switch(thisSystem->state)
		{
			case MODULE_SYSTEM_STATUS_START:
				//Check if system has undergone first time setup by looking for a 32-bit random number in EEPROM
				//IF A NEW FIRST TIME SETUP IS DESIRED TO BE RUN just change the value of EEPROM_FIRST_TIME_COMPLETE in <EEPROM.h>
				//uint32_t test = *(uint32_t*) FIRST_TIME_INITIATION;
				//thisSystem->state = (*(uint32_t*) FIRST_TIME_INITIATION != EEPROM_FIRST_TIME_COMPLETE) ?						MODULE_SYSTEM_STATUS_FIRST_TIME :						MODULE_SYSTEM_STATUS_INITIATION;
			break;
			//-----------
			case MODULE_SYSTEM_STATUS_FIRST_TIME:
				//EEPROMInit(thisSystem);
				thisSystem->state = MODULE_SYSTEM_STATUS_INITIATION;

			break;
			//-----------
			case MODULE_SYSTEM_STATUS_INITIATION:
				module_system_init(thisSystem);
				thisSystem->BUS_FLAG = 0;
				thisSystem->ID = 0;			//TODO module type will be assigned by master micro and we need to reload that from eeprom/flash memory
				thisSystem->status = 0;
				thisSystem->type = 0; 			//TODO module type will be assigned by master micro and we need to reload that from eeprom/flash memory
				thisSystem->state = MODULE_SYSTEM_STATUS_IDLE;
			break;
			//-----------
			case MODULE_SYSTEM_STATUS_IDLE:
				if (thisSystem->BUS_FLAG == 1)
				{
					//MockData(&thisSystem->Magnetometer);
					//WriteDataFrame(&thisSystem->Magnetometer, &thisSystem->Bus) ;
					//GPIOC->BSRR = GPIO_PIN_0;
					//GPIOC->BRR = GPIO_PIN_0;
					//Set all bus pins to low and send complete
					///thisBus->_GPIO_Bus->BRR = (uint32_t) (0x000000FF);
					//GPIOA->BRR = GPIO_PIN_15;
					//GPIOA->BRR = (uint32_t) (0x00002000);
					//Set Bus pins to input
					//temp = GPIOB->MODER;
					///temp &= ~BUS_BUSMASK32;
					//GPIOB->MODER = temp;
					//Set CBus pins to input
					//temp = GPIOA->MODER;
					//temp &= ~BUS_CBUSMASK32;
					//GPIOA->MODER = temp;
					//Complete(&thisSystem->Bus);
					//GPIOC->BSRR = GPIO_PIN_0;
					//GPIOC->BRR = GPIO_PIN_0;
					//HAL_I2C_Slave_Receive_IT(&hi2c2, thisSystem->I2C.receiveBuffer, I2C_RECEIVE_LENGTH);
				}
				//HAL_Delay(1);
				//thisSystem->BUS_FLAG = 1;
				//GPIOC->BSRR = GPIO_PIN_0;
				//GPIOC->BRR = GPIO_PIN_0;
				//GPIOC->BSRR = ((GPIOC->ODR & GPIO_PIN_0) << 16) | (~GPIOC->ODR & GPIO_PIN_0);
				/*if (__HAL_GPIO_EXTI_GET_FLAG(thisSystem->sensorA_MMC5983.INT_GPIO_Pin))
				{
					readMMC5983_XYZ(&thisSystem->sensorA_MMC5983);
					__HAL_GPIO_EXTI_CLEAR_IT(thisSystem->sensorA_MMC5983.INT_GPIO_Pin);
				}*/
				/*if (__HAL_GPIO_EXTI_GET_FLAG(thisSystem->Magnetometer.sensorB_MMC5983.INT_GPIO_Pin))
				{
					readMMC5983_XYZ(&thisSystem->Magnetometer, &thisSystem->Magnetometer.sensorB_MMC5983);
					__HAL_GPIO_EXTI_CLEAR_IT(thisSystem->Magnetometer.sensorB_MMC5983.INT_GPIO_Pin);
				}*/
				/*if (__HAL_GPIO_EXTI_GET_FLAG(thisSystem->sensorA.DRDY_GPIO_Pin))
				{
					readLIS3MDL_XYZ(&thisSystem->sensorA);
					__HAL_GPIO_EXTI_CLEAR_IT(thisSystem->sensorA.DRDY_GPIO_Pin);
				}
				if (__HAL_GPIO_EXTI_GET_FLAG(thisSystem->sensorB.DRDY_GPIO_Pin))
				{
					readLIS3MDL_XYZ(&thisSystem->sensorB);
					__HAL_GPIO_EXTI_CLEAR_IT(thisSystem->sensorB.DRDY_GPIO_Pin);
				}
				if (__HAL_GPIO_EXTI_GET_FLAG(thisSystem->sensorC.DRDY_GPIO_Pin))
				{
					readLIS3MDL_XYZ(&thisSystem->sensorC);
					__HAL_GPIO_EXTI_CLEAR_IT(thisSystem->sensorC.DRDY_GPIO_Pin);
				}*/
			break;
			//-----------
			case MODULE_SYSTEM_STATUS_CALIBRATION:
			break;
			//-----------
			case MODULE_SYSTEM_STATUS_FIRMWARE_UPDATE:
			break;
			//-----------
			case MODULE_SYSTEM_STATUS_FAULTY:
			break;
		}
}
