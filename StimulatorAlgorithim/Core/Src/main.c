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

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define PERIOD_MS           	50U
#define AMPLITUDE_MA			30U
#define PULSE_PERIOD_MS     	10U
#define INTERPULSE_PERIOD_MS   	10U
#define BIPHASIC_OUTPUT_ENABLE  1U

#if (BIPHASIC_OUTPUT_ENABLE != 1U)
	#define CONSTANT_OUTPUT_ENABLE 1U
#endif

#define MAX_PERIOD_DEBUG_MS     1U
#define DAC_ARR_SIZE_DEBUG      (size_t) (PERIOD_MS / MAX_PERIOD_DEBUG_MS)


#define UART_BUF_SIZE 			60U


#define APB2_DIV            (uint32_t)((RCC->CFGR & RCC_CFGR_PPRE2) >> 3)
#define V_REF               3.3
#define R_SHUNT_OHMS        33

#define ADC_BUF_SIZE 	   512U
#define ADC_LATENCY 	   4.5    // Number of ADC Clock cycles between Timer Trigger and Start of Conversion
#define ADC_CONV_TIME_US   0.87
#define ADC_CAL_ENABLE     0U

#define XFERS_PER_TX   1U	// Number of ADC Conversion Sequences to add to ADC Buffers before UART TX
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


typedef enum {
	ADC_CH0,
	ADC_CH1
}adc_ch_t;

typedef enum {
	FALSE,
	TRUE
}bool_t;

typedef enum {
	DO_STIM_RUN,
	STIM_RUNNING,
	DO_STIM_STOP_CAPTURE,
	DO_STIM_RESTART_CAPTURE,
	STIM_DISABLE,
}stim_state_t;

typedef enum {
	TX_DISABLED,
	TX_INCPLT,
	TX_CPLT,
}tx_state_t;

typedef enum {
	ADC_BUF_WAIT,
	ADC_BUF_FIRST_HALF_FILLING,
	ADC_BUF_SECOND_HALF_FILLING,
}adc_buf_state_t;

typedef enum {
	NO_XFERS,
	HALF_XFER_CPLT,
	XFER_CPLT
}dma_xfer_state_t;


typedef struct {
	adc_buf_state_t  adc_buf_state_current;
	adc_buf_state_t  adc_buf_state_prev;
	dma_xfer_state_t  dma_xfer_state;
	tx_state_t tx_state;
	stim_state_t stim_state_current;
	stim_state_t stim_state_prev;
}states_t;

volatile uint16_t ADC_Buf[ADC_BUF_SIZE];
volatile states_t states = {
		.adc_buf_state_current = ADC_BUF_WAIT,
		.adc_buf_state_prev = ADC_BUF_WAIT,
		.dma_xfer_state = NO_XFERS,
		.tx_state = TX_DISABLED,
		.stim_state_current = DO_STIM_RUN,
		};

uint32_t *DAC_Lut;
uint16_t *DAC_TIM_Lut;
uint16_t DAC_TIM_Arr[DAC_ARR_SIZE_DEBUG]; // Used for Debug only
uint32_t DAC_Arr[DAC_ARR_SIZE_DEBUG];     // Used for Debug only
size_t n_elem;
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
void GenerateTimerPulse(uint32_t *LUT, uint32_t n_tot);
void GenerateBiphasicPulse_LUT(float Amplitude_mA, float Pulse_Period_mS, float Interpulse_Period_mS, float Period_mS);
void GenerateConstCurrent_LUT(uint32_t *LUT, float Amplitude_mA);
float ComputeImpedance(uint16_t ADC3_Res, uint16_t ADC4_Res);

void HAL_DMA1_CH1_XferCpltCallback(DMA_HandleTypeDef* hdma_adc);
void SetTimerPeriod(TIM_HandleTypeDef *htim, uint16_t *tim_arr, size_t n, uint8_t *index);
float GetTimerPeriod_S(TIM_HandleTypeDef htim);
void AllocateTimerLUT(TIM_HandleTypeDef htim, size_t n_elem);
void Load_DAC_Timer(TIM_HandleTypeDef* htim);

