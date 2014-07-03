#include <moai-core/headers.h>
#include "PcmSource.hpp"
#include "Mp3Decoder.hpp"

PcmSource::PcmSource()
	:mStream(NULL)
	,mEos(true)
{
	RTTI_BEGIN
		RTTI_EXTEND(Root<float>);
	RTTI_END
}

PcmSource::~PcmSource()
{
	if(mStream)
	{
		mStream->close();
		mStream = NULL;
	}
}

void PcmSource::RegisterLuaFuncs(MOAILuaState& state)
{
	Root<float>::RegisterLuaFuncs(state);

	luaL_reg regTable[] = {
		{ "open", _open },
		{ "getProgress", _getProgress },
		{ "getInfo", _getInfo },
		{ NULL, NULL }
	};

	luaL_register(state, 0, regTable);
}

size_t PcmSource::pull(float* outBuff, size_t size)
{
	if(mStream == NULL || mEos) return 0;

	unsigned int numChannels = mStream->getNumChannels();
	mTempBuff.resize(size * numChannels);
	size_t numFramesRead = 0;
	AudioStream::Status status = mStream->read(mTempBuff.data(), size, numFramesRead);

	switch(status)
	{
		case AudioStream::OK:
			break;
		case AudioStream::EOS:
			mEos = true;
			break;
		case AudioStream::ERROR:
			return 0;
	}

	//Mix all channels into one
	size_t numSamplesRead = numFramesRead * numChannels;
	for(size_t frameIndex = 0; frameIndex < numFramesRead; ++frameIndex)
	{
		float sum = 0.0f;
		for(unsigned int channelIndex = 0; channelIndex < numChannels; ++channelIndex)
		{
			sum += mTempBuff[frameIndex * numChannels + channelIndex];
		}
		outBuff[frameIndex] = sum / (float)numChannels;
	}

	return numFramesRead;
}

int PcmSource::_open(lua_State* L)
{
	MOAI_LUA_SETUP(PcmSource, "US");

	if(self->mStream != NULL)
	{
		ZLLog::Print("Stream is already opened\n");
		return false;
	}

	STLString path = state.GetValue(2, "");
	if(!MOAILogMessages::CheckFileExists(path, L))
	{
		state.Push(false);
		return 1;
	}

	AudioStream* stream = createMp3Stream(path);
	if(stream == NULL)
	{
		state.Push(false);
		return 1;
	}

	self->mStream = stream;
	self->mEos = false;

	state.Push(true);
	return 1;
}

int PcmSource::_getProgress(lua_State* L)
{
	MOAI_LUA_SETUP(PcmSource, "U");

	if(self->mStream)
	{
		state.Push(self->mStream->getPosition() / self->mStream->getLength());
		return 1;
	}
	else
	{
		state.Push();
		return 1;
	}
}

int PcmSource::_getInfo(lua_State* L)
{
	MOAI_LUA_SETUP(PcmSource, "U");

	if(self->mStream)
	{
		state.Push(self->mStream->getSampleRate());
		state.Push(self->mStream->getNumChannels());
		state.Push(self->mStream->getLength());
		return 3;
	}
	else
	{
		state.Push();
		return 1;
	}
}
