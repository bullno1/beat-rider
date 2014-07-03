cmake_minimum_required ( VERSION 2.8.5 )
project(moai-aubio)

add_library(moai-aubio STATIC
    host.cpp
	PcmSource.cpp
	TempoDetector.cpp
	OnsetDetector.cpp
	PhaseVocoder.cpp
	SpecDesc.cpp
	BufferSink.cpp
	CenteredMovingAvg.cpp
	DoubleExp.cpp
	Mp3Decoder.cpp
	UntzSoundEx.cpp
)
target_include_directories(moai-aubio PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../)
target_link_libraries(moai-aubio aubio mpg123 moai-core moai-util moai-sim zlcore untz)
