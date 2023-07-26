
#include <stdio.h>
#include "pico/stdlib.h"
#include <stdint.h>
#include <stdbool.h>
#include <string.h> 
#include "hardware/i2c.h"


#include "defs.h"

void comms_error(){
    gpio_put(STATUS_LED_GREEN, false);
    gpio_put(STATUS_LED_RED, true);
    while(1);
}


int main() {
    stdio_init_all();

    gpio_init(STATUS_LED_GREEN);
    gpio_set_dir(STATUS_LED_GREEN, GPIO_OUT);
    gpio_set_drive_strength(STATUS_LED_GREEN, GPIO_DRIVE_STRENGTH_12MA );
    gpio_init(STATUS_LED_RED);
    gpio_set_dir(STATUS_LED_RED, GPIO_OUT);
    gpio_set_drive_strength(STATUS_LED_RED, GPIO_DRIVE_STRENGTH_12MA );

    gpio_put(STATUS_LED_GREEN, false);
    gpio_put(STATUS_LED_RED, true);

    i2c_init(i2c0, I2C_SPEED);
    gpio_set_function(I2C_SDA_PIN, GPIO_FUNC_I2C);
    gpio_set_function(I2C_SCL_PIN, GPIO_FUNC_I2C);


    // validate that all expanders are communicating
    uint8_t devices[] = {INPUT_EXP_ADDR_0, INPUT_EXP_ADDR_1, OUTPUT_EXP_ADDR_0, OUTPUT_EXP_ADDR_1};
    for(int device=0; device<sizeof(devices); device++){
        uint8_t dummy;
        int bread = i2c_read_timeout_us(i2c0, device, &dummy, 1, false, 1000);
        if( bread != 1 ){
            // Device not found. No need to do anything else.
            comms_error();
        }
    }
    
    sleep_ms(500);
    printf("Program initialized.\n");

    while (true) {

        bool cable_good = true;

        printf("========================\n");
        // set one output high and test that all but the corresponding input is low
        for(int i=0; i<50; i++){

            uint8_t byte_buffer[5];
            int n_trans = 0;

            uint8_t output_addr_act = i < 25 ? OUTPUT_EXP_ADDR_0 : OUTPUT_EXP_ADDR_1;
            uint8_t output_addr_alt = i >= 25 ? OUTPUT_EXP_ADDR_0 : OUTPUT_EXP_ADDR_1;
            uint8_t input_addr_act = i < 25 ? INPUT_EXP_ADDR_0 : INPUT_EXP_ADDR_1;
            uint8_t input_addr_alt = i >= 25 ? INPUT_EXP_ADDR_0 : INPUT_EXP_ADDR_1;
            uint32_t pins = 1 << ( i < 25 ? i : i - 25);


            // set active output bits
            byte_buffer[0] = OUTPUT_BASE_ADDR;
            memcpy(&byte_buffer[1], &pins, 4);
            n_trans = i2c_write_timeout_us(i2c0, output_addr_act, byte_buffer, 5, false, 1000);
            if( n_trans != 5 ) comms_error();

            // set unused bits
            byte_buffer[0] = OUTPUT_BASE_ADDR;
            memset(&byte_buffer[1], 0, 4);
            n_trans = i2c_write_timeout_us(i2c0, output_addr_alt, byte_buffer, 5, false, 1000);
            if( n_trans != 5 ) comms_error();

            // read active input bits
            byte_buffer[0] = INPUT_BASE_ADDR;
            n_trans = i2c_write_timeout_us(i2c0, input_addr_act, byte_buffer, 1, true, 1000);
            if( n_trans != 1 ) comms_error();
            memset(byte_buffer, 0, 4);
            n_trans = i2c_read_timeout_us(i2c0, input_addr_act, byte_buffer, 4, false, 1000);
            if( n_trans != 4 ) comms_error();
            uint32_t pins_read_act = *((uint32_t*)byte_buffer) & ~(0b1111111 << 24); // top 7 IO pins are not used and need to be masked off

            // read alt bits
            byte_buffer[0] = INPUT_BASE_ADDR;
            n_trans = i2c_write_timeout_us(i2c0, input_addr_alt, byte_buffer, 1, true, 1000);
            if( n_trans != 1 ) comms_error();
            memset(byte_buffer, 0, 4);
            n_trans = i2c_read_timeout_us(i2c0, input_addr_alt, byte_buffer, 4, false, 1000);
            if( n_trans != 4 ) comms_error();
            uint32_t pins_read_alt = *((uint32_t*)byte_buffer) & ~(0b1111111 << 24); // top 7 IO pins are not used and need to be masked off

            if( pins_read_act != pins || pins_read_alt != 0){
                cable_good = false;
                char* result;
                switch( __builtin_popcount(pins_read_act) + __builtin_popcount(pins_read_alt)){
                    case 0:
                        result = "OPEN";
                        break;
                    case 1:
                        result = "CROSSED";
                        break;
                    default:
                        result = "SHORTED";
                }
                printf("PIN %d: %s.\n", i, result);
            }
        }
        
        if(stdio_usb_connected()){
            if( cable_good ){
                gpio_put(STATUS_LED_RED, false);
                gpio_put(STATUS_LED_GREEN, true);
            }else{
                gpio_put(STATUS_LED_RED, true);
                gpio_put(STATUS_LED_GREEN, false);
            }
            sleep_ms(500);
            gpio_put(STATUS_LED_RED, false);
            gpio_put(STATUS_LED_GREEN, false);  

        }else{
            sleep_ms(250); // idk.
            if( cable_good ){
                gpio_put(STATUS_LED_RED, false);
                gpio_put(STATUS_LED_GREEN, gpio_get(STATUS_LED_GREEN));
            }else{
                gpio_put(STATUS_LED_GREEN, false);
                gpio_put(STATUS_LED_RED, gpio_get(STATUS_LED_RED));
            }
        }

        printf("RESULT: %s\n", cable_good ? "PASS" : "FAIL");
    }
}