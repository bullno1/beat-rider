cmake_minimum_required(VERSION 2.8.8)

project(mpg123 C ASM)

include(CheckCSourceCompiles)
include(CheckFunctionExists)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckTypeSize)
include(CheckSymbolExists)

if(BUILD_LINUX OR BUILD_WINDOWS OR BUILD_OSX)
	set(ABI_ALIGN_FUN 1)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
	set(ABI_ALIGN_FUN 0)
elseif(ANDROID_ABI STREQUAL "armeabi")
	set(ABI_ALIGN_FUN 0)
else()
	message(FALTAL_ERROR "Unsupported platform")
endif()

set(ACCURATE_ROUNDING 1)
set(DYNAMIC_BUILD "")

if(DEFINED CMAKE_ASM_COMPILER)
	message(STATUS ${CMAKE_ASM_COMPILER})
	if(BUILD_ANDROID)
		set(ASM_COMPILER ${CMAKE_ASM_COMPILER} -c)
	else()
		set(ASM_COMPILER ${CMAKE_ASM_COMPILER})
	endif()
else()
	enable_language(ASM-ATT)
	set(ASM_COMPILER ${CMAKE_ASM-ATT_COMPILER})
endif()

macro(check_asm_compiles source var)
	file(WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.S" "${source}\n")
	if("${VAR}" MATCHES "^${VAR}$")
		message(STATUS "Performing Test ${var}")
		execute_process(
			COMMAND ${ASM_COMPILER} "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.S"
			ERROR_VARIABLE ERROR
			RESULT_VARIABLE ${var}
		)
		if(${var} STREQUAL 0)
			message(STATUS "Performing Test ${var} - Success")
			set(${var} 1 CACHE INTERNAL "Test ${var}")
			file(APPEND "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log"
				"Performing S SOURCE FILE Test ${VAR} succeeded with the following output:\n"
				"${ERROR}\n"
				"Source file was:\n${source}\n")
		else()
			message(STATUS "Performing Test ${var} - Failed")
			set(${var} "" CACHE INTERNAL "Test ${var}")
			file(APPEND "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log"
				"Performing S SOURCE FILE Test ${var} failed with the following output:\n"
				"${ERROR}\n"
				"Source file was:\n${source}\n")
		endif()
	endif()
endmacro()
check_asm_compiles(".balign 4" ASMALIGN_BALIGN)
check_asm_compiles(".balign 3" ASMALIGN_EXP)
if(ASMALIGN_EXP STREQUAL "")
	set(ASMALIGN_BYTE 1 CACHE INTERNAL "Test ASMALIGN_BYTE")
else()
	set(ASMALIGN_BYTE "" CACHE INTERNAL "Test ASMALIGN_BYTE")
endif()

check_c_source_compiles("__attribute__((aligned(16))) float var;int main(){}" CCALIGN)
check_include_files(inttypes.h HAVE_INTTYPES_H)
check_include_files(limit.h HAVE_LIMITS_H)
check_include_files(memory.h HAVE_MEMORY_H)
check_include_files(signal.h HAVE_SIGNAL_H)
check_include_files(sys/signal.h HAVE_SIGNAL_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(stdio.h HAVE_STDIO_H)
check_include_files(stdlib.h HAVE_STDLIB_H)
check_include_files(sys/types.h HAVE_SYS_TYPE_H)
check_include_files(strings.h HAVE_STRINGS_H)
check_include_files(string.h HAVE_STRING_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_type_size(off_t SIZEOF_OFF_T)
math(EXPR LFS_ALIAS_BITS "${SIZEOF_OFF_T} * 8")
check_type_size(int32_t SIZEOF_INT32_T)
check_type_size(long SIZEOF_LONG)
check_type_size(size_t SIZEOF_SIZE_T)
check_type_size(ssize_t SIZEOF_SSIZE_T)
check_symbol_exists(EOVERFLOW errno.h HAVE_EOVERFLOW)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/config.h.in" "${CMAKE_CURRENT_BINARY_DIR}/config.h")

if(HAVE_STDLIB_H)
	set(INCLUDE_STDLIB_H "#include <stdlib.h>")
endif()
if(HAVE_SYS_TYPE_H)
	set(INCLUDE_SYS_TYPE_H "#include <sys/types.h>")
endif()
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/mpg123.h.in" "${CMAKE_CURRENT_BINARY_DIR}/include/mpg123.h")

set(MPG123_SRC
	src/compat.c
	src/parse.c
	src/frame.c
	src/format.c
	src/dct64.c
	src/equalizer.c
	src/id3.c
	src/icy.c
	src/icy2utf8.c
	src/optimize.c
	src/readers.c
	src/tabinit.c
	src/libmpg123.c
	src/index.c
	src/layer1.c
	src/layer2.c
	src/layer3.c
	src/feature.c
	src/synth.c
	src/ntom.c
	src/synth_8bit.c
	src/stringbuf.c
)
set(S_DITHER
	src/dither.c
)
set(S_FPU
	src/synth_s32.c
	src/synth_real.c
)
set(S_ARM
	src/synth_arm_accurate.S
)
set(S_NEON
	src/dct36_neon.S
	src/dct64_neon_float.S
	src/synth_neon_float.S
	src/synth_neon_s32.S
	src/synth_stereo_neon_float.S
	src/synth_stereo_neon_s32.S
	src/synth_neon_accurate.S
	src/synth_stereo_neon_accurate.S
)
set(S_ARM_MULTI
	src/getcpuflags_arm.c
	src/check_neon.S
)
if(BUILD_LINUX OR BUILD_WINDOWS OR BUILD_OSX)
	add_definitions(-DOPT_GENERIC -DREAL_IS_FLOAT)
	set(MPG123_SRC "${MPG123_SRC}" ${S_FPU})
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
	add_definitions(-DOPT_MULTI -DOPT_GENERIC -DOPT_GENERIC_DITHER -DOPT_NEON -DREAL_IS_FLOAT)
	set(MPG123_SRC "${MPG123_SRC}" ${S_FPU} ${S_DITHER} ${S_NEON} ${S_ARM_MULTI})
elseif(ANDROID_ABI STREQUAL "armeabi")
	message(FALTAL_ERROR "Not supported")
endif()
add_definitions(-DHAVE_CONFIG_H)

include_directories("${CMAKE_CURRENT_BINARY_DIR}/include" "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/src")
add_library(mpg123 STATIC ${MPG123_SRC})
target_include_directories(mpg123 PUBLIC "${CMAKE_CURRENT_BINARY_DIR}/include")
