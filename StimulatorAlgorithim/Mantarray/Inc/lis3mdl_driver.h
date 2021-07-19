//this is the driver layer to connect with specific chip

#include <stdio.h>
#include <stdlib.h>
#include "stm32l0xx_hal.h"

#ifndef LIS3MDL_H_
#define LIS3MDL_H_

#define LIS3MDL_WHO_AM_I 			0x0F
#define LIS3MDL_WHO_ID_RESPONSE  	0x3D
#define LIS3MDL_STATUS_REG 			0x27

#define LIS3MDL_OUT_X_L 			0x28
#define LIS3MDL_OUT_X_H 			0x29
#define LIS3MDL_OUT_Y_L 			0x2A
#define LIS3MDL_OUT_Y_H 			0x2B
#define LIS3MDL_OUT_Z_L 			0x2C
#define LIS3MDL_OUT_Z_H				0x2D
#define LIS3MDL_TEMP_OUT_L 			0x2E
#define LIS3MDL_TEMP_OUT_H 			0x2f

#define LIS3MDL_READ_SINGLEBIT 		0x80
#define LIS3MDL_READ_CONT 			0xC0
#define LIS3MDL_WRITE_SINGLEBIT 	0x00
#define LIS3MDL_WRITE_CONT 			0x40

#define LIS3MDL_CTRL_REG1 			0x20
#define LIS3MDL_CTRL_REG2 			0x21
#define LIS3MDL_CTRL_REG3 			0x22
#define LIS3MDL_CTRL_REG4 			0x23
#define LIS3MDL_CTRL_REG5 			0x24

#define LIS3MDL_MAXREADINGS			10

#define LIS3MDL_SENSOR_FOUND		0x20
#define LIS3MDL_SENSOR_NOT_FOUND	0x30
//anything specific for this chip driver layer will be here this class driven from magnetometer

typedef struct
{
	uint8_t sensor_status;
	SPI_HandleTypeDef *spi_channel;

	GPIO_TypeDef *CS_GPIO_Bus;
	uint16_t CS_GPIO_Pin;

	GPIO_TypeDef *DRDY_GPIO_Bus;
	uint16_t DRDY_GPIO_Pin;
} LIS3MDL_t;

LIS3MDL_t * LIS3MDL_create(SPI_HandleTypeDef *,GPIO_TypeDef *,uint16_t,GPIO_TypeDef *,uint16_t);
void LIS3MDL_destroy(LIS3MDL_t *);
uint8_t LIS3MDL_register_read(LIS3MDL_t *, uint8_t );
void LIS3MDL_register_write(LIS3MDL_t *, uint8_t, uint8_t);
//----------------------- by passing a magnetometer object to this method it will update X Y Z ------------------
//-----------  we really do not need to the second parameter since by having the address of the magnetometer object ----------
//------- we can calculate the offset of x y z data place holder there is risk on that approach if someone in future ------------
//--- add more eleman at the bigining of the structure or change the data type we need to consider those changes ---------
uint8_t LIS3MDL_read_XYZ(LIS3MDL_t *,uint16_t *);

#endif /* LIS3MDL_H_ */
