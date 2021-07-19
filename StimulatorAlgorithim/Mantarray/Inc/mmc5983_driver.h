//this is the driver layer to connect with specific chip
#include "main.h"
#include "GlobalTimer.h"

#ifndef MMC5983_H_
#define MMC5983_H_
//---------------------------------------------------------
#define	MMC5983_MAXIMUM_NO_OF_MPU_REGISTERS		14
#define	MMC5983_XOUT0							0x00 		//Xout [17:10]
#define MMC5983_XOUT1							0x01 		//Xout [9:2]
#define MMC5983_YOUT0							0x02 		//Yout [17:10]
#define MMC5983_YOUT1							0x03 		//Yout [9:2]
#define MMC5983_ZOUT0							0x04 		//Zout [17:10]
#define MMC5983_ZOUT1							0x05 		//Zout [9:2]
#define MMC5983_XYZOUT2							0x06 		//Xout[1:0], Yout[1:0], Zout[1:0]
#define MMC5983_TOUT							0x07 		//Temperature output
#define MMC5983_STATUS							0x08 		//Device status

#define MMC5983_INTERNALCONTROL0				0x09 		//Control register 0
#define MMC5983_INTERNALCONTROL1				0x0A 		//Control register 1
#define MMC5983_INTERNALCONTROL2				0x0B		//Control register 2
#define MMC5983_INTERNALCONTROL3				0x0C 		//Control register 3
#define MMC5983_WHOAMI							0x2F 		//Product ID
#define MMC5983_WHO_ID_RESPONSE					0x30

#define MMC5983_WRITE							0x00
#define MMC5983_READ							0x80
//--------------------------status register bits ------------------------------
#define MMC5983_STATUS_Meas_M_Done				0x01
#define MMC5983_STATUS_Meas_T_Done				0x02
#define MMC5983_STATUS_OTP_Read_Done			0x10
//----------------Internal Control 0 --------
#define MMC5983_CTRL0_TM_M						0x01
#define MMC5983_CTRL0_TM_T						0x02
#define MMC5983_CTRL0_INT_meas_done_en			0x04
#define MMC5983_CTRL0_Set						0x08
#define MMC5983_CTRL0_Reset						0x10
#define MMC5983_CTRL0_Auto_SR_en				0x20
#define MMC5983_CTRL0_OTP_Read					0x40
#define MMC5983_CTRL0_Reserved					0x80
//----------------Internal Control 1 --------
#define MMC5983_CTRL1_BW0						0x01
#define MMC5983_CTRL1_BW1						0x02
#define MMC5983_CTRL1_X_inhibit					0x04
#define MMC5983_CTRL1_YZ_inhibit_l				0x08
#define MMC5983_CTRL1_YZ_inhibit_2				0x10

#define MMC5983_CTRL1_Reserved_5				0x20
#define MMC5983_CTRL1_Reserved_6				0x40
#define MMC5983_CTRL1_SW_RST					0x80
//----------------Internal Control 2 --------
#define MMC5983_CTRL2_Cm_freq0					0x01
#define MMC5983_CTRL2_Cm_freq1					0x02
#define MMC5983_CTRL2_Cm_freq2					0x04
#define MMC5983_CTRL2_Cmm_en					0x08
#define MMC5983_CTRL2_Prd_set0					0x10
#define MMC5983_CTRL2_Prd_set1					0x20
#define MMC5983_CTRL2_Prd_set2					0x40
#define MMC5983_CTRL2_En_prd_set				0x80
//----------------Internal Control 3 --------
#define MMC5983_CTRL3_Reservd					0x01
#define MMC5983_CTRL3_St_enp					0x02
#define MMC5983_CTRL3_ST_enm					0x04
#define MMC5983_CTRL3_Reserved_3				0x08
#define MMC5983_CTRL3_Reserved_4				0x10
#define MMC5983_CTRL3_Reserved_5				0x20
#define MMC5983_CTRL3_Spi_3w					0x40
#define MMC5983_CTRL3_Reserved_7				0x80
//-----------------------------------------------------------------------------
#define MMC5983_MAXREADINGS						10

#define MMC5983_SENSOR_FOUND					0x20
#define MMC5983_SENSOR_NOT_FOUND				0x30
//---------------------------------------------------------
//anything specific for this chip driver layer will be here this class driven from magnetometer
typedef struct
{
	uint8_t sensor_status;
	SPI_HandleTypeDef *spi_channel;

	GPIO_TypeDef * INT_GPIO_Bus;
	uint16_t INT_GPIO_Pin;

	GPIO_TypeDef * CS_GPIO_Bus;
	uint16_t CS_GPIO_Pin;
} MMC5983_t;


MMC5983_t * MMC5983_create(SPI_HandleTypeDef *,GPIO_TypeDef *,uint16_t,GPIO_TypeDef *,uint16_t);
void MMC5983_destroy(MMC5983_t *);
uint8_t MMC5983_register_read(MMC5983_t *, uint8_t );
void MMC5983_register_write(MMC5983_t *, uint8_t, uint8_t);
//----------------------- by passing a magnetometer object to this method it will update X Y Z ------------------
//-----------  we really do not need to the second parameter since by having the address of the magnetometer object ----------
//------- we can calculate the offset of x y z data place holder there is risk on that approach if someone in future ------------
//--- add more eleman at the bigining of the structure or change the data type we need to consider those changes ---------
uint8_t MMC5983_read_XYZ(MMC5983_t *thisMMC5983,uint8_t * data);
//-----------return query sensor status --------
uint8_t MMC5983_get_status(MMC5983_t *);
#endif /* MMC5983_H_ */
