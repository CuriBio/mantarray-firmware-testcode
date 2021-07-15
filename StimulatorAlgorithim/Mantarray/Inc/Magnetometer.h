#ifndef MAGNETOMETER_H_
#define MAGNETOMETER_H_

#include "lis3mdl_driver.h"
#include "mmc5983_driver.h"

#define MAGNETOMETER_TYPE_LIS3MDL	10
#define MAGNETOMETER_TYPE_MMC5983	20

#define MAGNETOMETER_FAULTY			80
#define MAGNETOMETER_OK				81

#define MAGNETOMETER_DEFAULT_SAMPLE_RATE	100
#define X_AX	0
#define Y_AX	1
#define Z_AX	2

#pragma pack (push, 1)

typedef struct
{
	uint8_t whichMagnetometer; //MAGNETOMETER_TYPE_LIS3MDL   or   MAGNETOMETER_TYPE_MMC5983
	void *magnetometer;
	//TODO mmc5983 use different data format 18bits If we decide to use a different  x y z data type for each sensor
	//or just x for single axies sensor like TI- DRV425 we may consider moving this inside the sensor deiver
	//and then we may need to change this to32 bit variable since mmc5983  chip can provide 18bits results
	uint16_t Readings[3];
	uint64_t time_stamp;
	uint8_t b_new_data_needed;

	uint16_t sampleRate;
	uint16_t sensorConfig;
	uint8_t sensor_status;

}Magnetometer_t;

#pragma pack (pop)
//thses two function should be impliment with polymorphism
Magnetometer_t * magnetometer_create(uint8_t,SPI_HandleTypeDef *,GPIO_TypeDef *,uint16_t,GPIO_TypeDef *,uint16_t);
//------------------destroy a megnetometer turn it off release hardware pin and release memory ----------------------------------
void magnetometer_destroy(Magnetometer_t *);
//----------------------- by passing a magnetometer object to this method it will update X Y Z --otherwise will return fail----------------
uint8_t magnetometer_read(Magnetometer_t *thisMagnetometer);

#endif /* MAGNETOMETER_H_ */
