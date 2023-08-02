
#include <stdio.h>
#include "pico/stdlib.h"
#include <stdint.h>
#include <stdbool.h>
#include <string.h> 
#include "hardware/i2c.h"


#include "defs.h"

void comms_error(){
    while(1){
        gpio_put(STATUS_LED_GREEN, true);
        gpio_put(STATUS_LED_RED, false);
        sleep_ms(150);
        gpio_put(STATUS_LED_RED, true);
        gpio_put(STATUS_LED_GREEN, false);
        sleep_ms(150);
    }
}


uint8_t pin_remap(uint8_t pin_input){
    if( pin_input <= 24 ) return pin_input*2+1;
    return (50-pin_input)*2;
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

    for(int i=0; i<4; i++){
        gpio_put(STATUS_LED_GREEN, true);
        gpio_put(STATUS_LED_RED, false);
        sleep_ms(100);
        gpio_put(STATUS_LED_RED, true);
        gpio_put(STATUS_LED_GREEN, false);
        sleep_ms(100);
    }
    gpio_put(STATUS_LED_RED, false);
    gpio_put(STATUS_LED_GREEN, false);
    //while(!stdio_usb_connected());

    // validate that all expanders are communicating
    uint8_t found_devices = 0;
    uint8_t devices[] = {INPUT_EXP_ADDR_0, INPUT_EXP_ADDR_1, OUTPUT_EXP_ADDR_0, OUTPUT_EXP_ADDR_1};
    for(int device=0; device<sizeof(devices); device++){
        uint8_t dummy = 0 ;
        int bread = i2c_write_timeout_us(i2c0, devices[device], &dummy, 1, false, 1000);
        printf("Device 0x%x: %s\n", devices[device] << 1, bread == 1 ? "PASS" : "FAIL");
        if(bread == 1) found_devices++;
    }

    if(found_devices != 4){
        comms_error();
    }
    
    printf("Program initialized.\n");

    while (true) {

        printf("========================\n");
        uint8_t results[51];
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
            byte_buffer[0] = CONFIG_BASE_ADDR;
            uint32_t pins_inv = ~pins;
            memcpy(&byte_buffer[1], &pins_inv, 4);
            n_trans = i2c_write_timeout_us(i2c0, output_addr_act, byte_buffer, 5, false, 2000);
            if( n_trans != 5 ) comms_error();

            // set unused bits
            byte_buffer[0] = CONFIG_BASE_ADDR;
            memset(&byte_buffer[1], 0xFF, 4);
            n_trans = i2c_write_timeout_us(i2c0, output_addr_alt, byte_buffer, 5, false, 2000);
            if( n_trans != 5 ) comms_error();

            // read active input bits
            byte_buffer[0] = INPUT_BASE_ADDR;
            n_trans = i2c_write_timeout_us(i2c0, input_addr_act, byte_buffer, 1, true, 2000);
            if( n_trans != 1 ) comms_error();
            memset(byte_buffer, 0, 4);
            n_trans = i2c_read_timeout_us(i2c0, input_addr_act, byte_buffer, 4, false, 2000);
            if( n_trans != 4 ) comms_error();
            uint32_t pins_read_act = *((uint32_t*)byte_buffer) & ~(0b1111111 << 25); // top 7 IO pins are not used and need to be masked off

            // read alt bits
            byte_buffer[0] = INPUT_BASE_ADDR;
            n_trans = i2c_write_timeout_us(i2c0, input_addr_alt, byte_buffer, 1, true, 2000);
            if( n_trans != 1 ) comms_error();
            memset(byte_buffer, 0, 4);
            n_trans = i2c_read_timeout_us(i2c0, input_addr_alt, byte_buffer, 4, false, 2000);
            if( n_trans != 4 ) comms_error();
            uint32_t pins_read_alt = *((uint32_t*)byte_buffer) & ~(0b1111111 << 25); // top 7 IO pins are not used and need to be masked off

            if( pins_read_act != pins || pins_read_alt != 0){
                switch( __builtin_popcount(pins_read_act) + __builtin_popcount(pins_read_alt)){
                    case 0:
                        // OPEN
                        results[pin_remap(i)] = 1;
                        break;
                    case 1:
                        // CROSSED
                        results[pin_remap(i)] = 2;
                        break;
                    default:
                        // SHORTED
                        results[pin_remap(i)] = 3;
                }
            }
            else{
                results[pin_remap(i)] = 0;
            }
        }
        
        bool cable_26pin = true;
        bool cable_good = true;
        for(int i=1; i<=50; i++){
            if( i <= 26 && results[i] != 0) cable_26pin = false;
            if( i > 26 && results[i] != 1) cable_26pin = false;
        }
        for(int i=1; i<=( cable_26pin ? 26 : 50); i++){
            char* result = "";
            switch(results[i]){
                case 1:
                    result = "OPEN";
                    break;
                case 2:
                    result = "CROSSED";
                    break;
                case 3:
                    result = "SHORTED";
                    break;
            }
            if(results[i] > 0){
                printf("PIN %02d: %s\n", i, result);
                cable_good = false;
            }
        }

        printf("\nCABLE TYPE: %s\n", cable_26pin ? "26 PIN" : "50 PIN");
        printf("RESULT: %s\n", cable_good ? "PASS" : "FAIL");

        if(stdio_usb_connected()){
            if( cable_good ){
                gpio_put(STATUS_LED_RED, false);
                gpio_put(STATUS_LED_GREEN, true);
            }else{
                gpio_put(STATUS_LED_RED, true);
                gpio_put(STATUS_LED_GREEN, false);
            }

            sleep_ms(700);
            gpio_put(STATUS_LED_RED, false);
            gpio_put(STATUS_LED_GREEN, false);  

            while(getchar_timeout_us(100) != PICO_ERROR_TIMEOUT);
            printf("PRESS ENTER TO TEST AGAIN...\n");
            while(getchar_timeout_us(100) == PICO_ERROR_TIMEOUT && stdio_usb_connected());


            

        }else{
            sleep_ms(120); // idk.
            if( cable_good ){
                gpio_put(STATUS_LED_RED, false);
                gpio_put(STATUS_LED_GREEN, !gpio_get(STATUS_LED_GREEN));
            }else{
                gpio_put(STATUS_LED_GREEN, false);
                gpio_put(STATUS_LED_RED, !gpio_get(STATUS_LED_RED));
            }
        }

        
    }
}