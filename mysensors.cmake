
SET(CMAKE_SYSTEM_PROCESSOR arm)
SET(CMAKE_CROSSCOMPILING 1)

#set this to "-flto" to enable LTO
set(LTO_FLAGS "")

# Find Arduino SDK delivered programs
find_program(AR_AVR_GCC NAMES avr-gcc PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)
find_program(AR_AVR_CXX NAMES avr-g++ PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)
find_program(AR_AVR_OBJCOPY NAMES avr-objcopy PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)
find_program(AR_AVR_OBJDUMP NAMES avr-objdump PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)
find_program(AR_AVR_RANLIB NAMES avr-ranlib PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)
find_program(AR_AVR_LD NAMES avr-ld PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)
find_program(AR_AVR_SIZE NAMES avr-size PATHS ${ARDUINO_PATH}/hardware/tools/avr/bin)

# Compiler flags
add_definitions(${LTO_FLAGS} -mmcu=${MCU} -DF_CPU=${CPU_SPEED})
add_definitions(-c -g -Os -Wall)
add_definitions(-fno-exceptions -ffunction-sections -fdata-sections)
add_definitions(-DARDUINO=160 -DAVR=1)

# Linker flags
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")   # remove -rdynamic for C
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "") # remove -rdynamic for CXX
set(CMAKE_EXE_LINKER_FLAGS "${LTO_FLAGS} -Os -Wl,--gc-sections -mmcu=${MCU}")

add_subdirectory(${ARDUINO_PATH})
add_subdirectory(${MYSENSORS_PATH})



add_executable(${PROJECT_NAME} 
	${SRC_FILES_C}
	${SRC_FILES_CPP}
	)

target_link_libraries(${PROJECT_NAME} Arduino)
target_link_libraries(${PROJECT_NAME} MySensors)




find_program(AR_AVRDUDE NAMES avrdude PATHS ${ARDUINO_PATH}/hardware/tools/)
file(GLOB_RECURSE AR_AVRDUDE_CFG ${ARDUINO_PATH}/**/avrdude.conf)

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
		COMMAND ${AR_AVR_OBJCOPY} -R .eeprom -O ihex ${PROJECT_NAME}  "${PROJECT_NAME}.hex"
		COMMAND ${AR_AVR_OBJDUMP} -h -S ${PROJECT_NAME}  >"${PROJECT_NAME}.lss"
		COMMAND ${AR_AVR_OBJCOPY} -j .eeprom --no-change-warnings --change-section-lma .eeprom=0 -O ihex ${PROJECT_NAME}  "${PROJECT_NAME}.eep"
		COMMAND ${AR_AVR_SIZE} --format=avr --mcu=${MCU} ${PROJECT_NAME}
		)

add_custom_target(download 
	COMMAND ${CMAKE_OBJCOPY} -j .text -j .data -O ihex ${PROJECT_NAME} ${PROJECT_NAME}.hex
	COMMAND ${AR_AVRDUDE} -C${AR_AVRDUDE_CFG} -F -p${MCU} -c${PROGRAMMER} -P${PORT} -b${PORT_SPEED} -D -Uflash:w:${PROJECT_NAME}.hex:i
	DEPENDS ${PROJECT_NAME}
	)
