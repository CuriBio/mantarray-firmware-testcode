/**
  ******************************************************************************
  * @file    adc.c
  * @brief   This file provides code for the configuration
  *          of the ADC instances.
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

/* Includes ------------------------------------------------------------------*/
#include "adc.h"

/* USER CODE BEGIN 0 */

ADC_HandleTypeDef hadc;
DMA_HandleTypeDef hdma_adc;


/* USER CODE END 0 */

/**
  * @brief ADC Initialization Function
  * @param None
  * @retval None
  */
void MX_ADC_Init(void)
{

  /* USER CODE BEGIN ADC_Init 0 */

  /* USER CODE END ADC_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC_Init 1 */
  hadc.State = HAL_ADC_STATE_RESET;
  /* USER CODE END ADC_Init 1 */
  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion)
  */
  hadc.Instance = ADC1;
  hadc.Init.OversamplingMode = DISABLE;
  hadc.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV2;
  hadc.Init.Resolution = ADC_RESOLUTION_12B;
  hadc.Init.SamplingTime = ADC_SAMPLETIME_7CYCLES_5;
  hadc.Init.ScanConvMode = ADC_SCAN_DIRECTION_FORWARD;
  hadc.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc.Init.ContinuousConvMode = ENABLE;
  hadc.Init.DiscontinuousConvMode = DISABLE;
  hadc.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc.Init.DMAContinuousRequests = ENABLE;
  hadc.Init.EOCSelection = ADC_EOC_SEQ_CONV;
  hadc.Init.Overrun = ADC_OVR_DATA_PRESERVED;
  hadc.Init.LowPowerAutoWait = DISABLE;
  hadc.Init.LowPowerFrequencyMode = DISABLE;
  hadc.Init.LowPowerAutoPowerOff = DISABLE;
  if (HAL_ADC_Init(&hadc) != HAL_OK)
  {
    Error_Handler();
  }
  /** Configure for the selected ADC regular channel to be converted.
  */
  sConfig.Channel = ADC_CHANNEL_0;
  sConfig.Rank = ADC_RANK_CHANNEL_NUMBER;
  if (HAL_ADC_ConfigChannel(&hadc, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /** Configure for the selected ADC regular channel to be converted.
  */
  sConfig.Channel = ADC_CHANNEL_1;
  if (HAL_ADC_ConfigChannel(&hadc, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN ADC_Init 2 */
	  /* Calibrate for ADC and analog circuitry errors */
	#if (ADC_CAL_ENABLE == 1)
	   	   ADC_CalibrateStimulator(&hadc, &hdac);
	#endif

	   /* Reinitialize using DMA*/

	   if (HAL_ADC_Init(&hadc) != HAL_OK)
	   {
	      Error_Handler();
	   }
  /* USER CODE END ADC_Init 2 */

}




/* USER CODE BEGIN 1 */
void ADC_CalibrateStimulator(ADC_HandleTypeDef* hadc, DAC_HandleTypeDef* hdac, TIM_HandleTypeDef* htim)
{
	/* Remove errors due to op-amp offset voltage and ADC offset */
	uint32_t data = 2048;
	HAL_DAC_Start_DMA(hdac, DAC_CHANNEL_1, &data, 1, DAC_ALIGN_12B_R);
	HAL_TIM_Base_Start(htim);
	HAL_Delay(100);
	HAL_ADCEx_Calibration_Start(hadc, ADC_SINGLE_ENDED);
	uint32_t ADC_cal = HAL_ADCEx_Calibration_GetValue(hadc, ADC_SINGLE_ENDED);
	HAL_ADC_Start(hadc);
	uint32_t stim_offset;
	if (HAL_ADC_PollForConversion(hadc, 100) == HAL_OK)
	{
		stim_offset = (int)HAL_ADC_GetValue(hadc) - 2048;
		ADC_cal -= stim_offset;
		HAL_ADCEx_Calibration_SetValue(hadc, ADC_SINGLE_ENDED, ADC_cal);
	}
	HAL_ADC_Stop(hadc);
	HAL_TIM_Base_Stop(htim);
	HAL_DAC_Stop_DMA(hdac, DAC_CHANNEL_1);
}

/* USER CODE END 1 */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
