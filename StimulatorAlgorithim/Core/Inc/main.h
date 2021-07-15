/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2021 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32l0xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */
static inline void BIT_SET(volatile uint16_t *bits, uint16_t bit){
	*(bits) = *(bits) | bit;
}

static inline void BIT_CLR(volatile uint16_t *bits, uint16_t bit){
	*(bits) = *(bits) & !bit;
}

static inline uint16_t IS_BIT_SET(volatile uint16_t bits, uint16_t bit){
	return (bits & (bit)) ? 1 : 0;
}
/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define BRD_CONF_NUCLEO_L053R8


#ifdef BRD_CONF_NUCLEO_L053R8
#define B1_Pin GPIO_PIN_13
#define B1_GPIO_Port GPIOC
#define USART_TX_Pin GPIO_PIN_2
#define USART_TX_GPIO_Port GPIOA
#define USART_RX_Pin GPIO_PIN_3
#define USART_RX_GPIO_Port GPIOA
#define GREEN_LED_PIN_Pin GPIO_PIN_5
#define GREEN_LED_PIN_GPIO_Port GPIOA
#define TMS_Pin GPIO_PIN_13
#define TMS_GPIO_Port GPIOA
#define TCK_Pin GPIO_PIN_14
#define TCK_GPIO_Port GPIOA
#define I2C2_SDA_PIN   GPIO_PIN_11
#define I2C2_SCL_PIN   GPIO_PIN_13
#define I2C2_GPIO_Port GPIOB
#else
#define BUS_C0_Pin GPIO_PIN_13
#define BUS_C0_GPIO_Port GPIOA
#define BUS_C2_Pin GPIO_PIN_15
#define BUS_C2_GPIO_Port GPIOA
#define BUS4_Pin GPIO_PIN_4
#define BUS4_GPIO_Port GPIOB
#define BUS7_Pin GPIO_PIN_7
#define BUS7_GPIO_Port GPIOB
#define CHN_OUT_RST_Pin GPIO_PIN_14
#define CHN_OUT_RST_GPIO_Port GPIOC
#define BUS_C1_Pin GPIO_PIN_14
#define BUS_C1_GPIO_Port GPIOA
#define BUS3_Pin GPIO_PIN_3
#define BUS3_GPIO_Port GPIOB
#define BUS6_Pin GPIO_PIN_6
#define BUS6_GPIO_Port GPIOB
#define mag_int_a_Pin GPIO_PIN_8
#define mag_int_a_GPIO_Port GPIOB
#define CHN_OUT_BT0_Pin GPIO_PIN_15
#define CHN_OUT_BT0_GPIO_Port GPIOC
#define programmer_TX_line_Pin GPIO_PIN_10
#define programmer_TX_line_GPIO_Port GPIOA
#define BUS1_Pin GPIO_PIN_1
#define BUS1_GPIO_Port GPIOB
#define BUS5_Pin GPIO_PIN_5
#define BUS5_GPIO_Port GPIOB
#define programmer_RX_line_Pin GPIO_PIN_9
#define programmer_RX_line_GPIO_Port GPIOA
#define BUS0_Pin GPIO_PIN_0
#define BUS0_GPIO_Port GPIOB
#define BUS_CLK_Pin GPIO_PIN_0
#define BUS_CLK_GPIO_Port GPIOA
#define SPI_C_CS_Pin GPIO_PIN_8
#define SPI_C_CS_GPIO_Port GPIOA
#define SPI_A_CS_Pin GPIO_PIN_6
#define SPI_A_CS_GPIO_Port GPIOA
#define mag_int_c_Pin GPIO_PIN_4
#define mag_int_c_GPIO_Port GPIOA
#define tx2_tp_Pin GPIO_PIN_2
#define tx2_tp_GPIO_Port GPIOA
#define BUS2_Pin GPIO_PIN_2
#define BUS2_GPIO_Port GPIOB
#define SPI_B_CS_Pin GPIO_PIN_7
#define SPI_B_CS_GPIO_Port GPIOA
#define mag_int_b_Pin GPIO_PIN_3
#define mag_int_b_GPIO_Port GPIOA
#endif
/* USER CODE BEGIN Private defines */


/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
