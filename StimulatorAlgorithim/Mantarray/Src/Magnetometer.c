#include "magnetometer.h"

//!---------------------------------------------------------------------------------------------------------------------
//!-------------- create a new magenotometer object and add that to the system this methode need to know what is the
//!TODO if in future we decided to use analog sensors or different kind of sensors this function need to change to a variadic function like printf
//!since different sensors may have different type and number of variables
//!1 - sensor type  depend to the sensor type
//!2 - data tranmitter handler in this implimentation we just limited that to SPI in future if we add I2C or analog sensor ADC line can passs as a parameter
//!--------------------------create a new magnotmemeter of any type lower layer support and make a interface and initilize that-----------------------------------
Magnetometer_t * magnetometer_create(uint8_t type,SPI_HandleTypeDef *spi_line,GPIO_TypeDef *CS_Bus,uint16_t CS_Pin,GPIO_TypeDef *INT_Bus,uint16_t INT_Pin)
{
	Magnetometer_t *  thisMagnetometer = malloc(sizeof(Magnetometer_t));
	if(thisMagnetometer != NULL)
	{
		thisMagnetometer->whichMagnetometer = type;
		switch (thisMagnetometer->whichMagnetometer)
		{
		case MAGNETOMETER_TYPE_LIS3MDL:
			{
				thisMagnetometer->magnetometer = (LIS3MDL_t*)LIS3MDL_create(spi_line,CS_Bus,CS_Pin,INT_Bus,INT_Pin);
				if(thisMagnetometer->magnetometer != NULL)
				{
					thisMagnetometer->sampleRate = MAGNETOMETER_DEFAULT_SAMPLE_RATE;
					thisMagnetometer->time_stamp = 0;
					thisMagnetometer->Readings[X_AX] = 0;
					thisMagnetometer->Readings[Y_AX] = 0;
					thisMagnetometer->Readings[Z_AX] = 0;
				}
			}
		break;
		//------------------------------
		case MAGNETOMETER_TYPE_MMC5983:
			{
				thisMagnetometer->magnetometer = (MMC5983_t*)MMC5983_create(spi_line,CS_Bus,CS_Pin,INT_Bus,INT_Pin);
				if(thisMagnetometer->magnetometer != NULL)
				{
					thisMagnetometer->sampleRate = MAGNETOMETER_DEFAULT_SAMPLE_RATE;
					thisMagnetometer->time_stamp = 0;
					thisMagnetometer->Readings[X_AX] = 0;
					thisMagnetometer->Readings[Y_AX] = 0;
					thisMagnetometer->Readings[Z_AX] = 0;
					thisMagnetometer->sensor_status = ( MMC5983_get_status(thisMagnetometer->magnetometer) ? MAGNETOMETER_OK : MAGNETOMETER_FAULTY);
				}
			}
		break;
		}
	}
	return(thisMagnetometer);
}
//------------------destroy a megnetometer turn it off release hardware pin and release memory ----------------------------------
void magnetometer_destroy(Magnetometer_t *thisMagnetometer)
{
	switch (thisMagnetometer->whichMagnetometer)    //we need to freeup child memory first before freeing mother class otherwise we will lost trace of that
	{
	case MAGNETOMETER_TYPE_LIS3MDL:
		LIS3MDL_destroy((LIS3MDL_t*)thisMagnetometer->magnetometer);//we may need to turn off or reset chip before freeing memory each chip must have its own destroyer
		break;
	//------------------------------
	case MAGNETOMETER_TYPE_MMC5983:
		MMC5983_destroy((MMC5983_t*)thisMagnetometer->magnetometer);//we may need to turn off or reset chip before freeing memory each chip must have its own destroyer
		break;
	}
	//any extera hardware or software init before killin the magnetometer will go here
	free(thisMagnetometer);
}
//----------------regardless of magnetometer type this methode is our interface between higher layer and driver layer---------------------------------------
//--------------- by calling this methode we will have fresh data provided by low level layer driver ready to use --------------------------
uint8_t magnetometer_read(Magnetometer_t *thisMagnetometer)
{
	uint8_t res=0;
	switch (thisMagnetometer->whichMagnetometer)
	{
	case MAGNETOMETER_TYPE_LIS3MDL:
		res = LIS3MDL_read_XYZ((LIS3MDL_t*)thisMagnetometer->magnetometer,thisMagnetometer->Readings);
		break;
	//------------------------------
	case MAGNETOMETER_TYPE_MMC5983:
		res = MMC5983_read_XYZ((MMC5983_t*)thisMagnetometer->magnetometer, (uint8_t*)thisMagnetometer->Readings);
		break;
	}
	return res;
}
//--------------------test sensor---------------------------
/*uint8_t get_status(Magnetometer_t *thisMagnetometer)
{
	uint8_t res=0;
	switch (thisMagnetometer->whichMagnetometer)
	{
	case MAGNETOMETER_TYPE_LIS3MDL:
		if((LIS3MDL_t*)thisMagnetometer->sensor_status == LIS3MDL_SENSOR_FOUND)
			res=1;
		break;
	//------------------------------
	case MAGNETOMETER_TYPE_MMC5983:
		if((MMC5983_t*)thisMagnetometer->sensor_status == MMC5983_SENSOR_FOUND)
			res=1;
		break;
	}
	return res;
}*/
