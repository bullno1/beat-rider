#include <moai-core/headers.h>
#include "MOAIUntzSoundPlus.hpp"
#include "Mp3Decoder.hpp"

MOAIUntzSoundPlus::MOAIUntzSoundPlus()
	:mSound(NULL)
	,mAudioStream(NULL)
	,mLength(0.0)
	,mEos(true)
{
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject);
	RTTI_END
}

MOAIUntzSoundPlus::~MOAIUntzSoundPlus()
{
	if(mSound)
	{
		UNTZ::Sound::dispose(mSound);
		mSound = NULL;
	}

	if(mAudioStream)
	{
		mAudioStream->close();
		mAudioStream = NULL;
	}
}

void MOAIUntzSoundPlus::RegisterLuaFuncs(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ "load", _load },
		{ "play", _play },
		{ "pause", _pause },
		{ "getLength", _getLength },
		{ "getPosition", _getPosition },
		{ NULL, NULL }
	};

	luaL_register(state, 0, regTable);
}

int MOAIUntzSoundPlus::_load(lua_State* L)
{
	MOAI_LUA_SETUP(MOAIUntzSoundPlus, "US");

	STLString path = state.GetValue(2, "");
	if(!MOAILogMessages::CheckFileExists(path, L))
	{
		state.Push(false);
		return 1;
	}

	UNTZ::Sound* sound = UNTZ::Sound::create(path, false);
	AudioStream* mp3Stream = NULL;
	if(sound == NULL)//built-in decoders failed
	{
		mp3Stream = createMp3Stream(path);

		if(mp3Stream == NULL)//mpg123 failed too
		{
			state.Push(false);
			return 1;
		}

		sound = UNTZ::Sound::create(mp3Stream->getSampleRate(), mp3Stream->getNumChannels(), streamCallback, self);
		self->mLength = mp3Stream->getLength();
		self->mEos = false;
	}

	if(self->mSound)
	{
		UNTZ::Sound::dispose(self->mSound);
	}

	self->mSound = sound;

	if(self->mAudioStream)
	{
		self->mAudioStream->close();
	}

	self->mAudioStream = mp3Stream;

	state.Push(true);
	return 1;
}

int MOAIUntzSoundPlus::_play(lua_State* L)
{
	MOAI_LUA_SETUP(MOAIUntzSoundPlus, "U");

	if(self->mSound) { self->mSound->play(); }

	return 0;
}

int MOAIUntzSoundPlus::_pause(lua_State* L)
{
	MOAI_LUA_SETUP(MOAIUntzSoundPlus, "U");

	if(self->mSound) { self->mSound->pause(); }

	return 0;
}

int MOAIUntzSoundPlus::_getLength(lua_State* L)
{
	MOAI_LUA_SETUP(MOAIUntzSoundPlus, "U");

	if(self->mSound)
	{
		state.Push(self->mAudioStream != NULL ? self->mLength : self->mSound->getInfo().mLength);
	}
	else
	{
		state.Push();
	}

	return 1;
}

int MOAIUntzSoundPlus::_getPosition(lua_State* L)
{
	MOAI_LUA_SETUP(MOAIUntzSoundPlus, "U");

	if(self->mSound)
	{
		state.Push(self->mSound->getPosition());
	}
	else
	{
		state.Push();
	}

	return 1;
}

Int64 MOAIUntzSoundPlus::streamCallback(float* buffers,	UInt32 numChannels,	UInt32 numFrames, void* userdata)
{
	MOAIUntzSoundPlus* self = static_cast<MOAIUntzSoundPlus*>(userdata);
	std::vector<float>& mTempBuff = self->mTempBuff;
	mTempBuff.resize(numFrames * numChannels);
	if(self->mEos) { return 0; }

	size_t numSamplesRead;

	AudioStream::Status status = self->mAudioStream->read(mTempBuff.data(), numFrames, numSamplesRead);
	for(int i = 0; i < numSamplesRead * numChannels; ++i)
	{
		int channel = i % numChannels;
		buffers[numSamplesRead * channel + i / numChannels] = mTempBuff[i];
	}

	switch(status)
	{
	case AudioStream::OK:
		return numSamplesRead;
	case AudioStream::EOS:
		self->mEos = true;
		return numSamplesRead;
	case AudioStream::ERROR:
		return -1;
	}
}
