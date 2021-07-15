#include "lis3mdl_driver.h"

//TODO we need to test the whole library
LIS3MDL_t * LIS3MDL_create(SPI_HandleTypeDef *spi_line,GPIO_TypeDef *CS_Bus,uint16_t CS_Pin,GPIO_TypeDef *DRDY_Bus,uint16_t DRDY_Pin)
{
	LIS3MDL_t * thisLIS3MDL = (LIS3MDL_t *)malloc(sizeof(LIS3MDL_t));
	thisLIS3MDL->CS_GPIO_Bus = CS_Bus;
	thisLIS3MDL->CS_GPIO_Pin = CS_Pin;
	thisLIS3MDL->DRDY_GPIO_Bus = DRDY_Bus;
	thisLIS3MDL->DRDY_GPIO_Pin = DRDY_Pin;
	thisLIS3MDL->spi_channel = spi_line;
	HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_SET);   //Set CS pin on sensor A to high to ensure no SPI communication enabled initially
	if(thisLIS3MDL != NULL)
	{
		//Set all of the configuration registers every time on bootup
		LIS3MDL_register_write(thisLIS3MDL, LIS3MDL_CTRL_REG2,0b00001100);  //32/64: Gauss Scale Selection   8: Reboot Memory Content   4: Configuration Registers and User Register Reset
		HAL_Delay(1);
		LIS3MDL_register_write(thisLIS3MDL, LIS3MDL_CTRL_REG1,0b00011110);  //128: Temp Sensor Enable   32/64: X-Y-axis Performance Selection   4/8/16: Output Data Rate Selection   2: Data Rate Overdrive
		LIS3MDL_register_write(thisLIS3MDL, LIS3MDL_CTRL_REG2,0b01100000);  //32/64: Gauss Scale Selection   8: Reboot Memory Content   4: Configuration Registers and User Register Reset
		LIS3MDL_register_write(thisLIS3MDL, LIS3MDL_CTRL_REG3,0b00000000);  //32: Low Power Mode   4: 3-4 Wire SPI   1/2: Operating Mode Selection
		LIS3MDL_register_write(thisLIS3MDL, LIS3MDL_CTRL_REG4,0b00001100);  //2: Big-Little Endian Data Selection   4/8: Z-axis Performance Selection
		LIS3MDL_register_write(thisLIS3MDL, LIS3MDL_CTRL_REG5,0b00000000);  //128: Fast Read   64: Block Data Update
		//Check whether you are communicating with the ST sensor
		uint8_t SPITestWHOAMI = LIS3MDL_register_read(thisLIS3MDL, (uint8_t)LIS3MDL_WHO_AM_I);
		if (SPITestWHOAMI==LIS3MDL_WHO_ID_RESPONSE)
		{
			//TODO Implement Sensor found subroutine
			thisLIS3MDL->sensor_status = LIS3MDL_SENSOR_FOUND;
		}
		else
		{
			thisLIS3MDL->sensor_status = LIS3MDL_SENSOR_NOT_FOUND;
		}
	}
	return(thisLIS3MDL);
}

uint8_t LIS3MDL_register_read(LIS3MDL_t *thisLIS3MDL, uint8_t thisRegister)
{
	uint8_t result;
	uint8_t out[2];
	uint8_t in[2] = {0 , 0};
	out[0] = 128 | thisRegister;   //adding 128 to writing 1 in MSB bit 7
	out[1]= 0;   //transfer dummy byte to get response
	HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_RESET); //! Set CS pin low to begin SPI read on target device
	HAL_SPI_TransmitReceive(thisLIS3MDL->spi_channel , out, in, 2, 10);
	HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_SET); //! Set CS pin high to signal SPI read as done
	result = in[1];
	return result;
}

void LIS3MDL_register_write(LIS3MDL_t *thisLIS3MDL, uint8_t thisRegister, uint8_t val)
{
	uint8_t out[2];
	out[0] = thisRegister;
	out[1] = val;
	HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_RESET); //! Set CS pin low to begin SPI read on target device
	HAL_SPI_Transmit(thisLIS3MDL->spi_channel, out, 2, 10);
	HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_SET); //! Set CS pin high to signal SPI read as done
}


//--------------object destroyer---------------------------
void LIS3MDL_destroy(LIS3MDL_t *thisLIS3MDL)
{
	free(thisLIS3MDL);//we may need to turn off or reset chip before freeing memory each chip must have its own destroyer
}
//-----------------------------------------------------
uint8_t LIS3MDL_read_XYZ(LIS3MDL_t *thisLIS3MDL,uint16_t *data)
{
	//TODO  need clean up and test
	/*if (thisLIS3MDL->magneticFront < LIS3MDL_MAXREADINGS)
	{
		thisLIS3MDL->out[0] = LIS3MDL_READ_CONT | LIS3MDL_OUT_X_L;   //Doing a continuous read and starting at the first measurement register (X_Low)
		HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_RESET); //! Set CS pin low to begin SPI read on target device
		HAL_SPI_TransmitReceive(&hspi1, thisLIS3MDL->out, thisLIS3MDL->in, 7, 10);   //Read all the data at once
		HAL_GPIO_WritePin(thisLIS3MDL->CS_GPIO_Bus, thisLIS3MDL->CS_GPIO_Pin, GPIO_PIN_SET); //! Set CS pin high to signal SPI read as done
		//Concatenate low and high bits
		thisLIS3MDL->magneticX[thisLIS3MDL->magneticFront]= (thisLIS3MDL->in[2]<<8) | thisLIS3MDL->in[1];
		thisLIS3MDL->magneticY[thisLIS3MDL->magneticFront]= (thisLIS3MDL->in[4]<<8) | thisLIS3MDL->in[3];
		thisLIS3MDL->magneticZ[thisLIS3MDL->magneticFront]= (thisLIS3MDL->in[6]<<8) | thisLIS3MDL->in[5];

		//TEST CODE
		thisLIS3MDL->timestamp = getGlobalTimer(&my_sys.GlobalTimer);
		thisLIS3MDL->uartBufLen = sprintf(thisLIS3MDL->uartBuffer, "%c %i %i %i %u\r\n",
										  thisLIS3MDL->id,
										  thisLIS3MDL->magneticX[thisLIS3MDL->magneticFront],
										  thisLIS3MDL->magneticY[thisLIS3MDL->magneticFront],
										  thisLIS3MDL->magneticZ[thisLIS3MDL->magneticFront],
										  thisLIS3MDL->timestamp);
		serialSend(&huart2, thisLIS3MDL->uartBuffer, thisLIS3MDL->uartBufLen);

		thisLIS3MDL->magneticFront++;
		if (thisLIS3MDL->magneticFront == LIS3MDL_MAXREADINGS)
		{
			thisLIS3MDL->magneticFront = 0;
		}
	}*/
}
