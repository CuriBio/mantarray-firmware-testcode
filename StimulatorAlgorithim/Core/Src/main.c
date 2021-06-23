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


/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define DAC_ARR_SIZE   4
#define UART_BUF_SIZE 60
#define PERIOD_MS           40
#define AMPLITUDE_MA		20
#define PULSE_PERIOD_MS     10
#define INTERPULSE_PERIOD_MS   10

#define APB2_DIV            (uint32_t)((RCC->CFGR & RCC_CFGR_PPRE2) >> 3)
#define V_REF               3.3
#define R_SHUNT_OHMS        33

#define ADC_BUF_SIZE 	   2
#define ADC_LATENCY 	   4.5    // Number of ADC Clock cycles between Timer Trigger and Start of Conversion
#define ADC_CONV_TIME_US   0.87
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc;
DMA_HandleTypeDef hdma_adc;

DAC_HandleTypeDef hdac;
DMA_HandleTypeDef hdma_dac_ch1;

TIM_HandleTypeDef htim2;
TIM_HandleTypeDef htim6;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
char msg[UART_BUF_SIZE] = {'\0'};

typedef enum {
	ADC_CH0,
	ADC_CH1
}adc_ch_t;

typedef enum {
	FALSE,
	TRUE
}bool_t;


uint32_t *LUT;
uint16_t *tim_arr;

volatile uint16_t ADC3_Buf[ADC_BUF_SIZE];
volatile uint16_t ADC4_Buf[ADC_BUF_SIZE];
volatile uint16_t ADC_Buf[ADC_BUF_SIZE];
float trig_period_g;
extern bool_t XferCplt = FALSE;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_DAC_Init(void);
static void MX_TIM2_Init(void);
static void MX_ADC_Init(void);
static void MX_TIM6_Init(void);
/* USER CODE BEGIN PFP */
uint32_t GetReqSize_LUT(TIM_HandleTypeDef htim);
void GenerateTimerPulse(uint32_t *LUT,uint32_t n_tot);
void GenerateBiphasicPulse_LUT(uint32_t *LUT, uint16_t *tim_arr, float Amplitude_mA, uint16_t Pulse_Period_mS, uint16_t Interpulse_Period_mS, uint16_t Period_mS);
void GenerateConstCurrent_LUT(uint32_t *LUT, float Amplitude_mA, uint32_t n_tot);
void HAL_DMA1_CH1_XferCpltCallback(DMA_HandleTypeDef* hdma_adc);
void SetTimerPeriod(TIM_HandleTypeDef *htim, uint16_t *tim_arr, size_t n, uint8_t *index);
float GetTimerPeriod_S(TIM_HandleTypeDef htim);
uint16_t CalcTimerARR(TIM_HandleTypeDef htim, uint32_t period_ms);
void Load_DAC_Timer(TIM_HandleTypeDef* htim);
extern pHAL_DMA1_CH1_XferCpltCallback = HAL_DMA1_CH1_XferCpltCallback;
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
uint32_t GetReqSize_LUT(TIM_HandleTypeDef htim)
{
	TIM_TypeDef *TIM = htim.Instance;
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
	HAL_RCC_GetClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0);
	uint32_t f_hclk = HAL_RCC_GetSysClockFreq() / (RCC_ClkInitStruct.AHBCLKDivider + 1);
	uint32_t f_clk;
	if (TIM == TIM2 || TIM == TIM6) f_clk = f_hclk / (RCC_ClkInitStruct.APB2CLKDivider + 1);
	else if (TIM == TIM21 || TIM == TIM22) f_clk = f_hclk / (RCC_ClkInitStruct.APB2CLKDivider + 1);
	uint32_t f_trig = f_clk / (((TIM2->PSC) + 1) * ((TIM2->ARR) + 1));
	uint32_t n_tot = PERIOD_MS * f_trig / 1000U;
	return n_tot;
}

