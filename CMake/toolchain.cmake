# Copyright (C) 2014 ARM Limited. All rights reserved. 

cmake_minimum_required(VERSION 2.8)

# search path for included .cmake files (set this as early as possible, so that
# indirect includes still use it)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(CMakeForceCompiler)


 
set(CMAKE_SYSTEM_NAME Yottos)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "armv7-m")

set(CMAKE_STATIC_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")
set(CMAKE_EXECUTABLE_SUFFIX "")
set(CMAKE_C_OUTPUT_EXTENSION ".o")
set(CMAKE_ASM_OUTPUT_EXTENSION ".o")
set(CMAKE_CXX_OUTPUT_EXTENSION ".o")


# !!! FIXME: this line should actually be the substantial content of this file,
# most other stuff belongs elsewhere.
# !!! FIXME: also add the arch/core definitions here, and maybe the standard
# format for these should be TARGET_XXX CHIP_YYY VARIANT_ZZZ etc, to reduce the
# possibility of collisions
set(YOTTA_TARGET_DEFINITIONS "-DSTK3700 -DEFM32GG990F1024 -DEFM32GG -DEFM32")


# actual link commands are overridden later, just save the paths into internal
# variables for now
find_program(_ARM_GNU_GCC       NAMES arm-none-eabi-gcc)
find_program(_ARM_GNU_GPP       NAMES arm-none-eabi-g++)
find_program(_ARM_GNU_AS        NAMES arm-none-eabi-as)
find_program(_ARM_GNU_RANLIB    NAMES arm-none-eabi-ranlib)
find_program(_ARM_GNU_AR        NAMES arm-none-eabi-ar)
find_program(_ARM_GNU_OBJCOPY   NAMES arm-none-eabi-objcopy)
find_program(_ARM_GNU_OBJDUMP   NAMES arm-none-eabi-objdump)
find_program(_ARM_GNU_NM        NAMES arm-none-eabi-nm)
find_program(_ARM_GNU_STRIP     NAMES arm-none-eabi-strip)
find_program(_ARM_GNU_LINKER    NAMES arm-none-eabi-ld)

set(CMAKE_C_COMPILER ${_ARM_GNU_GCC})
set(CMAKE_ASM_COMPILER ${_ARM_GNU_GCC})
set(CMAKE_CXX_COMPILER ${_ARM_GNU_GPP})

# TODO: move as much of setup as reasonable into a
# Platform/${CMAKE_SYSTEM_NAME}-${CMAKE_C[XX}_COMPILER_ID}-C[XX]-${CMAKE_SYSTEM_PROCESSOR}
# file (included from CMakeC[XX]Information.cmake)
CMAKE_FORCE_C_COMPILER("${CMAKE_C_COMPILER}"     GNU)
CMAKE_FORCE_CXX_COMPILER("${CMAKE_CXX_COMPILER}" GNU)
set(CMAKE_C_COMPILER_WORKS   TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_ASM_COMPILER_WORKS TRUE)

if(NOT _ARM_GNU_GCC)
    message(FATAL_ERROR "A version of arm-none-eabi-gcc could not be found")
endif()

execute_process(
    COMMAND "${_ARM_GNU_GCC}" "--version"
    OUTPUT_VARIABLE _ARM_GNU_GCC_VERSION_OUTPUT
)
string(REGEX REPLACE ".* ([0-9]+[.][0-9]+[.][0-9]+) .*" "\\1" _ARM_GNU_GCC_VERSION "${_ARM_GNU_GCC_VERSION_OUTPUT}")
#message("GCC version is: ${_ARM_GNU_GCC_VERSION}")

mark_as_advanced(
    _ARM_GNU_GCC
    _ARM_GNU_RANLIB
    _ARM_GNU_AR
    _ARM_GNU_OBJCOPY
    _ARM_GNU_OBJDUMP
    _ARM_GNU_NM
    _ARM_GNU_STRIP
    _ARM_GNU_LINKER
)

# use GNU binutils
set(CMAKE_RANLIB              "${_ARM_GNU_RANLIB}" )
set(CMAKE_AR                  "${_ARM_GNU_AR}"     )
set(CMAKE_OBJCOPY             "${_ARM_GNU_OBJCOPY}")
set(CMAKE_OBJDUMP             "${_ARM_GNU_OBJDUMP}")
set(CMAKE_NM                  "${_ARM_GNU_NM}"     )
set(CMAKE_STRIP               "${_ARM_GNU_STRIP}"  )
set(CMAKE_LINKER              "${_ARM_GNU_LINKER}" )

# Override the link rules to use the gcc ld, NB C_FLAGS are NOT passed as they
# normally would be (since we use C_FLAGS to specify clang-specific things,
# like -integrated-as)
set(CMAKE_C_CREATE_SHARED_LIBRARY "echo 'shared libraries not supported' && 1")
set(CMAKE_C_CREATE_SHARED_MODULE  "echo 'shared modules not supported' && 1")
# something (enable_language?) is clobbering CMAKE_AR etc. variables...
set(CMAKE_C_CREATE_STATIC_LIBRARY "${_ARM_GNU_AR} -cr <LINK_FLAGS> <TARGET> <OBJECTS>")
set(CMAKE_C_COMPILE_OBJECT        "<CMAKE_C_COMPILER> ${YOTTA_TARGET_DEFINITIONS} <DEFINES> <FLAGS> -o <OBJECT> -c <SOURCE>")
set(CMAKE_C_LINK_EXECUTABLE       "${_ARM_GNU_GCC} <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> <LINK_LIBRARIES> -o <TARGET>")

# CMake treats objective C as CXX
set(CMAKE_CXX_CREATE_SHARED_LIBRARY "echo 'shared libraries not supported' && 1")
set(CMAKE_CXX_CREATE_SHARED_MODULE  "echo 'shared modules not supported' && 1")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "${_ARM_GNU_AR} -cr <LINK_FLAGS> <TARGET> <OBJECTS>")
set(CMAKE_CXX_COMPILE_OBJECT        "<CMAKE_CXX_COMPILER> ${YOTTA_TARGET_DEFINITIONS} <DEFINES> <FLAGS> -o <OBJECT> -c <SOURCE>")
set(CMAKE_CXX_LINK_EXECUTABLE       "${_ARM_GNU_GCC} <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> <LINK_LIBRARIES> -lstdc++ -lsupc++ -o <TARGET>")

