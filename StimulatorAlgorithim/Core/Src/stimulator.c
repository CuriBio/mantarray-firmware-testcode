/*
 * stimulator.c
 *
 *  Created on: Jul 14, 2021
 *      Author: alexv
 */

#include "stimulator.h"
#include <stdlib.h>
#include <stdio.h>
#include "math.h"
#include "string.h"
#include "tim.h"

Stimulator_t *stimulator_create(DAC_HandleTypeDef *hdac, ADC_HandleTypeDef *hadc, TIM_HandleTypeDef *htim)
{
	Stimulator_t *stimulator = (Stimulator_t *) malloc(sizeof(Stimulator_t));
	ring_buffer_t *eq = malloc(sizeof(ring_buffer_t) * RING_BUFFER_SIZE);
	ring_buffer_init(eq);
	stimulator->event_queue = eq;
	stimulator->hadc = hadc;
	stimulator->hdac = hdac;
	stimulator->htim = htim;
	stimulator->state_current = STIM_STOPPED;
	stimulator->state_prev = STIM_STOPPED;
	stimulator->flags = STIM_READY_FLAG;
	stimulator->n_elem_val_time_arr = 2;
	stimulator->val_time_arr = malloc(sizeof(stimulator->val_time_arr) * stimulator->n_elem_val_time_arr);
	stimulator->val_time_arr[0] = STIM_DAC_OUT_ZERO_MA;
	stimulator->val_time_arr[1] = TIM21_MAX_PERIOD_CNTS;
	stimulator_generate_wave_lut(stimulator);

	return stimulator;
}

void stimulator_destroy(Stimulator_t *stimulator)
{
	free(stimulator->event_queue);
	free(stimulator->dac_lut);
	free(stimulator->dac_tim_lut);
	free(stimulator->val_time_arr);
	free(stimulator);
}

void stimulator_state_machine (Stimulator_t *stimulator)
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
	    					 if (event.data == NULL) { break; }
	    					 stimulator->val_time_arr = malloc(event.data_size);
	    					 stimulator->n_elem_val_time_arr = event.data_size / sizeof(event.data[0]);
	    		 	 		 memcpy(stimulator->val_time_arr, event.data, event.data_size);
	    			    	 free_event_data(&event);

							 #ifdef STIM_OUTPUT_ENABLE
	    			    	 /* Generate DAC look-up tables based on command array */
	    			    	 stimulator_generate_wave_lut(stimulator);

	    			    	 /* Load the dac timer with first element of table generated in GenerateWaveLUT and start it. Then, start the DAC and DMA with LUT generated in same function */
	    			    	 LoadTimerDac(&htim21, stimulator->dac_tim_lut, stimulator->n_elem_lut);
	    			    	 HAL_TIM_Base_Start_IT(&htim21);
	    			    	 HAL_DAC_Start_DMA(stimulator->hdac, DAC_CHANNEL_1, (uint32_t *)stimulator->dac_lut, stimulator->n_elem_lut, DAC_ALIGN_12B_R);

	    			    	 /* TODO: In future, timer 21 CC module interrupt will trigger a conversion and DMA transfer every 100uS. */
	    			    	 HAL_ADC_Start_DMA(stimulator->hadc, (uint32_t *)stimulator-> data_buf, sizeof(stimulator-> data_buf));

	    			    	 /* Set state and flags */
	    			    	 stimulator->state_current = STIM_RUNNING;
	    			    	 stimulator->state_prev = STIM_STOPPED;
	    			    	 uint16_t flags = stimulator->flags;
	    			    	 BIT_CLR(&flags, STIM_READY_FLAG);
	    			    	 BIT_CLR(&flags, NEW_DATA_READY_FLAG);
	    			    	 #endif

	    			     }
	    			     break;
	    			 case STIM_RUNNING:
	    				 if ( event.name == XFER_CPLT )
	    			     {
						#ifndef STIM_CONTINUOUS_MODE_ENABLED
	    			    	 stimulator->state_current = STIM_STOPPED;
	    			    	 stimulator->state_prev = STIM_RUNNING;
						#else
	    			    	 stimulator->state_current = STIM_RUNNING;
	    			         stimulator->state_prev = STIM_RUNNING;
						#endif
	    			    	 uint16_t flags = stimulator->flags;
	    			         BIT_SET(&flags, NEW_DATA_READY_FLAG);
	    			     }
	    			     else if ( event.name == STIM_STOP_CMD )
	    			     {
	    			    	 HAL_ADC_Stop_DMA(stimulator->hadc);
	    			    	 HAL_DAC_Stop_DMA(stimulator->hdac, DAC_CHANNEL_1);

	    			    	 /* Enable the DAC peripheral again so that we can zero out stimulator current */
	    			    	 __HAL_DAC_ENABLE(stimulator->hdac, DAC_CHANNEL_1);
	    			    	 HAL_DAC_SetValue(stimulator->hdac, DAC_CHANNEL_1, DAC_ALIGN_12B_R, STIM_DAC_OUT_ZERO_MA);

	    			    	 stimulator->state_current = STIM_STOPPED;
	    			    	 stimulator->state_prev = STIM_RUNNING;
	    			    	 uint16_t flags = stimulator->flags;
	    			    	 BIT_SET(&flags, STIM_READY_FLAG);
	    			     }
	    			     break;
	    		 }
	    }
}

