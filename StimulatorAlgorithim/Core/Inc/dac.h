/*
 * dac.h
 *
 *  Created on: Jul 14, 2021
 *      Author: alexv
 */

#ifndef DAC_H_
#define DAC_H_

/* Includes ------------------------------------------------------------------*/
#include "main.h"
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

extern DAC_HandleTypeDef hdac;
extern DMA_HandleTypeDef hdma_dac_ch1;

/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

void MX_DAC_Init(void);

/* USER CODE BEGIN Prototypes */

/* USER CODE END Prototypes */


#endif /* DAC_H_ */
