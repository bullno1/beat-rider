cmake_minimum_required(VERSION 2.8)

project(aubio)

include(CheckIncludeFiles)
include(CheckCSourceCompiles)
check_include_files(stdlib.h HAVE_STDLIB_H)
check_include_files(stdio.h HAVE_STDIO_H)
check_include_files(math.h HAVE_MATH_H)
check_include_files(string.h HAVE_STRING_H)
check_include_files(limits.h HAVE_LIMITS_H)

set(VARARG_TEST_SRC
"#include <stdio.h>
 #define AUBIO_ERR(...) fprintf(stderr, __VA_ARGS__)
 int main(){}"
)
set(C99_C_FLAG_CANDIDATES
	" "
	"-std=c99"
	"-std=gnu99"
	"-c99"
	"-AC99"
	"-xc99=all"
	"-qlanglvl=extc99"
)
set(SAFE_CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS}")
foreach(FLAG ${C99_C_FLAG_CANDIDATES})
	set(CMAKE_REQUIRED_FLAGS "${FLAG}")
	unset(HAVE_C99_VARARGS_MACROS CACHE)
	message(STATUS "Try C99 C flag = [${FLAG}]")
	check_c_source_compiles(${VARARG_TEST_SRC} HAVE_C99_VARARGS_MACROS)
	if(HAVE_C99_VARARGS_MACROS)
		message(STATUS ${C99_C_FLAGS_INTERNAL})
		set(C99_C_FLAGS_INTERNAL "${FLAG}")
		break()
	endif(HAVE_C99_VARARGS_MACROS)
endforeach(FLAG ${C99_C_FLAG_CANDIDATES})
set(CMAKE_REQUIRED_FLAGS "${SAFE_CMAKE_REQUIRED_FLAGS} ${C99_C_FLAGS_INTERNAL}")

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/config.h.in" "${CMAKE_CURRENT_BINARY_DIR}/config.h")

file(GLOB_RECURSE AUBIO_SRC "src/*.c")
include_directories(${CMAKE_CURRENT_BINARY_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/src")
add_library(aubio STATIC ${AUBIO_SRC})
target_include_directories(aubio PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/src")