void CreateTxStr(char * msg, float Data);
HAL_StatusTypeDef TransmitMessage_UART(char * msg);

void ADC_CalibrateStimulator(ADC_HandleTypeDef* hadc, DAC_HandleTypeDef* hdac);

adc_buf_state_t *StimRunStateMachine(states_t *states); // Only call during Stim Run State
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

void AllocateLUT(TIM_HandleTypeDef htim, size_t n_elem)
{
	DAC_TIM_Lut = (uint16_t *) malloc(n_elem * sizeof(DAC_TIM_Lut[0]));
	DAC_Lut = (uint32_t *) malloc(n_elem * sizeof(DAC_Lut[0]));
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

float ComputeImpedance(uint16_t ADC3_Res, uint16_t ADC4_Res)
{
	//float trig_period = GetTimerPeriod_S(htim2);
	//uint32_t time_stamp = i * trig_period;

	float v_pos, v_neg, adc3_V, adc4_V;
	float well_impedance_OHMS, well_current_A, well_voltage_V;

	adc3_V = ((float) ADC3_Res / 4096) * 3.3;
	v_pos = ( adc3_V - 1.65054 ) * 5.7;
	adc4_V = ((float) ADC4_Res / 4096) * 3.3;
	v_neg = ((adc4_V*2) - V_REF);  // Shunt Voltage
	well_current_A = v_neg / R_SHUNT_OHMS;
	well_voltage_V = v_pos - v_neg;
	well_impedance_OHMS = well_voltage_V / well_current_A;

	return well_impedance_OHMS;
}

void CreateTxStr(char * msg, float data)
{
	  sprintf(msg, "%f,", data);
}

HAL_StatusTypeDef TransmitMessage_UART(char * msg)
{
	HAL_StatusTypeDef status = HAL_UART_Transmit(&huart2, (uint8_t *) msg, strlen(msg), 100);
	if (status != HAL_OK) { return status; }
	char newline[2] = "\r\n";
	HAL_UART_Transmit(&huart2, (uint8_t *) newline, 2, 10);
	return status;
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



void GenerateBiphasicPulse_LUT(float amplitude_mA, float pulse_period_mS, float interpulse_period_mS, float period_mS)
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

	if (period_mS < (2 * pulse_period_mS) + interpulse_period_mS || amplitude_mA > 100 || period_mS > 500)
	{
		return; /* Total period cannot be less than sum of inter-pulse and pulse periods.
				 * Amplitude cannot be greater than 100mA
				 * Total Period cannot be greater than 500mS
				 */
	}

	float v_shunt = amplitude_mA * R_SHUNT_OHMS / 1000;
	float v_dac = (v_shunt / 2) + 1.65 ;
	uint16_t amplitude = ((v_dac * 4096) / V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
	HAL_RCC_GetClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0);

	uint32_t f_clk = HAL_RCC_GetPCLK1Freq();

	float afterpulse_period_mS = period_mS - (2*pulse_period_mS + interpulse_period_mS);

	uint32_t pulse_period_cnts = (f_clk * ((double) pulse_period_mS / 1000));
	uint32_t interpulse_period_cnts = (f_clk * ((double) interpulse_period_mS / 1000));
	uint32_t afterpulse_period_cnts = (f_clk * ((double) afterpulse_period_mS / 1000));
	uint32_t n_pulse_elem = (uint32_t) ceil((double) pulse_period_cnts / 65535);
	uint32_t n_interpulse_elem = (uint32_t) ceil((double) interpulse_period_cnts / 65535);
	uint32_t n_afterpulse_elem = (uint32_t) ceil((double) afterpulse_period_cnts / 65535);
	n_elem = (2 * n_pulse_elem) + n_interpulse_elem + n_afterpulse_elem;
	AllocateLUT(htim2, n_elem);


		for (int i = 0; i < n_pulse_elem; i++)
		{
			DAC_Lut[i] = 2048 + amplitude;

			if (i < n_pulse_elem - 1)
			{
				DAC_TIM_Lut[i] = 65534;
			}
			else
			{
				float rem_cnts = pulse_period_cnts - (65535 * (n_pulse_elem - 1));
				DAC_TIM_Lut[i] = (uint16_t)(rem_cnts + (TIM2 -> PSC)) - 1;
			}
			DAC_TIM_Arr[i] = DAC_TIM_Lut[i];
			DAC_Arr[i] = DAC_Lut[i];

		}
		for (int i = n_pulse_elem; i < n_pulse_elem + n_interpulse_elem; i++)
		{
			DAC_Lut[i] = 2048;

			if (i < n_pulse_elem + n_interpulse_elem - 1)
			{
				DAC_TIM_Lut[i] = 65534;
			}
			else
			{
				float rem_cnts =  interpulse_period_cnts - (65535 * (n_interpulse_elem - 1));
				DAC_TIM_Lut[i] = (uint16_t)(rem_cnts + (TIM2 -> PSC)) - 1;
			}
			DAC_TIM_Arr[i] = DAC_TIM_Lut[i];
			DAC_Arr[i] = DAC_Lut[i];

		}
		for (int i = n_pulse_elem + n_interpulse_elem; i < (2*n_pulse_elem) + n_interpulse_elem; i++)
		{
			DAC_Lut[i] = 2048 - amplitude;

			if (i < (2*n_pulse_elem) + n_interpulse_elem - 1)
			{
				DAC_TIM_Lut[i] = 65534;
			}
			else
			{
				float rem_cnts =  pulse_period_cnts - (65535 * (n_pulse_elem - 1));
				DAC_TIM_Lut[i] = (uint16_t)(rem_cnts + (TIM2 -> PSC)) - 1;
			}
			DAC_TIM_Arr[i] = DAC_TIM_Lut[i];
			DAC_Arr[i] = DAC_Lut[i];

		}
		for (int i = (2*n_pulse_elem) + n_interpulse_elem; i < n_elem; i++)
		{
			DAC_Lut[i] = 2048;

			if (i < n_elem - 1)
			{
				DAC_TIM_Lut[i] = 65534;
			}
			else if (i == n_elem - 1)
			{
				float rem_cnts = afterpulse_period_cnts - (65535 * (n_afterpulse_elem - 1));
				DAC_TIM_Lut[i] = (uint16_t)(rem_cnts + (TIM2 -> PSC)) - 1;
			}
			DAC_TIM_Arr[i] = DAC_TIM_Lut[i];
			DAC_Arr[i] = DAC_Lut[i];

		}



}

void GenerateConstCurrent_LUT(uint32_t *LUT, float Amplitude_mA)
{
	uint32_t i = 0;
	float V_Shunt = Amplitude_mA * R_SHUNT_OHMS / 1000;
	float V_Dac = (V_Shunt / 2) + 1.65 ;
	uint16_t Amplitude = ((V_Dac * 4096) / V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range
	for (i = 0; i < DAC_ARR_SIZE_DEBUG; i++)
	{
		*(LUT + i) = 2048 + Amplitude;
	}
}


void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef* htim)
{
	if (htim == &htim2) { Load_DAC_Timer(htim); }
}

float GetTimerPeriod_S(TIM_HandleTypeDef htim)
{
	TIM_TypeDef *TIM = htim.Instance;
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
	HAL_RCC_GetClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0);
	uint32_t f_clk;
	if (TIM == TIM2 || TIM == TIM6)
	{
		f_clk = HAL_RCC_GetPCLK1Freq();
	}
	else if (TIM == TIM22 || TIM == TIM21)
	{
		f_clk = HAL_RCC_GetPCLK2Freq();
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

void Load_DAC_Timer(TIM_HandleTypeDef* htim)
{
	  static uint8_t index = 0;
	  SetTimerPeriod(htim, DAC_TIM_Lut, n_elem, &index); // Set the new ARR values for next portion of DAC waveform in advance
}

void HAL_ADC_ConvHalfCpltCallback(ADC_HandleTypeDef* hadc)
{
	states -> dma_xfer_state = HALF_XFER_CPLT;
}

void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc)
{
	states -> dma_xfer_state = XFER_CPLT;
}

void ADC_CalibrateStimulator(ADC_HandleTypeDef* hadc, DAC_HandleTypeDef* hdac)
{
	/* Remove errors due to op-amp offset voltage and ADC offset */
	uint32_t data = 2048;
	HAL_DAC_Start_DMA(hdac, DAC_CHANNEL_1, &data, 1, DAC_ALIGN_12B_R);
	HAL_TIM_Base_Start(&htim2);
	HAL_Delay(100);
	HAL_ADCEx_Calibration_Start(hadc, ADC_SINGLE_ENDED);
	uint32_t ADC_cal = HAL_ADCEx_Calibration_GetValue(hadc, ADC_SINGLE_ENDED);
	HAL_ADC_Start(hadc);
	uint32_t stim_offset;
	if (HAL_ADC_PollForConversion(hadc, 100) == HAL_OK)
	{
		stim_offset = (uint16_t)HAL_ADC_GetValue(hadc) - 2048;
		ADC_cal -= stim_offset;
		HAL_ADCEx_Calibration_SetValue(hadc, ADC_SINGLE_ENDED, ADC_cal);
	}
	HAL_ADC_Stop(hadc);
	HAL_TIM_Base_Stop(&htim2);
	HAL_DAC_Stop_DMA(hdac, DAC_CHANNEL_1);
}

adc_buf_state_t *StimBufState(states_t *states) // Only call during Stim Run State
{
	switch (states -> adc_buf_state_current)
	{
		case (ADC_BUF_WAIT):
			break;
		case (ADC_BUF_FIRST_HALF_FILLING):
		    if (states -> dma_xfer_status == HALF_XFER_CPLT )
		    {
			    states -> adc_buf_state_current = ADC_BUF_WAIT;
		    }
		  	states -> adc_buf_state_prev = states -> adc_buf_state_current;
			break;
		case (ADC_BUF_SECOND_HALF_FILLING):
			if (states -> dma_xfer_status == XFER_CPLT )
			{
				states -> adc_buf_state_current = ADC_BUF_WAIT;
			}
			states -> adc_buf_state_prev = states -> adc_buf_state_current;
			break;
		default:
			return states -> adc_buf_state_current;
	}
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
  /* USER CODE END 2 */
  New_Event();
  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
      while (1)
      {
    	 if (Is_New_Event()) //If a transfer or half transfer has been completed run state machine
    	 {
       	     StimBufState(states);

    	 switch (states)
    	 {
    	 	 case DO_STIM_RUN:
    	     {
    	    	 if (BIPHASIC_OUTPUT_ENABLE == 1) { GenerateBiphasicPulse_LUT(AMPLITUDE_MA, PULSE_PERIOD_MS, INTERPULSE_PERIOD_MS, PERIOD_MS); }
    	    	 else if (CONSTANT_OUTPUT_ENABLE == 1) { GenerateConstCurrent_LUT(AMPLITUDE_MA, DAC_ARR_SIZE_DEBUG); }
  	  	  	  	 HAL_DAC_Start_DMA(&hdac, DAC_CHANNEL_1, (uint32_t *)DAC_Lut, n_elem, DAC_ALIGN_12B_R);
  	  	  	  	 Load_DAC_Timer(&htim2);
  	  	  	  	 HAL_TIM_Base_Start_IT(&htim2);
  	  	  	  	 HAL_ADC_Start_DMA(&hadc, (uint32_t *)ADC_Buf, ADC_BUF_SIZE);

  	  	  	  	 if (states ->dma_xfer_state == HALF_XFER_CPLT)
  	  	  	  	 {
  	  	  	  		 states -> adc_buf_state_current = ADC_BUF_SECOND_HALF_FILLING;
  	  	  	  	  	 states -> state = STIM_RUNNING; // The stimulator DAC and ADC are now running
  	  	  	  	 }
  	  	  	  	 break;
    	 	 case STIM_RUNNING:
    	 	 {
  	  	  	  		 /* ADC Buffer is full, transmit data if haven't already done so.*/
  	  	  	  		 if ( states -> adc_buf_state_current == ADC_BUF_FIRST_HALF_FILLING )
  	  	  	  		 {
  	  	  	  			 TransmitBufSecondHlf(ADC_Buf); // If full transfer has been completed send out second half
  	  	  	  		  	 char msg[UART_BUF_SIZE] = {'\0'};
  	  	  	  		  	 float data = ComputeImpedance(ADC3_Res, ADC4_Res);
  	  	  	  		  	 CreateTxStr(msg, data);
  	  	  	  		  	 TransmitMessage_UART(msg);
  	  	  	  		 }
  	  	  	  		 else if ( states -> adc_buf_state_current == ADC_BUF_SECOND_HALF_FILLING )
  	  	  	  		 {
  	  	  	  			 TransmitBufFirstHlf(ADC_Buf);
  	  	  	  	  	  	 char msg[UART_BUF_SIZE] = {'\0'};
  	  	  	  	  	  	 float data = ComputeImpedance(ADC3_Res, ADC4_Res);
  	  	  	  	  	  	 CreateTxStr(msg, data);
  	  	  	  	  	  	 TransmitMessage_UART(msg);
  	  	  	  		 }
  	  	  	  		 else if ( states -> adc_buf_state_current == ADC_BUF_WAIT )
  	  	  	  		 {
  	  	  	  			 states -> state = DO_STIM_STOP_CAPTURE;
  	  	  	  	         New_Event();
  	  	  	  		 }
  	  	  	  	 break;
    	     }
    	 	 case DO_STIM_STOP_CAPTURE:
    	 	 {
    	 		HAL_ADC_Stop_DMA(&hadc);

    	 		if ( states -> adc_buf_state_prev == ADC_BUF_FIRST_HALF_FILLING )
    	 		{
    	 		  	  TransmitBufFirstHlf(ADC_Buf);
    	 		}
    	 		else if ( states -> adc_buf_state_prev == ADC_BUF_SECOND_HALF_FILLING )
    	 		{
    	 		  	  TransmitBufSecondHlf(ADC_Buf);
    	 		}
    	 		states -> state = DO_STIM_RESTART_CAPTURE;
	  	  	    New_Event();
    	 		break;
    	 	 }
    	 	 case DO_STIM_RESTART_CAPTURE:
    	 	 {
    	 		 HAL_ADC_Start_DMA(&hadc, (uint32_t *)ADC_Buf, ADC_BUF_SIZE);
    	    	 states -> state = STIM_RUNNING;
        	     states -> adc_buf_state_current = states -> adc_buf_state_prev; // We are now filling the buffer
    	    	 break;
    	 	 }
    	 	 case DO_STIM_DISABLE:
    	 	 {

    	 	 }
    	 	 default:
    	 	 {
    	    	 HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_SET);
    	 	 }
    	 }
    	 }
		 states -> dma_xfer_state = NO_XFERS;

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
  hadc.Init.SamplingTime = ADC_SAMPLETIME_19CYCLES_5;
  hadc.Init.ScanConvMode = ADC_SCAN_DIRECTION_FORWARD;
  hadc.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc.Init.ContinuousConvMode = DISABLE;
  hadc.Init.DiscontinuousConvMode = ENABLE;
  hadc.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc.Init.ExternalTrigConv = ADC_SOFTWARE_START;
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
  /* Calibrate for ADC and analog circuitry errors */
#if (ADC_CAL_ENABLE == 1)
   	   ADC_CalibrateStimulator(&hadc, &hdac);
#endif

   /* Reinitialize using DMA*/
   hadc.Init.ExternalTrigConv = ADC_SOFTWARE_START;
   hadc.Init.DMAContinuousRequests = ENABLE;
   hadc.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
   hadc.Init.ContinuousConvMode = ENABLE;

   ADC1 -> IER |= ADC_IER_EOSEQIE | ADC_IER_EOCIE;
   if (HAL_ADC_Init(&hadc) != HAL_OK)
   {
      Error_Handler();
   }
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
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
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
  huart2.Init.BaudRate = 115200;
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
  HAL_NVIC_SetPriority(DMA1_Channel2_3_IRQn, 0, 0);
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
