#include <moai-core/headers.h>
#include "UntzSoundEx.hpp"
#include "Mp3Decoder.hpp"

UntzSoundEx::UntzSoundEx()
	:mStream(NULL)
	,mSound(NULL)
{
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject);
	RTTI_END
}

UntzSoundEx::~UntzSoundEx()
{
	if(mSound)
	{
		UNTZ::Sound::dispose(mSound);
		mSound = NULL;
	}

	if(mStream)
	{
		mStream->close();
		mStream = NULL;
	}
}

void UntzSoundEx::RegisterLuaClass(MOAILuaState& state)
{
	state.SetField(-1, "STATUS_MORE", MORE);
	state.SetField(-1, "STATUS_DONE", DONE);
	state.SetField(-1, "STATUS_ERROR", ERROR);
}

void UntzSoundEx::RegisterLuaFuncs(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ "open", _open },
		{ "loadChunk", _loadChunk },
		{ "play", _play },
		{ "pause", _pause },
		{ "getPosition", _getPosition },
		{ "getInfo", _getInfo },
		{ NULL, NULL }
	};

	luaL_register(state, 0, regTable);
}

int UntzSoundEx::_open(lua_State* L)
{
	MOAI_LUA_SETUP(UntzSoundEx, "US");

	STLString filename = state.GetValue(2, "");
	if(!MOAILogMessages::CheckFileExists(filename, L))
	{
		state.Push(false);
		return 1;
	}

	AudioStream* stream = createMp3Stream(filename);
	if(stream == NULL)
	{
		state.Push(false);
		return 1;
	}

	if(self->mSound)
	{
		UNTZ::Sound::dispose(self->mSound);
		self->mSound = NULL;
	}

	if(self->mStream)
	{
		self->mStream->close();
	}

	self->mStream = stream;
	self->mSoundData.clear();
	self->mSoundInfo.mSampleRate = stream->getSampleRate();
	self->mSoundInfo.mLength = stream->getLength();
	self->mSoundInfo.mChannels = stream->getNumChannels();
	self->mSoundInfo.mBitsPerSample = 32;

	state.Push(true);
	return 1;
}

int UntzSoundEx::_loadChunk(lua_State* L)
{
	MOAI_LUA_SETUP(UntzSoundEx, "UN");

	if(self->mStream)
	{
		size_t numChannels = self->mSoundInfo.mChannels;
		size_t numFrames = state.GetValue(2, 2048);
		size_t numFramesRead = 0;
		std::vector<float>& mTempBuff = self->mTempBuff;
		std::vector<float>& mSoundData = self->mSoundData;
		AudioStream* mStream = self->mStream;

		self->mTempBuff.resize(numFrames * numChannels, 0.0f);
		AudioStream::Status status = self->mStream->read(mTempBuff.data(), numFrames, numFramesRead);
		mSoundData.insert(mSoundData.end(), &mTempBuff[0], &mTempBuff[numFramesRead * numChannels]);

		switch(status)
		{
		case AudioStream::OK:
			state.Push(MORE);
			state.Push(mStream->getPosition() / mStream->getLength());
			return 2;
		case AudioStream::EOS:
			self->mStream->close();
			self->mStream = NULL;
			self->mSoundInfo.mTotalFrames = mSoundData.size() / numChannels;
			self->mSound = UNTZ::Sound::create(self->mSoundInfo, mSoundData.data(), false);
			state.Push(DONE);
			return 1;
		case AudioStream::ERROR:
			state.Push(ERROR);
			return 1;
		}
	}
	else
	{
		return 0;
	}
}

int UntzSoundEx::_play(lua_State* L)
{
	MOAI_LUA_SETUP(UntzSoundEx, "U");

	if(self->mSound) { self->mSound->play(); }

	return 0;
}

int UntzSoundEx::_pause(lua_State* L)
{
	MOAI_LUA_SETUP(UntzSoundEx, "U");

	if(self->mSound) { self->mSound->pause(); }

	return 0;
}

int UntzSoundEx::_getInfo(lua_State* L)
{
	MOAI_LUA_SETUP(UntzSoundEx, "U");

	if(self->mSound)
	{
		const UNTZ::SoundInfo& soundInfo = self->mSoundInfo;
		state.Push(soundInfo.mSampleRate);
		state.Push(soundInfo.mChannels);
		state.Push(soundInfo.mTotalFrames);
		state.Push(soundInfo.mLength);
		return 4;
	}
	else
	{
		return 0;
	}
}

int UntzSoundEx::_getPosition(lua_State* L)
{
	MOAI_LUA_SETUP(UntzSoundEx, "U");

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