float GetTimerPeriod_S(TIM_HandleTypeDef htim)
{
	TIM_TypeDef *TIM = htim.Instance;
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
	HAL_RCC_GetClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0);
	uint32_t f_hclk;
	uint32_t f_clk;
	if (TIM == TIM2 || TIM == TIM6)
	{
		f_hclk = HAL_RCC_GetSysClockFreq() / (RCC_ClkInitStruct.AHBCLKDivider + 1);
		f_clk = f_hclk / (RCC_ClkInitStruct.APB1CLKDivider + 1);
	}
	else if (TIM == TIM22 || TIM == TIM21)
	{
		f_hclk = HAL_RCC_GetSysClockFreq() / (RCC_ClkInitStruct.AHBCLKDivider + 1);
		f_clk = f_hclk / (RCC_ClkInitStruct.APB2CLKDivider + 1);
	}
	float tim_period = (float) (((TIM->PSC) + 1) * ((TIM->ARR) + 1)) / f_clk;
	return tim_period;
}

void SetTimerPeriod(TIM_HandleTypeDef *htim, uint16_t *tim_arr, size_t n, uint8_t *index)
{
	TIM_TypeDef *TIM = htim -> Instance;
	TIM -> PSC = 0;
    TIM -> ARR = tim_arr[*(index)];
	*(index) = ((*index) + 1)%n;
}

uint16_t CalcTimerARR(TIM_HandleTypeDef htim, uint32_t period_ms)
{
	TIM_TypeDef *TIM = htim.Instance;
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
	HAL_RCC_GetClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0);
	uint32_t f_hclk = HAL_RCC_GetSysClockFreq() / (RCC_ClkInitStruct.AHBCLKDivider + 1);
	uint32_t f_clk;
	if (TIM == TIM2 || TIM == TIM6) f_clk = f_hclk / (8);
	else if (TIM == TIM21 || TIM == TIM22) f_clk = f_hclk / (RCC_ClkInitStruct.APB2CLKDivider + 1);
	f_clk = f_hclk / (8);
	float period_max_ms = (float) (1000 / f_clk) * 65535;
	return period_ms < 1 ? 1 : (uint16_t)(((((float) period_ms / 1000) * f_clk) + (TIM -> PSC))) - 1;
}

int movingAvg(int *ptrArrNumbers, long *ptrSum, int pos, int len, uint16_t nextNum)
{
  //Subtract the oldest number from the prev sum, add the new number
  *ptrSum = *ptrSum - ptrArrNumbers[pos] + nextNum;
  //Assign the nextNum to the position in the array
  ptrArrNumbers[pos] = nextNum;
  //return the average
  return *ptrSum / len;
}

void CreateTxStr_UART(char * msg, uint32_t n_tot)
{
	int i = 0;
	float trig_period = GetTimerPeriod_S(htim2);
	trig_period_g = trig_period;
	uint32_t time_stamp = i * trig_period;
	uint16_t num_samples = n_tot/2;
	float v_pos, v_neg;
	float well_impedance_OHMS[num_samples];
	float well_current_A[num_samples];
	float well_voltage_V[num_samples];

	int arrNumbers_adc3[1] = {0};
	int arrNumbers_adc4[1] = {0};

	int pos_adc3 = 0, pos_adc4 = 0;
	int newAvg_adc3, newAvg_adc4 = 0;
	long sum_adc3 = 0, sum_adc4 = 0;
	int len = sizeof(arrNumbers_adc3) / sizeof(int);
	int samples = n_tot / 2;
	uint16_t adc3_buf[samples];
	uint16_t adc4_buf[samples];
	int adc3_buf_avg[samples];
    int adc4_buf_avg[samples];
	uint16_t j = 0;
	 for(int i = 0; i < n_tot; i++){
		 if (i%2 == 0)
		 {
			 adc3_buf[j] = ADC_Buf[i]; // Index is even, so value is adc3
		 }
		 else if (i%2 != 0)
		 {
			 adc4_buf[j] = ADC_Buf[i];
			 j++; // Both samples are stored so increment j
		 }
	 }

	  for(int i = 0; i < samples; i++)
	  {
		newAvg_adc3 = movingAvg(arrNumbers_adc3, &sum_adc3, pos_adc3, len, adc3_buf[i]);
		adc3_buf_avg[i] = newAvg_adc3;
	    pos_adc3++;
	    if (pos_adc3 >= len){
	    	pos_adc3 = 0;
	    }
	  }
	  for(int i = 0; i < samples; i++)
	  {
	  	newAvg_adc4 = movingAvg(arrNumbers_adc4, &sum_adc4, pos_adc4, len, adc4_buf[i]);
	  	adc4_buf_avg[i] = newAvg_adc4;
	  	pos_adc4++;
	  	if (pos_adc4 >= len){
	  	    pos_adc4 = 0;
	  	}
	  }
	for (i = 0; i < samples; i++){
			float adc3_V = ((float) adc3_buf[i] / 4096) * 3.3;
			v_pos = ( adc3_V - 1.65054 ) * 5.7;
			float adc4_V = ((float) adc4_buf[i] / 4096) * 3.3;
			v_neg = ((adc4_V*2) - V_REF);  // Shunt Voltage
			well_current_A[i] = v_neg / R_SHUNT_OHMS;
			well_voltage_V[i] = v_pos - v_neg;
			well_impedance_OHMS[i] = well_voltage_V[i] / well_current_A[i];
			sprintf(msg, "%f, %f,", v_pos, v_neg);
			HAL_UART_Transmit(&huart2, (uint8_t *) msg, strlen(msg), 100);
			char newline[2] = "\r\n";
			HAL_UART_Transmit(&huart2, (uint8_t *) newline, 2, 10);

	}

}

