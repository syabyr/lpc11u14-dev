# EFM32 Base CMake file
#
# Configures the project files and environment for any EFM32 project
#
# Copyright (c) 2016 Ryan Kurte
# This file is covered under the MIT license available at: https://opensource.org/licenses/MIT

function(lpc11u14_configure_linker_addresses target)
    if(FLASH_ORIGIN)
        target_link_options(${target}
            PRIVATE "LINKER:--defsym=flash_origin=${FLASH_ORIGIN}"
            )
    else()
        # We always need to set FLASH_ORIGIN so that the script
        # toolchain/flash.in gets configured correctly.
        set(FLASH_ORIGIN 0x00000000 PARENT_SCOPE)
    endif()

    if(FLASH_LENGTH)
        target_link_options(${target}
            PRIVATE "LINKER:--defsym=flash_length=${FLASH_LENGTH}"
            )
    endif()

    if(RAM_ORIGIN)
        target_link_options(${target}
            PRIVATE "LINKER:--defsym=ram_origin=${RAM_ORIGIN}"
            )
    endif()

    if(RAM_LENGTH)
        target_link_options(${target}
            PRIVATE "LINKER:--defsym=ram_length=${RAM_LENGTH}"
            )
    endif()
endfunction(lpc11u14_configure_linker_addresses)

if (NOT DEFINED DEVICE)
    message(FATAL_ERROR "No processor defined")
endif ()
message("Device: ${DEVICE}")

# Convert to upper case
string(TOUPPER ${DEVICE} DEVICE_U)
message("Processor: ${DEVICE_U}")

# Determine device family by searching for an appropriate device directory
set(DEVICE_FOUND FALSE)
set(TEMP_DEVICE "${DEVICE_U}")



set(CPU_FAMILY_U ${TEMP_DEVICE})
string(TOLOWER ${CPU_FAMILY_U} CPU_FAMILY_L)
message("Family: ${CPU_FAMILY_U}")

# Determine core type
# TODO: find a neater (array based) way of doing this
if (CPU_FAMILY_U STREQUAL "LPC11U14")
    message("Architecture: cortex-m0plus")
    set(CPU_TYPE "m0plus")
    set(CPU_FIX "")
else ()
    message("Architecture: cortex-m3 (default)")
    set(CPU_TYPE "m3")
    set(CPU_FIX "-mfix-cortex-m3-ldrd")
endif ()

# Set compiler flags
# Common arguments
add_definitions("-D__REDLIB__")

if(CMAKE_BUILD_TYPE STREQUAL "RELEASE")
    message("release")
    add_definitions("-DNDEBUG")
else()
    message("debug")
    add_definitions("-DDEBUG")
endif ()

add_definitions("-D__CODE_RED")
add_definitions("-D__USE_LPCOPEN")
add_definitions("-DCORE_M0")

set(COMMON_DEFINITIONS "-Wextra -Wall -Wno-unused-parameter -mcpu=cortex-${CPU_TYPE} -mthumb -fno-builtin -ffunction-sections -fdata-sections -fomit-frame-pointer ${OPTIONAL_DEBUG_SYMBOLS}")
set(DEPFLAGS "-MMD -MP -D__REDLIB__ -DDEBUG -D__CODE_RED -D__USE_LPCOPEN -DCORE_M0")






# Enable FLTO optimization if required
if (USE_FLTO)
    set(OPTFLAGS "-Os -flto")
else ()
    set(OPTFLAGS "-Os")
endif ()

# Build flags
if(CMAKE_BUILD_TYPE STREQUAL "RELEASE")
    set(CMAKE_C_FLAGS "-Os -g -Wall -c -fmessage-length=0 -fno-builtin -ffunction-sections -fdata-sections ${COMMON_DEFINITIONS} ${CPU_FIX} --specs=nano.specs ${DEPFLAGS}")
else()
    set(CMAKE_C_FLAGS "-O0 -g3 -Wall -c -fmessage-length=0 -fno-builtin -ffunction-sections -fdata-sections -fmerge-constants ${COMMON_DEFINITIONS} ${CPU_FIX} --specs=nano.specs ${DEPFLAGS}")
endif ()

set(CMAKE_C_FLAGS "-std=gnu99 ${COMMON_DEFINITIONS} ${CPU_FIX} --specs=nano.specs ${DEPFLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_DEFINITIONS} ${CPU_FIX} --specs=nano.specs ${DEPFLAGS}")
set(CMAKE_ASM_FLAGS "${COMMON_DEFINITIONS} -x assembler-with-cpp -DLOOP_ADDR=0x8000")

# Set default inclusions
#set(LIBS ${LIBS} -lgcc -lc -lnosys -lgcc -lc -lnosys)

# Debug Flags
set(COMMON_DEBUG_FLAGS "-O0 -g3 -Wall -fmessage-length=0 -fno-builtin -ffunction-sections -fdata-sections -fmerge-constants")
set(CMAKE_C_FLAGS_DEBUG "${COMMON_DEBUG_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "${COMMON_DEBUG_FLAGS}")
set(CMAKE_ASM_FLAGS_DEBUG "${COMMON_DEBUG_FLAGS}")

# Release Flags
set(COMMON_RELEASE_FLAGS "${OPTFLAGS} -DNDEBUG=1 -DRELEASE=1 -Wall -fmessage-length=0 -fno-builtin -ffunction-sections -fdata-sections")
set(CMAKE_C_FLAGS_RELEASE "${COMMON_RELEASE_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "${COMMON_RELEASE_FLAGS}")
set(CMAKE_ASM_FLAGS_RELEASE "${COMMON_RELEASE_FLAGS}")

# Print debug info helper function
function(print_debug_info)
    message("COMPILER_PREFIX =${COMPILER_PREFIX}")
    message("CMAKE_SOURCE_DIR =${CMAKE_SOURCE_DIR}")
    message("CMAKE_C_COMPILER =${CMAKE_C_COMPILER}")
    message("CMAKE_C_FLAGS =${CMAKE_C_FLAGS}")
    message("CMAKE_C_LINK_EXECUTABLE =${CMAKE_C_LINK_EXECUTABLE}")
    message("CMAKE_EXE_LINKER_FLAGS =${CMAKE_EXE_LINKER_FLAGS}")
    message("CMAKE_AR =${CMAKE_AR}")

    message("Definitions: ")
    get_directory_property(defs DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS)
    foreach (def ${defs})
        message(STATUS "-D${def}")
    endforeach ()

    get_property(dirs TARGET ${PROJECT_NAME} PROPERTY INCLUDE_DIRECTORIES)
    message("Includes: ")
    foreach (dir ${dirs})
        message(STATUS "${dir}")
    endforeach ()

    get_property(libs TARGET ${PROJECT_NAME} PROPERTY LINK_LIBRARIES)
    message("Libraries:")
    foreach (libs ${libs})
        message(STATUS "${libs}")
    endforeach ()
endfunction()
