#include <moai-core/headers.h>
#include <moai-core/MOAILua.h>
#include <aubio.h>
#include <mpg123.h>
#include <map>
#include <string>
#include "TempoDetector.hpp"
#include "BufferSink.hpp"
#include "MOAIUntzSoundPlus.hpp"
#include "PcmSource.hpp"
#include "OnsetDetector.hpp"

void MOAIAubioAppInitialize()
{
	mpg123_init();

	const char** decoders = mpg123_supported_decoders();
	ZLLog::Print("Supported mp3 decoders:\n");
	for(unsigned int i = 0; decoders[i] != NULL; ++i)
	{
		ZLLog::Print(" * %s\n", decoders[i]);
	}
}

void MOAIAubioContextInitialize()
{
	REGISTER_LUA_CLASS(Source<float>);
	REGISTER_LUA_CLASS(Sink<float>);
	REGISTER_LUA_CLASS(PcmSource);
	REGISTER_LUA_CLASS(MOAIUntzSoundPlus);
	REGISTER_LUA_CLASS(OnsetDetector);
	REGISTER_LUA_CLASS(TempoDetector);
	REGISTER_LUA_CLASS(BufferSink);
}

void MOAIAubioAppFinalize()
{
	mpg123_exit();
	aubio_cleanup();
}