set(CMAKE_C_FLAGS_INIT "-std=gnu99 -fno-exceptions -fno-unwind-tables -mcpu=cortex-m3 -mthumb -mfloat-abi=soft -nostdinc -nostdlib -ffreestanding -fno-builtin -ffunction-sections -fdata-sections -Wall -Wextra -D__packed=__attribute__\\(\\(__packed__\\)\\) -D__thumb2__")
set(CMAKE_C_FLAGS_DEBUG_INIT          "${CMAKE_C_FLAGS_INIT} -g")
set(CMAKE_C_FLAGS_MINSIZEREL_INIT     "${CMAKE_C_FLAGS_INIT} -Os -DNDEBUG")
set(CMAKE_C_FLAGS_RELEASE_INIT        "${CMAKE_C_FLAGS_INIT} -Os -DNDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "${CMAKE_C_FLAGS_INIT} -Os -g -DNDEBUG")
set(CMAKE_INCLUDE_SYSTEM_FLAG_C "-isystem ")

set(CMAKE_CXX_FLAGS_INIT "${CMAKE_C_FLAGS_INIT} -fno-exceptions -fno-unwind-tables")
set(CMAKE_CXX_FLAGS_DEBUG_INIT          "${CMAKE_CXX_FLAGS_INIT} -g")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT     "${CMAKE_CXX_FLAGS_INIT} -Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT        "${CMAKE_CXX_FLAGS_INIT} -Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "${CMAKE_CXX_FLAGS_INIT} -Os -g -DNDEBUG")
set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")

# !!! can't use CMAKE_ASM_FLAGS_INIT to set necessary asm flags, as they get
# clobbered when enable_language(asm) is called

set(CMAKE_ASM_FLAGS_INIT  "-fno-exceptions -fno-unwind-tables -mcpu=cortex-m3 -mthumb -x assembler-with-cpp -mfloat-abi=soft -nostdinc -nostdlib -ffreestanding -fno-builtin -D__thumb2__")
set(CMAKE_ASM_FLAGS_DEBUG_INIT          "${CMAKE_ASM_FLAGS_INIT} -g")
set(CMAKE_ASM_FLAGS_MINSIZEREL_INIT     "${CMAKE_ASM_FLAGS_INIT} -Os -DNDEBUG")
set(CMAKE_ASM_FLAGS_RELEASE_INIT        "${CMAKE_ASM_FLAGS_INIT} -Os -DNDEBUG")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO_INIT "${CMAKE_ASM_FLAGS_INIT} -Os -g -DNDEBUG")
set(CMAKE_INCLUDE_SYSTEM_FLAG_ASM  "-isystem ")

# include paths for standard libs (use gcc's)
exec_program("${_ARM_GNU_GCC} -print-libgcc-file-name" OUTPUT_VARIABLE _ARM_GNU_LIBGCC)
get_filename_component(_ARM_GNU_GCC_DIR ${_ARM_GNU_GCC} DIRECTORY)
get_filename_component(_ARM_GNU_LIBGCC_DIR ${_ARM_GNU_LIBGCC} DIRECTORY)

include_directories(SYSTEM 
    # NB: no compiler/system c library: the c library is a module like
    # everything else
    # !!! TODO: module-ify the c++ lib, then these will also no longer be hardcoded
    "/usr/local/Cellar/arm-none-eabi-gcc/4.8-2013-q4-major/bin/../lib/gcc/arm-none-eabi/${_ARM_GNU_GCC_VERSION}/../../../../arm-none-eabi/include/c++/${_ARM_GNU_GCC_VERSION}"
    "/usr/local/Cellar/arm-none-eabi-gcc/4.8-2013-q4-major/bin/../lib/gcc/arm-none-eabi/${_ARM_GNU_GCC_VERSION}/../../../../arm-none-eabi/include/c++/${_ARM_GNU_GCC_VERSION}/arm-none-eabi"
    "/usr/local/Cellar/arm-none-eabi-gcc/4.8-2013-q4-major/bin/../lib/gcc/arm-none-eabi/${_ARM_GNU_GCC_VERSION}/../../../../arm-none-eabi/include/c++/${_ARM_GNU_GCC_VERSION}/backward"
)

# set link flags
set(CMAKE_C_LINK_FLAGS "")
set(CMAKE_MODULE_LINKER_FLAGS_INIT
    "-fno-exceptions -fno-unwind-tables -nostdlib -nodefaultlibs -mcpu=cortex-m3 -mthumb -Wl,-gc-sections"
)

set(CMAKE_EXE_LINKER_FLAGS_INIT
    "${CMAKE_MODULE_LINKER_FLAGS_INIT} -T${CMAKE_CURRENT_LIST_DIR}/../ld/efm32gg.ld"
) 

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

