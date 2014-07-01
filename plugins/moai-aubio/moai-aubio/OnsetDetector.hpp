#ifndef MOAI_AUBIO_ONSET_DETECTOR_HPP
#define MOAI_AUBIO_ONSET_DETECTOR_HPP

#include <moai-core/MOAILua.h>
#include <aubio.h>
#include <string>
#include "ChunkProcessor.hpp"
#include "Source.hpp"

class OnsetDetector
	:public virtual ChunkProcessor<float>
	,public virtual Source<float>
{
public:
	DECL_LUA_FACTORY(OnsetDetector);

	OnsetDetector();
	virtual ~OnsetDetector();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onChunk(const float* data);
	void onEnd();

private:
	static int _setMethod(lua_State* L);
	static int _setSampleRate(lua_State* L);

	std::string mMethod;
	uint_t mSampRate;
	aubio_onset_t* mOnset;
};

#endif
