/*
 * stimulator.h
 *
 *  Created on: Jul 14, 2021
 *      Author: alexv
 */

#ifndef SRC_STIMULATOR_H_
#define SRC_STIMULATOR_H_

#include "main.h"
#include "adc.h"
#include "ringBuffer.h"
/* USER CODE BEGIN PD */
#define STIM_CONTINUOUS_MODE_ENABLED

#define STIM_MAX_PERIOD_US           65535U  // 65mS
#define STIM_MAX_CURRENT_10UA        10000  // 100mA
#define STIM_V_REF               	3.3
#define STIM_R_SHUNT_OHMS        	33
#define STIM_DAC_OUT_NEG_100_MA      0
#define STIM_DAC_OUT_ZERO_MA         2048
#define STIM_DAC_OUT_100_MA          4095

/* Defines used with old version of generateBiphasicPulse_LUT*/
#define STIM_PERIOD_MS           	50U
#define STIM_AMPLITUDE_MA			30U
#define STIM_PULSE_PERIOD_MS     	10U
#define STIM_INTERPULSE_PERIOD_MS   10U
#define STIM_OUTPUT_ENABLE  	1U

/* Bit definitions for pStimulator flags variable*/
#define NEW_DATA_READY_FLAG_POS 	0x01
#define STIM_READY_FLAG_POS      	0x02
#define NEW_DATA_READY_FLAG			( 1 << NEW_DATA_READY_FLAG_POS ) // HIGH: ADC Data buffer is full
#define STIM_READY_FLAG			( 1 << STIM_READY_FLAG_POS ) // HIGH: Stimulator is initialized and not currently in use.

typedef enum {
	STIM_RUNNING,
	STIM_STOPPED,
} State_t;

typedef struct {
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
	uint16_t data_buf[ADC_DMA_DATA_BUF_SIZE];
	ADC_HandleTypeDef *hadc;
	DMA_HandleTypeDef *hdma_adc;
	TIM_HandleTypeDef *htim;
} Stimulator_t;

Stimulator_t *stimulator_create(DAC_HandleTypeDef *hdac, ADC_HandleTypeDef *hadc, TIM_HandleTypeDef *htim);
void stimulator_generate_wave_lut(Stimulator_t *pStim);
void ComputeImpedances(uint16_t *ADC3_Res, uint16_t *ADC4_Res, float *Z_Buf);
void stimulator_state_machine (Stimulator_t *stimulator);

#endif /* SRC_STIMULATOR_H_ */
