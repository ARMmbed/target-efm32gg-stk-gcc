# Copyright (C) 2014 ARM Limited. All rights reserved. 

# search path for included .cmake files (set this as early as possible, so that
# indirect includes still use it)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(CMakeForceCompiler)

set(CMAKE_SYSTEM_NAME mbedOS)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "armv7-m")

# !!! FIXME: this line should be removed: TARGET_LIKE_XXX definitions are now
# provided by the yotta-generated CMakeLists
# (this line currently provides definitions that some ported components like
#  need to configure themselves)
set(YOTTA_TARGET_DEFINITIONS "-DSTK3700 -DEFM32GG990F1024 -DEFM32GG -DEFM32")


# Set the compiler to ARM-GCC
include(CMakeForceCompiler)

cmake_force_c_compiler(arm-none-eabi-gcc GNU)
cmake_force_cxx_compiler(arm-none-eabi-g++ GNU)

