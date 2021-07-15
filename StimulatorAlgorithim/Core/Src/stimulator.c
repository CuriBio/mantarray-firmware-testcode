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

Stimulator_t *stim_create(volatile ring_buffer_t *event_queue, DAC_HandleTypeDef *hdac, ADC_HandleTypeDef *hadc, TIM_HandleTypeDef *htim)
{

}


/*
 * GenerateWavePWL fills look-up tables for DAC and associated timer to create piecewise-linear waveform from a time, value pair array
 */

void stim_generate_wave_lut(Stimulator_t *pStim)
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
			if (period_uS > MAX_PERIOD_US || amp_10uA > MAX_CURRENT_10UA) { break; }
			double v_shunt = (double) amp_10uA * R_SHUNT_OHMS / 100000;
			double v_dac = (v_shunt / 2) + 1.65 ;

			int16_t dac_amp = ((v_dac * 4096) / V_REF) - 2048; // Subtract 2048 since 0mA corresponds to middle of DAC range
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

