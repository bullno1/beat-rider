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

void MOAIAubioAppInitialize()
{
	mpg123_init();

	const char** decoders = mpg123_supported_decoders();
	ZLLog::Print("Supported mp3 decoders:\n");
	for(unsigned int i = 0; decoders[i] != NULL; ++i)
	{
		ZLLog::Print(" * %s\n", decoders[i]);
	}

	std::map<mpg123_enc_enum, std::string> encodingNames;
#define MAP_ENC(NAME) encodingNames[NAME] = #NAME;
	MAP_ENC(MPG123_ENC_8);
	MAP_ENC(MPG123_ENC_16);
	MAP_ENC(MPG123_ENC_24);
	MAP_ENC(MPG123_ENC_32);
	MAP_ENC(MPG123_ENC_SIGNED);
	MAP_ENC(MPG123_ENC_FLOAT);
	MAP_ENC(MPG123_ENC_SIGNED_16);
	MAP_ENC(MPG123_ENC_UNSIGNED_16);
	MAP_ENC(MPG123_ENC_UNSIGNED_8);
	MAP_ENC(MPG123_ENC_SIGNED_8);
	MAP_ENC(MPG123_ENC_ULAW_8);
	MAP_ENC(MPG123_ENC_ALAW_8);
	MAP_ENC(MPG123_ENC_SIGNED_32);
	MAP_ENC(MPG123_ENC_UNSIGNED_32);
	MAP_ENC(MPG123_ENC_SIGNED_24);
	MAP_ENC(MPG123_ENC_UNSIGNED_24);
	MAP_ENC(MPG123_ENC_FLOAT_32);
	MAP_ENC(MPG123_ENC_FLOAT_64);
	MAP_ENC(MPG123_ENC_ANY);
#undef MAP_ENC
	const int* encodings = 0;
	size_t numEncodings = 0;
	mpg123_encodings(&encodings, &numEncodings);
	ZLLog::Print("Supported encodings:\n");
	for(size_t i = 0; i < numEncodings; ++i)
	{
		mpg123_enc_enum encoding = (mpg123_enc_enum)encodings[i];
		ZLLog::Print(" * %s\n", encodingNames[encoding].c_str());
	}
}

void MOAIAubioContextInitialize()
{
	REGISTER_LUA_CLASS(Source<float>);
	REGISTER_LUA_CLASS(Sink<float>);
	REGISTER_LUA_CLASS(PcmSource);
	REGISTER_LUA_CLASS(MOAIUntzSoundPlus);
	REGISTER_LUA_CLASS(TempoDetector);
	REGISTER_LUA_CLASS(BufferSink);
}

void MOAIAubioAppFinalize()
{
	mpg123_exit();
	aubio_cleanup();
}
