#ifndef MOAI_AUBIO_DIFFERENCE_HPP
#define MOAI_AUBIO_DIFFERENCE_HPP

#include <moai-core/MOAILua.h>
#include "Sink.hpp"
#include "Source.hpp"
#include <vector>

class Difference
	:public Sink<float>
	,public Source<float>
{
public:
	DECL_LUA_FACTORY(Difference);

	Difference();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onData(const float* data, size_t size);
	void onEnd();

private:
	float mLast;
	bool mFirst;
	std::vector<float> mBuff;
};

#endif
