#ifndef MOAI_AUBIO_CENTERED_MOVING_AVG_HPP
#define MOAI_AUBIO_CENTERED_MOVING_AVG_HPP

#include <moai-core/MOAILua.h>
#include <vector>
#include "Sink.hpp"
#include "Source.hpp"

class CenteredMovingAvg
	:public Sink<float>
	,public Source<float>
{
public:
	DECL_LUA_FACTORY(CenteredMovingAvg);

	CenteredMovingAvg();
	virtual ~CenteredMovingAvg();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onData(const float* data, size_t size);
	void onEnd();

	static int _setWindowRadius(lua_State* L);

private:
	float mTotal;
	std::vector<float> mRingBuff;
	std::vector<float> mChunkBuff;
	size_t mRadius;
	size_t mCursor;
	bool mEnoughData;
};

#endif
