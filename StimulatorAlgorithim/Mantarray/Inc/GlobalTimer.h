#ifndef GLOBALTIMER_H_
#define GLOBALTIMER_H_

#include <string.h>
#include <stdio.h>
#include "main.h"

typedef struct
{
	uint8_t overflow_counter;
	TIM_HandleTypeDef* h_timer;
} GlobalTimer_t;

GlobalTimer_t * global_timer_create(TIM_HandleTypeDef* timer_id);

uint64_t get_global_timer(GlobalTimer_t *thisGlobalTimer);

void set_global_timer(GlobalTimer_t *thisGlobalTimer, uint64_t new_value);



#endif /* GLOBALTIMER_H_ */
