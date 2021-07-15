/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
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
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdlib.h>
#include <stdio.h>
#include "math.h"
#include "string.h"
#include "system.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */






/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc;
DMA_HandleTypeDef hdma_adc;

DAC_HandleTypeDef hdac;
DMA_HandleTypeDef hdma_dac_ch1;

I2C_HandleTypeDef hi2c1;
I2C_HandleTypeDef hi2c2;

SPI_HandleTypeDef hspi1;
SPI_HandleTypeDef hspi2;

TIM_HandleTypeDef htim21;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */

System my_sys;

uint16_t DAC_TIM_Arr[DAC_ARR_SIZE_DEBUG]; // Used for Debug only
uint32_t DAC_Arr[DAC_ARR_SIZE_DEBUG];     // Used for Debug only
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_DMA_Init(void);

/* USER CODE BEGIN PFP */
/* User-defined Callback's*/
void HAL_DMA1_CH1_XferCpltCallback(DMA_HandleTypeDef* hdma_adc);
void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc);

/* Private Functions */
void TransmitBuf(uint16_t *buf, size_t size);
void CreateStrFromArray(char *dest_str, volatile uint16_t *data, size_t size);
void BIT_SET(volatile uint16_t *bits, uint16_t bit);
void BIT_CLR(volatile uint16_t *bits, uint16_t bit);
uint16_t IS_BIT_SET(volatile uint16_t bits, uint16_t bit);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc)
{
	HAL_ADC_Stop_DMA(hadc);
	//HAL_DAC_Stop_DMA(&hdac, DAC_CHANNEL_1);
	//HAL_TIM_Base_Stop_IT(&htim21);

	event_t event;
	create_event(XFER_CPLT, NULL, 0, &event);
	ring_buffer_queue((&my_sys) -> stimulator -> event_queue, event);
}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef* htim)
{
	if (htim == (&my_sys)->stimulator->htim) { LoadTimerDac(htim, (&my_sys)->stimulator->dac_tim_lut, (&my_sys)->stimulator->n_elem_lut); } // If the overflowed timer belongs to the stimulator then load new value into it
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */


  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_USART2_UART_Init();
  MX_DAC_Init();
  MX_ADC_Init();
  MX_TIM21_Init();


  /* USER CODE BEGIN 2 */

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  Stimulator_t *stimulator = (&my_sys)->stimulator;
  int16_t cmd_array[4] = { 3000, 10000, 0, 10000 };
  event_t event;
  create_event(STIM_RUN_CMD, cmd_array, sizeof(cmd_array), &event);
  push_event(stimulator->event_queue, event);

  module_system_init(&my_sys);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
     state_machine(&my_sys);
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }

      while (1)
      {
    		 if (!ring_buffer_is_empty(stimulator->event_queue))
    		 {
        		 event_t event;
    			 pop_event(stimulator->event_queue, &event);
    			 switch (stimulator-> state_current)
    			 {
    			 case STIM_STOPPED:
    				 if ( event.name == STIM_RUN_CMD )
    			 	 {
    					 /* Copy data from popped event to Stimulator struct. Free event memory. */
    					 stimulator->val_time_arr = malloc(event.data_size);
    					 stimulator->n_elem_val_time_arr = event.data_size / sizeof(event.data[0]);
    		 	 		 memcpy(stimulator->val_time_arr, event.data, event.data_size);
    			    	 free_event_data(&event);
    			    	 if (OUTPUT_ENABLE) { stim_generate_wave_lut((&my_sys)->stimulator); }

    			    	 /* Load the dac timer with values generated in GenerateWaveLUT and start it. Then, start the DAC and DMA with LUT generated in same function */
    			    	 LoadTimerDac(&htim21, stimulator->dac_tim_lut, stimulator->n_elem_lut);
    			    	 HAL_TIM_Base_Start_IT(&htim21);
    			    	 HAL_DAC_Start_DMA(&hdac, DAC_CHANNEL_1, (uint32_t *)stimulator->dac_lut, stimulator->n_elem_lut, DAC_ALIGN_12B_R);

    			    	 /*
    			    	  * TODO: In future, timer 21 CC module interrupt will trigger a conversion and DMA transfer every 100uS.
    			    	  */
    			    	 HAL_ADC_Start_DMA(&hadc, (uint32_t *)stimulator-> data_buf, DATA_BUF_SIZE);

    			    	 /* Set state and flags */
    			    	 stimulator->state_current = STIM_RUNNING;
    			    	 stimulator->state_prev = STIM_STOPPED;
    			    	 uint16_t flags = stimulator->flags;
    			    	 BIT_CLR(&flags, STIM_IDLE_FLAG);
    			    	 BIT_CLR(&flags, DATA_READY_FLAG);
    			     }
    			     break;
    			 case STIM_RUNNING:
    				 if ( event.name == XFER_CPLT )
    			     {
    			    	 TransmitBuf(stimulator->data_buf, DATA_BUF_SIZE);
    			    	 uint16_t flags = stimulator->flags;
    			    	 BIT_SET(&flags, STIM_IDLE_FLAG);
    			    	 BIT_SET(&flags, DATA_READY_FLAG);
    			     }
    			     else if ( event.name == STIM_STOP_CMD )
    			     {
    			    	 HAL_ADC_Stop_DMA(&hadc);
    			    	 HAL_DAC_Stop_DMA(&hdac, DAC_CHANNEL_1);
    			    	 HAL_TIM_Base_Stop_IT(&htim21);
    			    	 stimulator->state_current = STIM_STOPPED;
    			    	 stimulator->state_prev = STIM_RUNNING;
    			    	 uint16_t flags = stimulator->flags;
    			    	 BIT_CLR(&flags, STIM_IDLE_FLAG);
    			    	 BIT_CLR(&flags, DATA_READY_FLAG);
    			     }
    			     break;
    			 }

    		 }
    }
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */

  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);
  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLLMUL_4;
  RCC_OscInitStruct.PLL.PLLDIV = RCC_PLLDIV_2;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
  {
    Error_Handler();
  }
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_USART2|RCC_PERIPHCLK_I2C1;
  PeriphClkInit.Usart2ClockSelection = RCC_USART2CLKSOURCE_PCLK1;
  PeriphClkInit.I2c1ClockSelection = RCC_I2C1CLKSOURCE_PCLK1;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}


