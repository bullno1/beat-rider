#include <moai-core/headers.h>
#include <functional>
#include <algorithm>
#include "TempoDetector.hpp"
#include "AubioUtils.hpp"

TempoDetector::TempoDetector()
	:mMethod("default")
	,mSampRate(44100)
	,mTempo(NULL)
{
	RTTI_BEGIN
		RTTI_EXTEND(ChunkProcessor<float>);
	RTTI_END
}

TempoDetector::~TempoDetector()
{
	mBpmStream.Set(*this, 0);
	mBeatStream.Set(*this, 0);

	if(mTempo)
	{
		del_aubio_tempo(mTempo);
		mTempo = NULL;
	}
}

void TempoDetector::onBegin()
{
	affirmSubstreams();

	ChunkProcessor::onBegin();

	mBpmStream->beginStream();
	mBeatStream->beginStream();

	mTempo = new_aubio_tempo(const_cast<char*>(mMethod.c_str()), getChunkSize() * 2, getChunkSize(), mSampRate);
}

void TempoDetector::onChunk(const float* data)
{
	ALLOC_AUBIO_FVEC(dataVec, data, getChunkSize());
	ALLOC_AUBIO_TEMP_VEC(outVec, 2);
	aubio_tempo_do(mTempo, dataVec, outVec);

	if(fvec_get_sample(outVec, 0))
	{
		smpl_t lastBeat = aubio_tempo_get_last_s(mTempo);
		mBeatStream->pushData(&lastBeat, 1);
	}

	smpl_t bpm = aubio_tempo_get_bpm(mTempo);
	mBpmStream->pushData(&bpm, 1);
}

void TempoDetector::onEnd()
{
	del_aubio_tempo(mTempo);
	mTempo = NULL;

	mBeatStream->endStream();
	mBpmStream->endStream();

	ChunkProcessor::onEnd();
}

void TempoDetector::RegisterLuaFuncs(MOAILuaState& state)
{
	ChunkProcessor<float>::RegisterLuaFuncs(state);

	luaL_Reg regTable[] = {
		{ "setMethod", _setMethod },
		{ "setSampleRate", _setSampleRate },
		{ "getBpmStream", _getBpmStream },
		{ "getBeatStream", _getBeatStream },
		{ NULL, NULL }
	};

	luaL_register(state, 0, regTable);
}

void TempoDetector::affirmSubstreams()
{
	if(!mBpmStream)
	{
		mBpmStream.Set(*this, new Substream<float>);
		mBeatStream.Set(*this, new Substream<float>);
	}
}

int TempoDetector::_setMethod(lua_State* L)
{
	MOAI_LUA_SETUP(TempoDetector, "US");

	self->mMethod = state.GetValue(2, "default");
	return 0;
}

int TempoDetector::_setSampleRate(lua_State* L)
{
	MOAI_LUA_SETUP(TempoDetector, "UN");

	self->mSampRate = state.GetValue(2, 0);
	return 0;
}

int TempoDetector::_getBpmStream(lua_State* L)
{
	MOAI_LUA_SETUP(TempoDetector, "U");

	self->affirmSubstreams();
	self->mBpmStream->PushLuaUserdata(state);
	return 1;
}

int TempoDetector::_getBeatStream(lua_State* L)
{
	MOAI_LUA_SETUP(TempoDetector, "U");

	self->affirmSubstreams();
	self->mBeatStream->PushLuaUserdata(state);
	return 1;
}
