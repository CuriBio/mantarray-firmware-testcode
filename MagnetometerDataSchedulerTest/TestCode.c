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

//>>Thread for populating with false data
void StartMagDataOut(void* argument)
{
	osEventFlagsWait(efid_SystemEvents, FLAGS_SYSTEM_InitComplete, osFlagsNoClear, osWaitForever);
	//osThreadTerminate(MagDataOutHandle);
	Communicator_t* ph_this_communicator = &MantarraySystem.h_communicator;
	DoubleBufferPacket_t* ph_this_PacketBuffer = &ph_this_communicator->packetBuffer;
	Packet_t* producerAddress = ___DB_GET_PRODUCER(ph_this_PacketBuffer);
	osTimerStart(tiid_DataSchedulerTest, MantarraySystem.magPeriod);

	uint8_t MAGIC_WORD[MAGIC_WORD_LENGTH] = "CURI BIO";
	uint32_t thisCRC = 0;
	uint16_t memOffset = 0;
	while (1)
	{
		osEventFlagsWait(efid_DataBufferEvents, FLAGS_DATABUFF_MagDataReady, 0, osWaitForever);

		//Acquire new producer address after double buffer switch to begin loading data into
		if (osMutexAcquire(mtid_PacketProducerMutex, osWaitForever) != osOK)
		{
			//TODO implement timeout
			//TODO mutex error?
		}
		//Wait until double buffer switch to acquire new pointers
		osEventFlagsWait(efid_DataBufferEvents, FLAGS_DATABUFF_DBBufferSwitched, 0, osWaitForever);

		producerAddress = ___DB_GET_PRODUCER(ph_this_PacketBuffer);
		producerAddress->timeStamp = getGlobalTimer(&MantarraySystem.globalTimerTest);
		producerAddress->moduleID = COMMUNICATOR_OUTID_MAIN_MICRO;
		producerAddress->packetType = COMMUNICATOR_OUTTYPE_MAG_DATA3A;

		*(uint32_t*)(producerAddress->data + memOffset) = producerAddress->timeStamp - MantarraySystem.ph_module_block[0].timeStamp;
		memOffset += 4;
		for (uint8_t thisModule = 0; thisModule < MAXIMUM_MODULE_NUMBER; thisModule++)
		{
			MantarraySystem.ph_module_block[thisModule].axesConfig = 0b111111111;
			for (uint8_t thisSensorAxis = 0; thisSensorAxis < 9; thisSensorAxis++)
			{
				if (MantarraySystem.ph_module_block[thisModule].axesConfig & 0b100000000 >> thisSensorAxis)
				{
					*(uint16_t*)(MantarraySystem.ph_module_block[thisModule].magneticSensorA + thisSensorAxis) = thisSensorAxis * 10;
					*(uint16_t*)(producerAddress->data + memOffset) = *(uint16_t*)(MantarraySystem.ph_module_block[thisModule].magneticSensorA + thisSensorAxis);
					memOffset += 2;
				}

			}

		}
		producerAddress->packetLength = memOffset + 4;
		memOffset = 0;

		memcpy(producerAddress->magicWord, MAGIC_WORD, MAGIC_WORD_LENGTH);
		//CRC is done in two parts to account for non-sequential memory
		thisCRC = HAL_CRC_Calculate(&hcrc, (uint32_t*)producerAddress, TOTAL_PACKET_LENGTH_MINUS_DATA);
		thisCRC = HAL_CRC_Accumulate(&hcrc, (uint32_t*)producerAddress->data, producerAddress->packetLength - BASE_PACKET_LENGTH_PLUS_CRC);
		//Don't forget the bitwise complement!
		thisCRC = thisCRC ^ 0xFFFFFFFF;
		memcpy(producerAddress->data + (producerAddress->packetLength - BASE_PACKET_LENGTH_PLUS_CRC), &thisCRC, CRC_LENGTH);

		uint16_t packetDataLength = producerAddress->packetLength - BASE_PACKET_LENGTH;

		//Send a signal to TxDMA that the packet is finished being written and how long the packet is
		osMessageQueuePut(mqid_TxDMAQueue, &packetDataLength, 0, 0);

		if (osMutexGetOwner(mtid_PacketProducerMutex) == MagDataOutHandle)
		{
			if (osMutexRelease(mtid_PacketProducerMutex) != osOK)
			{
				uint8_t test = 0;
				//TODO Mutex Error?
			}
		}
	}
}

//>>Internal Bus test code
//Start the DMA in interrupt mode
	if (HAL_DMA_Start_IT(htim8.hdma[TIM_DMA_ID_CC2], (uint32_t)(GPIOE_BASE + 0x10), (uint32_t)RxGPIODMABuffer, 23) != HAL_OK)
	{
		//TODO catch DMA error
	}
	uint8_t buf[3] = {0b00001111, 0b10101010};
	HAL_I2C_Master_Transmit(&hi2c1, 0b10001110, buf, 2, 10);
	while(1)
	{
		errorCode = osEventFlagsWait(efid_DataBufferEvents, FLAGS_INTERNALBUS_Acknowledge, 0, 5);
		if (errorCode != osFlagsErrorTimeout)
		{
			errorCode = osEventFlagsWait(efid_DataBufferEvents, FLAGS_INTERNALBUS_Complete, 0, 5);
			if (errorCode != osFlagsErrorTimeout) {
				//TODO catch error
			}
			if (HAL_DMA_Start_IT(htim8.hdma[TIM_DMA_ID_CC2], (uint32_t)(GPIOE_BASE + 0x10), (uint32_t)RxGPIODMABuffer, 23) != HAL_OK)
			{
				//TODO catch DMA error
			}
		}
		HAL_Delay(5);
		HAL_I2C_Master_Transmit(&hi2c1, 0b10001110, buf, 2, 1000);
	}