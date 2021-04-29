//>>main.c
/* USER CODE BEGIN PV */
osTimerId_t tiid_DataSchedulerTest;
/* USER CODE END PV */

/* USER CODE BEGIN RTOS_TIMERS */
tiid_DataSchedulerTest = osTimerNew(DataScheduler_Callback,  osTimerPeriodic, (void *)0, NULL);
/* USER CODE END RTOS_TIMERS */

//>>system.c
void StartSystem(void *argument)
{
	MantarraySystem.state = MANTARRAY_SYSTEM_STATUS_TESTBENCH;
	osTimerStart(tiid_DataSchedulerTest, 10);
	while(1)
	{
		case MANTARRAY_SYSTEM_STATUS_TESTBENCH:
			osDelay(1);
		break;
	}
}
void DataScheduler_Callback (void *argument) {
	GPIOA->BSRR = GPIO_PIN_4;
	GPIOA->BSRR = GPIO_PIN_4<<16;
}

//>>Old functions for different sampling rates per well
void DataScheduler_Callback (void *argument) {
	for (uint8_t thisModule = 0; thisModule < MAXIMUM_MODULE_NUMBER; thisModule++)
	{
		MantarraySystem.ph_module_block[thisModule].samplingCounter--;
		if (MantarraySystem.ph_module_block[thisModule].samplingCounter == 0)
		{
			MantarraySystem.ph_module_block[thisModule].samplingCounter = MantarraySystem.ph_module_block[thisModule].samplingRate;
			osEventFlagsSet(efid_ModuleData, (uint32_t)1<<thisModule);
		}
	}
}

void StartMagDataOut(void *argument)
{
	uint8_t bitmask[35];
	uint8_t * slidingWindow;
	uint16_t slidingOffset = 7;
	uint32_t flagsSet = 0;
	//osEventFlagsWait(efid_SystemEvents, FLAGS_SYSTEM_InitComplete, osFlagsNoClear, osWaitForever);
	while(1)
	{
		osEventFlagsSet(efid_ModuleData, (uint32_t)FLAGS_MODULE_ALL);
		flagsSet = osEventFlagsWait(efid_ModuleData, (uint32_t)FLAGS_MODULE_ALL, osFlagsNoClear, osWaitForever);
		slidingWindow = bitmask;
		slidingOffset = 7;
		for (uint8_t thisModule = 0; thisModule < MAXIMUM_MODULE_NUMBER; thisModule++)
		{
			MantarraySystem.ph_module_block[thisModule].axesConfig = 0b101000101;
			uint16_t mask = ~(uint16_t)MAGDATAOUT_OFFSET_MASK<<slidingOffset;
			uint16_t * targetAddress = (uint16_t*)slidingWindow;
			uint16_t target = *targetAddress;
			*(uint16_t*)slidingWindow &= ~(uint16_t)MAGDATAOUT_OFFSET_MASK<<slidingOffset;
			if (flagsSet & 1<<thisModule)
			{
				*(uint16_t*)slidingWindow |= (uint16_t)(MantarraySystem.ph_module_block[thisModule].axesConfig <<slidingOffset);
				osEventFlagsClear(efid_ModuleData, (uint32_t)1<<thisModule);
			}

			if (slidingOffset==0)
			{
				slidingWindow = slidingWindow+2;
				slidingOffset = 7;
			}
			else
			{
				slidingWindow++;
				slidingOffset--;
			}
		}
	}
}