#include "mmc5983_driver.h"
#include "stdlib.h"

MMC5983_t * MMC5983_create(SPI_HandleTypeDef *spi_line,GPIO_TypeDef *CS_Bus,uint16_t CS_Pin,GPIO_TypeDef *INT_Bus,uint16_t INT_Pin)
{
	//TODO Do we want to use a series of #defines with | in between to describe configuration registers to make this function more human readable?

	MMC5983_t * thisMMC5983 = (MMC5983_t *) malloc(sizeof(MMC5983_t));
	thisMMC5983->CS_GPIO_Bus = CS_Bus;
	thisMMC5983->CS_GPIO_Pin = CS_Pin;
	thisMMC5983->INT_GPIO_Bus = INT_Bus;
	thisMMC5983->INT_GPIO_Pin = INT_Pin;
	thisMMC5983->spi_channel = spi_line;
	HAL_GPIO_WritePin(thisMMC5983->CS_GPIO_Bus, thisMMC5983->CS_GPIO_Pin, GPIO_PIN_SET);   //Set CS pin on sensor A to high to ensure no SPI communication enabled initially
	if(thisMMC5983 != NULL)
	{
		//Set all of the configuration registers every time on bootup
		MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL1, MMC5983_CTRL1_SW_RST); //128: Reset chip, operation takes 10 msec
		HAL_Delay(20);
		MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL0, MMC5983_CTRL0_Set);  //8: Set  magnetic sensor
		HAL_Delay(5);
		MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL3, 0);  //64: SPI 3-wire mode   4/2: Saturation checks.
		MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL0, MMC5983_CTRL0_Auto_SR_en);  //7:Reserved    6:OTP    5:Auto_SR  4:Reset    3:Set   2:INT_meas_done_en   1:TM_T   0:TM_M
		MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL1, 0);  //7:SW_	RST    6:Reserved    5:Reserved  4:YZ-inhibit    3:YZ-inhibit   2:X-inhibit   1:BW1   0:BW0 {100 200 400 800}Hz
		MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL2, 0);  //7:En_prd_set     4-6:Prd_set    3:Cmm_en     0-2: CM_Freq {off 1 10 20 50 100 200 1000}Hz
		//Check whether you are communicating with the MEMSIC sensor
		uint8_t SPITestWHOAMI = MMC5983_register_read(thisMMC5983, MMC5983_WHOAMI);
		if (SPITestWHOAMI==MMC5983_WHO_ID_RESPONSE)
		{
			//TODO Implement Sensor found subroutine
			thisMMC5983->sensor_status = MMC5983_SENSOR_FOUND;
		}
		else
		{
			thisMMC5983->sensor_status = MMC5983_SENSOR_NOT_FOUND;
		}
	}
	MMC5983_register_write(thisMMC5983, MMC5983_INTERNALCONTROL0, MMC5983_CTRL0_TM_M);
	return(thisMMC5983);
}

uint8_t MMC5983_register_read(MMC5983_t *thisMMC5983, uint8_t thisRegister)
{
	uint8_t result;
	uint8_t out[2];
	uint8_t in[2] = {0 , 0};
	out[0] = MMC5983_READ | thisRegister;   //adding 128 to writing 1 in MSB bit 7
	out[1]= 0;   //transfer dummy byte to get response
	HAL_GPIO_WritePin(thisMMC5983->CS_GPIO_Bus, thisMMC5983->CS_GPIO_Pin, GPIO_PIN_RESET); //! Set CS pin low to begin SPI read on target device
	HAL_SPI_TransmitReceive(thisMMC5983->spi_channel , out, in, 2, 10);
	HAL_GPIO_WritePin(thisMMC5983->CS_GPIO_Bus, thisMMC5983->CS_GPIO_Pin, GPIO_PIN_SET); //! Set CS pin high to signal SPI read as done
	result = in[1];
	return result;
}

void MMC5983_register_write(MMC5983_t *thisMMC5983, uint8_t thisRegister, uint8_t val)
{
	uint8_t out[2];
	out[0] = thisRegister;
	out[1] = val;
	HAL_GPIO_WritePin(thisMMC5983->CS_GPIO_Bus, thisMMC5983->CS_GPIO_Pin, GPIO_PIN_RESET); //! Set CS pin low to begin SPI read on target device
	HAL_SPI_Transmit(thisMMC5983->spi_channel, out, 2, 10);
	HAL_GPIO_WritePin(thisMMC5983->CS_GPIO_Bus, thisMMC5983->CS_GPIO_Pin, GPIO_PIN_SET); //! Set CS pin high to signal SPI read as done
}
//--------------object destroyer---------------------------
void MMC5983_destroy(MMC5983_t *thisMMC5983)
{
	free(thisMMC5983);//we may need to turn off or reset chip before freeing memory each chip must have its own destroyer
}

//----------------------- by passing a magnetometer object to this method it will update X Y Z ------------------
//-----------  we really do not need to send the second parameter since by having the address of the magnetometer object ----------
//------- we can calculate the offset of x y z data place holder there is risk on that approach if someone in future ------------
//--- add more eleman at the bigining of the structure or change the data type we need to consider those changes ---------
//----and after c++ 11 compiler can not guarantee the address of the first member of the struct is equal to the struct address -------------
uint8_t MMC5983_read_XYZ(MMC5983_t *thisMMC5983,uint8_t * data)
{
	//TODO  need a better implimentation
	uint8_t sensor_status;
	sensor_status = MMC5983_register_read(thisMMC5983, MMC5983_STATUS);
	if(sensor_status & MMC5983_STATUS_Meas_M_Done )
	{
		data[0] =MMC5983_register_read(thisMMC5983, MMC5983_XOUT1);
		data[1] =MMC5983_register_read(thisMMC5983, MMC5983_XOUT0);
		data[2] =MMC5983_register_read(thisMMC5983, MMC5983_YOUT1);
		data[3] =MMC5983_register_read(thisMMC5983, MMC5983_YOUT0);
		data[4] =MMC5983_register_read(thisMMC5983, MMC5983_ZOUT1);
		data[5] =MMC5983_register_read(thisMMC5983, MMC5983_ZOUT0);
		return 1;
	}
	return 0;
}
//---------------------------
uint8_t MMC5983_get_status(MMC5983_t *thisMMC5983)
{
	if(thisMMC5983->sensor_status == MMC5983_SENSOR_FOUND)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}
