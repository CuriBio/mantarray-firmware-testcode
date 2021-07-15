#include <stdlib.h>
#include <stdio.h>
#include "main.h"
#ifndef EEPROM_H_
#define EEPROM_H_

//TODO we don't need these specific address we can have a flexible file names for user
#define EEPROM_I2C_ADDR               	(DATA_EEPROM_BASE + 0x00000010UL) //uint8 DATA_EEPROM_BASE is a memory alias and will always point to the EEPROM base agnostic of chip ID
#define EEPROM_FIRST_TIME_INITIATION  	(DATA_EEPROM_BASE + 0x00000020UL) //uint32
#define EEPROM_WHICH_MAGNETOMETER	   	(DATA_EEPROM_BASE + 0x00000030UL) //uint8
#define EEPROM_OTHERINFO1             	(DATA_EEPROM_BASE + 0x00000040UL) //Increment by 0x20 to shift memory by one word, 0x10 by half-word, and 0x08 by byte
#define EEPROM_OTHERINFO2             	(DATA_EEPROM_BASE + 0x00000050UL) //Make sure to use the appropriate FLASHEx_Type_Program_Data Where the options are:
#define EEPROM_OTHERINFO3             	(DATA_EEPROM_BASE + 0x00000060UL) //FLASH_TYPEPROGRAMDATA_BYTE, FLASH_TYPEPROGRAMDATA_HALFWORD, and FLASH_TYPEPROGRAMDATA_WORD

#define EEPROM_FIRST_TIME_BOOT_MARKER		0x67

// save and load file in and from the eeprom
// for now we relay on predefined names for file names later we will change it to a real file name and variable file size
uint8_t EEPROM_save(uint32_t file_name, uint8_t *buffer, uint8_t buffer_size);
uint8_t EEPROM_load(uint32_t file_name, uint8_t *buffer, uint8_t buffer_size);
//TODO need to implement after finishing the FAT for this lib
uint8_t EEPROM_delete(uint32_t *file_name);

#endif /* EEPROM_H_ */