void GenerateTimerPulse(uint32_t *LUT, uint32_t n_tot)
{
	int i = 0;
	for (i = 0; i < n_tot; i++)
		{
			if (i%2 == 0)
			{
			*(LUT + i) = 4095;
			}
			else
			{
				*(LUT + i) = 0;

			}
		}
}

/*
void GenerateBiphasicPulse_LUT(uint32_t *LUT, float Amplitude_mA, uint16_t Pulse_Period_mS, uint16_t Interpulse_Period_mS, uint16_t Period_mS, uint32_t n_tot)
{

	uint32_t i = 0;
	uint32_t n_phase = n_tot * Pulse_Period_mS / Period_mS;
	uint32_t n_interphase = n_tot * Interpulse_Period_mS / Period_mS;
	float V_Shunt = Amplitude_mA * R_SHUNT_OHMS / 1000;
	float V_Dac = (V_Shunt / 2) + 1.65 ;
	uint16_t Amplitude = ((V_Dac * 4096) / V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range
	for (i = 0; i < n_phase; i++)2000
	{
		*(LUT + i) = 2048 + Amplitude; // Amplitude is currently just a 12-bit number specifying DAC_OUT value
	}
	for (i = n_phase; i < (n_phase + n_interphase); i++)
	{
		*(LUT + i) = 2048; // Middle of DAC Output Range is 0 mA
	}
	for (i = (n_phase + n_interphase); i < (2*n_phase + n_interphase); i++)
	{
		*(LUT + i) = 2048 - Amplitude;
	}
	for (i = (2*n_phase + n_interphase); i < n_tot; i++)
	{
		*(LUT + i) = 2048;
	}
}
 */
