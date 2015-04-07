
SET(CMAKE_CROSSCOMPILING 1)

#set this to "-flto" to enable LTO
set(LTO_FLAGS "")

# Find Arduino SDK delivered programs
find_program(AR_AVR_GCC     NAMES avr-gcc     PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_CXX     NAMES avr-g++     PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_OBJCOPY NAMES avr-objcopy PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_OBJDUMP NAMES avr-objdump PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_RANLIB  NAMES avr-ranlib  PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_LD      NAMES avr-ld      PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_SIZE    NAMES avr-size    PATHS ${ARDUINO_TOOLSET_PATH}/bin)

# Compiler flags
add_definitions(${LTO_FLAGS} -mmcu=${MCU} -DF_CPU=${CPU_SPEED})
add_definitions(-c -g -Os -Wall)
add_definitions(-fno-exceptions -ffunction-sections -fdata-sections -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums)
add_definitions(-DARDUINO=160 -DAVR=1 -D${MCU_MACRO}=1 -D__ATmegaxx0__=1)

# Linker flags
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")   # remove -rdynamic for C
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "") # remove -rdynamic for CXX
set(CMAKE_EXE_LINKER_FLAGS "${LTO_FLAGS} -Os -Wl,--gc-sections -mmcu=${MCU} -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums")

add_subdirectory(${ARDUINO_PATH})
add_subdirectory(${MYSENSORS_PATH})

find_program(AR_AVRDUDE NAMES avrdude PATHS ${ARDUINO_PATH}/hardware/tools/)
find_file(AR_AVRDUDE_CFG NAMES avrdude.conf PATHS ${ARDUINO_PATH}/**/ /etc/avrdude/)

function(make_arduino_program PROGRAM_NAME)
    add_executable(${PROGRAM_NAME}
    	${SRC_FILES_C}
    	${SRC_FILES_CPP}
    	)
    target_link_libraries(${PROGRAM_NAME} Arduino)
    target_link_libraries(${PROGRAM_NAME} MySensors)
    add_custom_command(TARGET ${PROGRAM_NAME} POST_BUILD
    		COMMAND ${AR_AVR_OBJCOPY} -R .eeprom -O ihex ${PROGRAM_NAME}  "${PROGRAM_NAME}.hex"
    		COMMAND ${AR_AVR_OBJDUMP} -h -S ${PROGRAM_NAME}  >"${PROGRAM_NAME}.lss"
    		COMMAND ${AR_AVR_OBJCOPY} -j .eeprom --no-change-warnings --change-section-lma .eeprom=0 -O ihex ${PROGRAM_NAME}  "${PROGRAM_NAME}.eep"
    		COMMAND ${AR_AVR_SIZE} --format=avr --mcu=${MCU} ${PROGRAM_NAME}
    		)

    add_custom_target(upload_${PROGRAM_NAME}
    	COMMAND ${AR_AVR_OBJCOPY} -j .text -j .data -O ihex ${PROGRAM_NAME} ${PROGRAM_NAME}.hex
    	COMMAND ${AR_AVRDUDE} -C${AR_AVRDUDE_CFG} -F -p${MCU} -c${PROGRAMMER} -P${PORT} -b${PORT_SPEED} -D -Uflash:w:${PROGRAM_NAME}.hex:i
    	DEPENDS ${PROGRAM_NAME}
    	)


endfunction(make_arduino_program)

