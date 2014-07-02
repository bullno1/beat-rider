#ifndef MOAI_AUBIO_DOUBLE_EXP_HPP
#define MOAI_AUBIO_DOUBLE_EXP_HPP

#include <moai-core/MOAILua.h>
#include <vector>
#include "Sink.hpp"
#include "Source.hpp"

class DoubleExp
	:public Source<float>
	,public Sink<float>
{
public:
	DECL_LUA_FACTORY(DoubleExp);

   	DoubleExp();
	virtual ~DoubleExp();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onData(const float* data, size_t size);
	void onEnd();

private:
	static int _setSmoothingFactors(lua_State* L);

	float mDataSmoothingFactor;
	float mTrendSmoothingFactor;
	float mLastSmooth;
	float mLastTrend;
	std::vector<float> mChunkBuff;
};

#endif
