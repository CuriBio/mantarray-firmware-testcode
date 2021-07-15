/*
 * stimulator.h
 *
 *  Created on: Jul 14, 2021
 *      Author: alexv
 */

#ifndef SRC_STIMULATOR_H_
#define SRC_STIMULATOR_H_

#include "main.h"
#include "ringBuffer.h"
/* USER CODE BEGIN PD */
#define DATA_BUF_SIZE           1024U
#define MAX_EVENT_QUEUE_SIZE    50U
#define MAX_PERIOD_DEBUG_MS     1U
#define DAC_ARR_SIZE_DEBUG      (size_t) (PERIOD_MS / MAX_PERIOD_DEBUG_MS)
#define MAX_PERIOD_US           65535  // 65mS
#define MAX_CURRENT_10UA        10000  // 100mA
#define V_REF               	3.3
#define R_SHUNT_OHMS        	33

/* Defines used with old version of generateBiphasicPulse_LUT*/
#define PERIOD_MS           	50U
#define AMPLITUDE_MA			30U
#define PULSE_PERIOD_MS     	10U
#define INTERPULSE_PERIOD_MS   	10U
#define OUTPUT_ENABLE  1U

#if (OUTPUT_ENABLE != 1U)
	#define CONSTANT_OUTPUT_ENABLE 1U
#endif


/* Bit definitions for pStimulator flags variable*/
#define DATA_READY_FLAG_POS 	0x01
#define STIM_IDLE_FLAG_POS      0x02

#define DATA_READY_FLAG			( 1 << DATA_READY_FLAG_POS ) // HIGH: ADC Data buffer is full
#define STIM_IDLE_FLAG			( 1 << STIM_IDLE_FLAG_POS ) // HIGH: Stimulator is initialized and not currently in use.

typedef enum {
	STIM_RUNNING,
	STIM_STOPPED,
} State_t;

typedef struct Stimulator_t{
	uint16_t flags;
	State_t state_current;
    State_t state_prev;
    int16_t *val_time_arr;
    uint16_t n_elem_val_time_arr;
	volatile ring_buffer_t *event_queue;
	uint16_t *dac_lut;
	uint16_t *dac_tim_lut;
	uint16_t n_elem_lut;
	DAC_HandleTypeDef *hdac;
	DMA_HandleTypeDef *hdma_dac;
	uint16_t data_buf[DATA_BUF_SIZE];
	ADC_HandleTypeDef *hadc;
	DMA_HandleTypeDef *hdma_adc;
	TIM_HandleTypeDef *htim;
} Stimulator_t;

void stim_generate_wave_lut(Stimulator_t *pStim);
void ComputeImpedances(uint16_t *ADC3_Res, uint16_t *ADC4_Res, float *Z_Buf);

#endif /* SRC_STIMULATOR_H_ */
