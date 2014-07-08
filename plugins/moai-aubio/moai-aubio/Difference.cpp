#include <moai-core/headers.h>
#include "Difference.hpp"

Difference::Difference()
	:mLast(0.0f)
	,mFirst(true)
{
	RTTI_BEGIN
		RTTI_EXTEND(Sink<float>);
		RTTI_EXTEND(Source<float>);
	RTTI_END
}

void Difference::onBegin()
{
	Source<float>::beginStream();
	mFirst = true;
}

void Difference::onData(const float* data, size_t size)
{
	mBuff.clear();

	for(size_t index = 0; index < size; ++index)
	{
		if(mFirst)
		{
			mLast = data[index];
			mFirst = false;
		}

		mBuff.push_back(fabs(data[index] - mLast));
		mLast = data[index];
	}

	Source<float>::pushData(mBuff.data(), mBuff.size());
}

void Difference::onEnd()
{
	Source<float>::endStream();
}

void Difference::RegisterLuaFuncs(MOAILuaState& state)
{
	Source<float>::RegisterLuaFuncs(state);
}
