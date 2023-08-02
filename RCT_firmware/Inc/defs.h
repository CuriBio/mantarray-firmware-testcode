#ifndef DEFS_H
#define DEFS_H

#define I2C_SPEED 50E3
#define I2C_SDA_PIN 0
#define I2C_SCL_PIN 1

#define OUTPUT_EXP_ADDR_0 0x46 >>1
#define OUTPUT_EXP_ADDR_1 0x40 >>1
#define INPUT_EXP_ADDR_0 0x42 >>1
#define INPUT_EXP_ADDR_1 0x44 >>1

#define INPUT_BASE_ADDR 0x00 
#define CONFIG_BASE_ADDR 0x0F 

#define STATUS_LED_GREEN 13
#define STATUS_LED_RED   14

#endif /* DEFS_H */