void GenerateBiphasicPulse_LUT(uint32_t *LUT, uint16_t *tim_arr, float amplitude_mA, uint16_t pulse_period_mS, uint16_t interpulse_period_mS, uint16_t period_mS)
{
	/*
		 * Full-Scale Current is +/-100mA. This corresponds to a shunt voltage
		 * of +/-3.3V and a DAC output of 0 and 3.3V for -100mA and +100mA respectively.

		I_Shunt | V_Shunt |   V_ADC_NEG (Also V_DAC)
		________|_________|_______________
		-100mA  | -3.3V   |   0V
		-50mA	| -1.65V  |   0.825
	      0mA   |  0V     |   1.65t6
	     50mA   |  1.65V  |   2.475
	     100mA  |  3.3V   |   3.3V

	    */
	uint16_t after_pulse_period_mS = period_mS - (2*pulse_period_mS + interpulse_period_mS);
	float v_shunt = amplitude_mA * R_SHUNT_OHMS / 1000;
	float v_dac = (v_shunt / 2) + 1.65 ;
	uint16_t amplitude = ((v_dac * 4096) / V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range

	tim_arr[0] = CalcTimerARR(htim2, pulse_period_mS);
	tim_arr[1] = CalcTimerARR(htim2, interpulse_period_mS);
	tim_arr[2] = CalcTimerARR(htim2, pulse_period_mS);
	tim_arr[3] = CalcTimerARR(htim2, after_pulse_period_mS);

	LUT[0] = 2048 + amplitude;
	LUT[1] = 2048;
	LUT[2] = 2048 - amplitude;
	LUT[3] = 2048;

}

void GenerateConstCurrent_LUT(uint32_t *LUT, float Amplitude_mA, uint32_t n_tot)
{
	uint32_t i = 0;
	float V_Shunt = Amplitude_mA * R_SHUNT_OHMS / 1000;
	float V_Dac = (V_Shunt / 2) + 1.65 ;
	uint16_t Amplitude = ((V_Dac * 4096) / V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range
	for (i = 0; i < n_tot; i++)
	{
		*(LUT + i) = 2048 + Amplitude;
	}
}

void HAL_ADC_ConvHalfCpltCallback(ADC_HandleTypeDef* hadc)
{
  /* This is called after the conversion is completed */
	HAL_GPIO_TogglePin(LD2_GPIO_Port, LD2_Pin); //HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);
	static int i = 0;
	ADC3_Buf[0] = ADC_Buf[0];

}

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef* htim)
{
	Load_DAC_Timer(htim);
}

void Load_DAC_Timer(TIM_HandleTypeDef* htim)
{
	  TIM2 -> DIER |= TIM_DIER_UIE;
	  static uint8_t index = 0;
	  SetTimerPeriod(htim, tim_arr, DAC_ARR_SIZE, &index); // Set the new ARR values for next portion of DAC waveform in advance
}

static void ADC_DMAConvCplt(DMA_HandleTypeDef *hdma_adc)
{
	ADC4_Buf[0] = ADC_Buf[1];
	XferCplt = TRUE;
	HAL_ADC_Stop_DMA(&hadc);
	HAL_TIM_Base_Stop(&htim6);
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
  MX_TIM2_Init();
  MX_ADC_Init();
  MX_TIM6_Init();
  /* USER CODE BEGIN 2 */
  //uint32_t n_tot = GetReqSize_LUT(htim2);
  LUT = (uint32_t *) malloc(DAC_ARR_SIZE * sizeof(*LUT));
  tim_arr = (uint16_t *) malloc(DAC_ARR_SIZE * sizeof(*tim_arr));
  //if (LUT != NULL) GenerateBiphasicPulse_LUT(LUT, tim_arr, AMPLITUDE_MA, PULSE_PERIOD_MS, INTERPULSE_PERIOD_MS, PERIOD_MS);
  //GenerateTimerPulse(LUT, DAC_ARR_SIZE);
  GenerateConstCurrent_LUT(LUT, AMPLITUDE_MA, DAC_ARR_SIZE);
  HAL_DAC_Start_DMA(&hdac, DAC_CHANNEL_1, (uint32_t *)LUT, DAC_ARR_SIZE, DAC_ALIGN_12B_R);
  Load_DAC_Timer(&htim2);
  HAL_TIM_Base_Start(&htim2);
  HAL_ADC_Start_DMA(&hadc, (uint32_t *)ADC_Buf, ADC_BUF_SIZE);
  //HAL_ADC_Start_IT(&hadc);
  hadc.DMA_Handle->XferCpltCallback = ADC_DMAConvCplt;
  HAL_TIM_Base_Start(&htim6);




  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */

      while (1)
      {

    	 if (XferCplt == TRUE){
    		 XferCplt = FALSE;
             CreateTxStr_UART(msg, sizeof(ADC_Buf) / sizeof(ADC_Buf[0]));
             HAL_ADC_Start_DMA(&hadc, (uint32_t *)ADC_Buf, ADC_BUF_SIZE);
             hadc.DMA_Handle->XferCpltCallback = ADC_DMAConvCplt;
             HAL_TIM_Base_Start(&htim6);
    	 }
    	  //HAL_GPIO_TogglePin(LD2_GPIO_Port, LD2_Pin); //HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);
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
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV16;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
  {
    Error_Handler();
  }
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_USART2;
  PeriphClkInit.Usart2ClockSelection = RCC_USART2CLKSOURCE_PCLK1;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief ADC Initialization Function
  * @param None
  * @retval None
  */
static void MX_ADC_Init(void)
{

  /* USER CODE BEGIN ADC_Init 0 */

  /* USER CODE END ADC_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC_Init 1 */

  /* USER CODE END ADC_Init 1 */
  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion)
  */
  hadc.Instance = ADC1;
  hadc.Init.OversamplingMode = DISABLE;
  hadc.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV2;
  hadc.Init.Resolution = ADC_RESOLUTION_12B;
  hadc.Init.SamplingTime = ADC_SAMPLETIME_160CYCLES_5;
  hadc.Init.ScanConvMode = ADC_SCAN_DIRECTION_FORWARD;
  hadc.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc.Init.ContinuousConvMode = DISABLE;
  hadc.Init.DiscontinuousConvMode = DISABLE;
  hadc.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_RISING;
  hadc.Init.ExternalTrigConv = ADC_EXTERNALTRIGCONV_T6_TRGO;
  hadc.Init.DMAContinuousRequests = ENABLE;
  hadc.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
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
  sConfig.Channel = ADC_CHANNEL_10;
  if (HAL_ADC_ConfigChannel(&hadc, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }


  /* USER CODE BEGIN ADC_Init 2 */
   HAL_ADCEx_Calibration_Start(&hadc, ADC_SINGLE_ENDED);
  /* USER CODE END ADC_Init 2 */

}

/**
  * @brief DAC Initialization Function
  * @param None
  * @retval None
  */
static void MX_DAC_Init(void)
{

  /* USER CODE BEGIN DAC_Init 0 */

  /* USER CODE END DAC_Init 0 */

  DAC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN DAC_Init 1 */
  hdac.Instance = DAC;
  DAC->CR = DAC_CR_EN1 | DAC_CR_TEN1 | DAC_CR_BOFF1;

  /* USER CODE END DAC_Init 1 */
  /** DAC Initialization
  */
  hdac.Instance = DAC;
  if (HAL_DAC_Init(&hdac) != HAL_OK)
  {
    Error_Handler();
  }
  /** DAC channel OUT1 config
  */
  sConfig.DAC_Trigger = DAC_TRIGGER_T2_TRGO;
  sConfig.DAC_OutputBuffer = DAC_OUTPUTBUFFER_ENABLE;
  if (HAL_DAC_ConfigChannel(&hdac, &sConfig, DAC_CHANNEL_1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN DAC_Init 2 */

  /* USER CODE END DAC_Init 2 */

}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 0;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 65535;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV4;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;
  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_UPDATE;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */
  //TIM2 -> DIER |= TIM_DIER_UIE;
  //TIM2 -> SR &= ~TIM_SR_UIF;
  /* USER CODE END TIM2_Init 2 */

}

/**
  * @brief TIM6 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM6_Init(void)
{

  /* USER CODE BEGIN TIM6_Init 0 */

  /* USER CODE END TIM6_Init 0 */

  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM6_Init 1 */

  /* USER CODE END TIM6_Init 1 */
  htim6.Instance = TIM6;
  htim6.Init.Prescaler = 0;
  htim6.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim6.Init.Period = 1000;
  htim6.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim6) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_UPDATE;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim6, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM6_Init 2 */

  /* USER CODE END TIM6_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 9600;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

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
  HAL_NVIC_SetPriority(DMA1_Channel2_3_IRQn, 3, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel2_3_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

}

/* USER CODE BEGIN 4 */

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
