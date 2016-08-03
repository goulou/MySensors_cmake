
SET(CMAKE_CROSSCOMPILING 1)

#set this to "-flto" to enable LTO
set(LTO_FLAGS "-flto -fno-fat-lto-objects")

# Find Arduino SDK delivered programs
find_program(AR_AVR_GCC     NAMES avr-gcc     PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_CXX     NAMES avr-g++     PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_OBJCOPY NAMES avr-objcopy PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_OBJDUMP NAMES avr-objdump PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_RANLIB  NAMES avr-gcc-ranlib  PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_LD      NAMES avr-ld      PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_SIZE    NAMES avr-size    PATHS ${ARDUINO_TOOLSET_PATH}/bin)
find_program(AR_AVR_AR      NAMES avr-gcc-ar    PATHS ${ARDUINO_TOOLSET_PATH}/bin)

set(CMAKE_AR ${AR_AVR_AR})
set(CMAKE_RANLIB ${AR_AVR_RANLIB})

find_program(AR_AVRDUDE NAMES avrdude PATHS ${ARDUINO_PATH}/hardware/tools/)
find_file(AR_AVRDUDE_CFG NAMES avrdude.conf PATHS ${ARDUINO_PATH}/**/ /etc/avrdude/)

find_path(pgmPath avr/pgmspace.h PATHS /usr/lib/avr/include)
if(pgmPath)
  include_directories(SYSTEM ${pgmPath})
else()
  message(FATAL_ERROR "Failed to find pgmspace.h")
endif()

function(make_arduino_program PROGRAM_NAME)

    # Compiler flags
    add_definitions(${LTO_FLAGS} -mmcu=${MCU} -DF_CPU=${CPU_SPEED})
    add_definitions(-c -g -O3 -Wall)
    add_definitions(-fno-exceptions -ffunction-sections -fdata-sections -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums)
    add_definitions(-DARDUINO=160 -DAVR=1 -D${MCU_MACRO}=1 -D__ATmegaxx0__=1 -DARDUINO_ARCH_AVR=1 -DPROGRAM_NAME=${PROGRAM_NAME} ${PROGRAM_DEFS})

    # Linker flags
    set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")   # remove -rdynamic for C
    set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "") # remove -rdynamic for CXX
 #    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LTO_FLAGS} -Os -Wl,--gc-sections -mmcu=${MCU} -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums")

    add_subdirectory(${ARDUINO_PATH} ${CMAKE_CURRENT_BINARY_DIR}/Arduino)
    add_subdirectory(${LIBRARIES_PATH} ${CMAKE_CURRENT_BINARY_DIR}/libraries)
    add_subdirectory(${MYSENSORS_PATH} ${CMAKE_CURRENT_BINARY_DIR}/MySensors)
    add_subdirectory(${CMAKE_SOURCE_DIR}/Common ${CMAKE_CURRENT_BINARY_DIR}/Common)

    add_executable(${PROGRAM_NAME}
    	${SRC_FILES_C}
    	${SRC_FILES_CPP}
    	)

    set_target_properties(${PROGRAM_NAME} PROPERTIES LINK_FLAGS "${LTO_FLAGS} -O2 -Wl,--gc-sections -mmcu=${MCU} -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums")

    target_link_libraries(${PROGRAM_NAME} Arduino_${DEVICE_NAME})
    target_link_libraries(${PROGRAM_NAME} MySensors_${DEVICE_NAME})
    #target_link_libraries(${PROGRAM_NAME} Common_${DEVICE_NAME})
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