/**
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void)
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA1_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA1_Channel1_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Channel1_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel1_IRQn);
  /* DMA1_Channel2_3_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Channel2_3_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel2_3_IRQn);

}


/* USER CODE BEGIN 4 */
void CreateStrFromArray(char *dest_str, volatile uint16_t *data, size_t size)
{

	  for (int i = 0; i < size; i++)
	  {
		 char src_str[6] = {'\0'};
		 sprintf(src_str, "%d,", data[i]);
		 strcat(dest_str, src_str);
	  }

}

void TransmitBuf(uint16_t *buf, size_t size)
{
	HAL_GPIO_TogglePin(GPIOA, GREEN_LED_PIN_Pin);

	for (int i = 0; i < size; i++)
	{
		char str[40] = {'\0'};
		snprintf(str, sizeof(str), "%d,", buf[i]);
		HAL_UART_Transmit(&huart2, (uint8_t *) str, strlen(str), 100);
		HAL_UART_Transmit(&huart2, (uint8_t *)"\n\r", 2, 10);

	}
}

void BIT_SET(volatile uint16_t *bits, uint16_t bit){
	*(bits) = *(bits) | bit;
}

void BIT_CLR(volatile uint16_t *bits, uint16_t bit){
	*(bits) = *(bits) & !bit;
}

uint16_t IS_BIT_SET(volatile uint16_t bits, uint16_t bit){
	return (bits & (bit)) ? 1 : 0;
}
/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
