#include <moai-core/headers.h>
#include "OnsetDetector.hpp"
#include "AubioUtils.hpp"

OnsetDetector::OnsetDetector()
	:mMethod("hfc")
	,mSampRate(44100)
	,mOnset(NULL)
{
	RTTI_BEGIN
		RTTI_EXTEND(ChunkProcessor<float>);
		RTTI_EXTEND(Source<float>);
	RTTI_END
}

OnsetDetector::~OnsetDetector()
{
	if(mOnset)
	{
		del_aubio_onset(mOnset);
		mOnset = NULL;
	}
}

void OnsetDetector::onBegin()
{
	ChunkProcessor::onBegin();
	Source<float>::beginStream();

	mOnset = new_aubio_onset(const_cast<char*>(mMethod.c_str()), getChunkSize() * 2, getChunkSize(), mSampRate);
}

void OnsetDetector::onChunk(const float* data)
{
	ALLOC_AUBIO_FVEC(dataVec, data, getChunkSize());
	ALLOC_AUBIO_TEMP_VEC(outVec, 2);
	aubio_onset_do(mOnset, dataVec, outVec);

	if(fvec_get_sample(outVec, 0))
	{
		smpl_t lastOnset = aubio_onset_get_last_s(mOnset);
		Source<float>::pushData(&lastOnset, 1);
	}
}

void OnsetDetector::onEnd()
{
	del_aubio_onset(mOnset);
	mOnset = NULL;

	Source<float>::endStream();
	ChunkProcessor::onEnd();
}

int OnsetDetector::_setMethod(lua_State* L)
{
	MOAI_LUA_SETUP(OnsetDetector, "US");

	self->mMethod = state.GetValue(2, "default");
	return 0;
}

int OnsetDetector::_setSampleRate(lua_State* L)
{
	MOAI_LUA_SETUP(OnsetDetector, "UN");

	self->mSampRate = state.GetValue(2, 0);
	return 0;
}

void OnsetDetector::RegisterLuaFuncs(MOAILuaState& state)
{
	ChunkProcessor<float>::RegisterLuaFuncs(state);
	Source<float>::RegisterLuaFuncs(state);

	luaL_Reg regTable[] = {
		{ "setMethod", _setMethod },
		{ "setSampleRate", _setSampleRate },
		{ NULL, NULL }
	};

	luaL_register(state, 0, regTable);
}
