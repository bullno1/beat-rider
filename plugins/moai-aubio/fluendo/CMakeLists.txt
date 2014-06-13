cmake_minimum_required(VERSION 2.8)

project(fluendo)

#if( BUILD_ANDROID )
	#if( ANDROID_ABI STREQUAL "armeabi-v7a" )
		#set(USE_ARM_VFP 1)
	#endif()
#endif()

add_definitions(-DHAVE_CONFIG_H)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/config.h.in" "${CMAKE_CURRENT_BINARY_DIR}/config.h")

if(MSVC)
	add_compile_options(/W4)
elseif(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
	add_compile_options(-fno-aggressive-loop-optimizations -Wimplicit-function-declaration -Werror)
endif()

set(FLUENDO_SRC
	src/bitstream.c
	src/common.c
	src/decode.c
	src/gst-stub.c
	src/mp3-c.c
	src/mp3-c-synth.c
	src/mp3tl.c
)
include_directories(${CMAKE_CURRENT_BINARY_DIR})
add_library(fluendo STATIC ${FLUENDO_SRC})
target_include_directories(fluendo PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/src")
