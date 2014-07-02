#include <moai-core/headers.h>
#include "DoubleExp.hpp"

DoubleExp::DoubleExp()
	:mDataSmoothingFactor(0.5f)
	,mTrendSmoothingFactor(0.5f)
	,mLastSmooth(0.0f)
	,mLastTrend(0.0f)
{
	RTTI_BEGIN
		RTTI_EXTEND(Sink<float>);
		RTTI_EXTEND(Source<float>);
	RTTI_END
}

DoubleExp::~DoubleExp()
{}

void DoubleExp::RegisterLuaFuncs(MOAILuaState& state)
{
	Source<float>::RegisterLuaFuncs(state);

	luaL_reg regTable[] = {
		{ "setSmoothingFactors", _setSmoothingFactors },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

void DoubleExp::onBegin()
{
	Source<float>::beginStream();
}

void DoubleExp::onData(const float* data, size_t size)
{
	mChunkBuff.clear();

	for(size_t i = 0; i < size; ++i)
	{
		float smooth = mDataSmoothingFactor * data[i] + (1 - mDataSmoothingFactor) * (mLastSmooth + mLastTrend);
		float trend = mTrendSmoothingFactor * (smooth - mLastSmooth) + (1 - mTrendSmoothingFactor) * mLastTrend;

		mChunkBuff.push_back(smooth);
		mLastSmooth = smooth;
		mLastTrend = trend;
	}

	Source<float>::pushData(mChunkBuff.data(), mChunkBuff.size());
}

void DoubleExp::onEnd()
{
	Source<float>::endStream();
}

int DoubleExp::_setSmoothingFactors(lua_State* L)
{
	MOAI_LUA_SETUP(DoubleExp, "UNN");

	self->mDataSmoothingFactor = state.GetValue(2, 0.5);
	self->mTrendSmoothingFactor = state.GetValue(2, 0.5);
	return 0;
}
