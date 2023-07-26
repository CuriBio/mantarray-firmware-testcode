cmake_minimum_required(VERSION 3.12)

set(CMAKE_C_COMPILER "/usr/bin/arm-none-eabi-gcc" CACHE STRING "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "/usr/bin/arm-none-eabi-g++" CACHE STRING "C++ compiler" FORCE)
set(CMAKE_AR  "/usr/bin/arm-none-eabi-ar")
set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> qcs <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_FINISH   true)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
#set(PICO_BOARD none)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --specs=nosys.specs -fstack-protector-strong")
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)


add_compile_options(-Wall
        -Wno-format          # int != int32_t as far as the compiler is concerned because gcc has int32_t as long int
        -Wno-unused-function # we have some for the docs that aren't called
        )
if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-Wno-maybe-uninitialized)
endif()

include(pico_sdk_import.cmake)
project(CableTester C CXX ASM)
pico_sdk_init()

include_directories(CableTester PUBLIC
    ./Inc
)

add_executable(CableTester
        main.c
        )

# pull in common dependencies
target_link_libraries(CableTester pico_stdlib hardware_i2c)

target_link_options(CableTester PUBLIC -Wl,--print-memory-usage)
pico_enable_stdio_usb(CableTester 1)
pico_enable_stdio_uart(CableTester 0)

# create map/bin/hex/uf2 file etc.
pico_add_extra_outputs(CableTester)






