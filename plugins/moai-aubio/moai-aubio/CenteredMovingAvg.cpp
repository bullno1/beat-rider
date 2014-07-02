#include <moai-core/headers.h>
#include "CenteredMovingAvg.hpp"
#include <algorithm>

CenteredMovingAvg::CenteredMovingAvg()
	:mTotal(0.0f)
	,mRadius(2)
	,mCursor(0)
	,mEnoughData(false)
{
	RTTI_BEGIN
		RTTI_EXTEND(Sink<float>);
		RTTI_EXTEND(Source<float>);
	RTTI_END
}

CenteredMovingAvg::~CenteredMovingAvg()
{
}

void CenteredMovingAvg::RegisterLuaFuncs(MOAILuaState& state)
{
	Source<float>::RegisterLuaFuncs(state);

	luaL_reg regTable[] = {
		{ "setWindowRadius", _setWindowRadius },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

void CenteredMovingAvg::onBegin()
{
	Source<float>::beginStream();

	mRingBuff.resize(mRadius * 2 + 1, 0.0f);
	mCursor = 0;
	mEnoughData = false;
	mTotal = 0.0f;
}

void CenteredMovingAvg::onData(const float* data, size_t size)
{
	mChunkBuff.clear();

	for(size_t i = 0; i < size; ++i)
	{
		float newVal = data[i];
		float evictedVal = mRingBuff[mCursor];
		mRingBuff[mCursor] = newVal;
		mCursor = (mCursor + 1) % (mRadius * 2 + 1);
		mTotal = mTotal - evictedVal + newVal;

		if(mEnoughData)
		{
			mChunkBuff.push_back(mTotal / (float)(mRadius * 2 + 1));
		}
		else
		{
			if(mCursor == mRadius)
			{
				mEnoughData = true;
			}
		}
	}

	Source<float>::pushData(mChunkBuff.data(), mChunkBuff.size());
}

void CenteredMovingAvg::onEnd()
{
	//Zero-pad the end
	float zeros[512];
	std::fill(zeros, zeros + 512, 0.0f);

	size_t radius = mRadius;
	while(radius > 0)
	{
		size_t numFill = std::min<size_t>(radius, 512);
		onData(zeros, numFill);
		radius -= numFill;
	}

	Source<float>::endStream();
}

int CenteredMovingAvg::_setWindowRadius(lua_State* L)
{
	MOAI_LUA_SETUP(CenteredMovingAvg, "UN");

	self->mRadius = state.GetValue(2, 2);
	return 0;
}
