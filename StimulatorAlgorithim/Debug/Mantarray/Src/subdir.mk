################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (9-2020-q2-update)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Mantarray/Src/Bus.c \
../Mantarray/Src/EEPROM.c \
../Mantarray/Src/GlobalTimer.c \
../Mantarray/Src/Magnetometer.c \
../Mantarray/Src/UART_Comm.c \
../Mantarray/Src/i2c_network_interface.c \
../Mantarray/Src/lis3mdl_driver.c \
../Mantarray/Src/mmc5983_driver.c \
../Mantarray/Src/system.c 

OBJS += \
./Mantarray/Src/Bus.o \
./Mantarray/Src/EEPROM.o \
./Mantarray/Src/GlobalTimer.o \
./Mantarray/Src/Magnetometer.o \
./Mantarray/Src/UART_Comm.o \
./Mantarray/Src/i2c_network_interface.o \
./Mantarray/Src/lis3mdl_driver.o \
./Mantarray/Src/mmc5983_driver.o \
./Mantarray/Src/system.o 

C_DEPS += \
./Mantarray/Src/Bus.d \
./Mantarray/Src/EEPROM.d \
./Mantarray/Src/GlobalTimer.d \
./Mantarray/Src/Magnetometer.d \
./Mantarray/Src/UART_Comm.d \
./Mantarray/Src/i2c_network_interface.d \
./Mantarray/Src/lis3mdl_driver.d \
./Mantarray/Src/mmc5983_driver.d \
./Mantarray/Src/system.d 


# Each subdirectory must supply rules for building sources it contributes
Mantarray/Src/Bus.o: ../Mantarray/Src/Bus.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/Bus.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/EEPROM.o: ../Mantarray/Src/EEPROM.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/EEPROM.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/GlobalTimer.o: ../Mantarray/Src/GlobalTimer.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/GlobalTimer.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/Magnetometer.o: ../Mantarray/Src/Magnetometer.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/Magnetometer.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/UART_Comm.o: ../Mantarray/Src/UART_Comm.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/UART_Comm.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/i2c_network_interface.o: ../Mantarray/Src/i2c_network_interface.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/i2c_network_interface.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/lis3mdl_driver.o: ../Mantarray/Src/lis3mdl_driver.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/lis3mdl_driver.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/mmc5983_driver.o: ../Mantarray/Src/mmc5983_driver.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/mmc5983_driver.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Mantarray/Src/system.o: ../Mantarray/Src/system.c Mantarray/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32L053xx -c -I../Core/Inc -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Src" -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray/Inc" -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Drivers/STM32L0xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/alexv/Documents/GitHub/mantarray-firmware-testcode/StimulatorAlgorithim/Mantarray" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"Mantarray/Src/system.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