/*
 * GenerateWavePWL fills look-up tables for DAC and associated timer to create piecewise-linear waveform from a time, value pair array
 */

void stimulator_generate_wave_lut(Stimulator_t *pStim)
{
	/*
		I_Shunt | V_Shunt |   V_ADC_NEG (Also V_DAC)
		________|_________|_______________
		-100mA  | -3.3V   |   0V
		-50mA	| -1.65V  |   0.825
	      0mA   |  0V     |   1.65
	     50mA   |  1.65V  |   2.475
	     100mA  |  3.3V   |   3.3V

	 */

	int16_t *vals_tims = pStim->val_time_arr;
	uint16_t n_elem_vals_tims = pStim->n_elem_val_time_arr;
	uint32_t f_clk = GetPclk(pStim->htim);
	uint16_t n_tot_elem = 0;


	int i = 0 , j = 0;

	for (i = 0; i < n_elem_vals_tims; i++)
	{
		if (i%2 == 1)
		{
			uint16_t period_uS = vals_tims[i];
			uint32_t num_clk_cyc = (f_clk * ((double) period_uS / 1000000));
			n_tot_elem += (uint16_t) ceil((double) num_clk_cyc / 65535);
		}
	}

	pStim->n_elem_lut = n_tot_elem;
	pStim->dac_lut = (uint16_t *) malloc(n_tot_elem * sizeof(pStim->dac_lut[0]));
	pStim->dac_tim_lut = (uint16_t *) malloc(n_tot_elem * sizeof(pStim->dac_tim_lut[0]));

	uint16_t idx = 0;

	for (i = 0; i < n_elem_vals_tims; i++)
	{
		/* Even indices correspond to DAC output values, odd indices correspond to time values */
		if (i%2 == 0)
		{
			// vals_tims is in format uS, 10uA
			int16_t amp_10uA = vals_tims[i];
			uint16_t period_uS = vals_tims[i + 1];
			if (period_uS > STIM_MAX_PERIOD_US || amp_10uA > STIM_MAX_CURRENT_10UA) { break; }
			double v_shunt = (double) amp_10uA * STIM_R_SHUNT_OHMS / 100000;
			double v_dac = (v_shunt / 2) + 1.65 ;

			int16_t dac_amp = ((v_dac * 4096) / STIM_V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range
			uint32_t num_clk_cyc = (f_clk * ((double) period_uS / 1000000));
			uint16_t n_elem = (uint16_t) ceil((double) num_clk_cyc / 65535);

			for (j = 0; j < n_elem; j++)
			{
				dac_amp = dac_amp < -2047 ? -2047 : dac_amp;
				pStim->dac_lut[j + idx] = 2047 + dac_amp;
				if (j < (n_elem) - 1)
				{
					pStim->dac_tim_lut[j + idx] = 65534;
				}
				else if (j == n_elem - 1)
				{
					uint16_t rem_clk_cyc = num_clk_cyc - (65535 * (n_elem - 1));
					pStim->dac_tim_lut[j + idx] = rem_clk_cyc == 0 ? 0 : (rem_clk_cyc + (TIM2 -> PSC)) - 1;
					idx += n_elem;
				}

			}
		}
	}

}


