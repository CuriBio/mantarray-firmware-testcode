#include "EEPROM.h"

// save a file in the eeprom
// for now we relay on predefined names for file names later we will change it to a real file name and variable file size
// TODO we need uint8_t EEPROM_save(unsigned char *file_name, uint8_t *buffer, uint8_t how_many_byte_write)
uint8_t EEPROM_save(uint32_t file_name, uint8_t *buffer, uint8_t buffer_size)
{
	uint8_t result = 0;
	//before anything else first check if the address you are trying to write to is in fact within the EEPROM memory map
	if (IS_FLASH_DATA_ADDRESS(file_name))
	{
		//Call unlock before programming operations to ensure that you have control of the EEPROM memory
		if ( HAL_OK == HAL_FLASHEx_DATAEEPROM_Unlock() )
		{
			//if( HAL_OK == HAL_FLASHEx_DATAEEPROM_Erase(FLASH_TYPEPROGRAMDATA_BYTE) )
			{
				if( HAL_OK == HAL_FLASHEx_DATAEEPROM_Program(FLASH_TYPEPROGRAMDATA_BYTE, (uint32_t) file_name, (uint32_t) buffer[0]) )
				{
					result =1;
				}
				//we already unlocked the EEPROM memory no matter if we succes to write or not we need to relock
				if( HAL_OK != HAL_FLASHEx_DATAEEPROM_Lock())
				{
					result =0;  //if we can not relock again it is a problem no matter if we succes to write
				}
			}
		}
	}
	//Lock the EEPROM afterwards to protect it from accidental memory writes
	return(result);
}


// load a file from the eeprom
// for now we relay on predefined names for file names later we will change it to a real file name and variable file size
// TODO we need uint8_t EEPROM_load(unsigned char *file_name, uint8_t *buffer, uint8_t how_many_byte_read)
uint8_t EEPROM_load(uint32_t file_name, uint8_t *buffer, uint8_t buffer_size)
{

	uint8_t result = 0;
	//before anything else first check if the address you are trying to write to is in fact within the EEPROM memory map
	if (IS_FLASH_DATA_ADDRESS(file_name))
	{
		buffer[0] = *(uint8_t*) file_name;
		result = 1;
	}
	//Lock the EEPROM afterwards to protect it from accidental memory writes
	return(result);
}

