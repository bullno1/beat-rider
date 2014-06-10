cmake_minimum_required ( VERSION 2.8.5 )
project(moai-aubio)

add_library(moai-aubio STATIC
    host.cpp
)
target_include_directories(moai-aubio PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../)
target_link_libraries(moai-aubio aubio moai-core moai-util moai-sim zlcore)
