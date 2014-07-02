#ifndef MOAI_AUBIO_PHASE_VOCODER_HPP
#define MOAI_AUBIO_PHASE_VOCODER_HPP

#include <moai-core/MOAILua.h>
#include <aubio.h>
#include <string>
#include "ChunkProcessor.hpp"
#include "Source.hpp"

class PhaseVocoder
	:public ChunkProcessor<float>
	,public Source<cvec_t>
{
public:
	DECL_LUA_FACTORY(PhaseVocoder);

	PhaseVocoder();
	virtual ~PhaseVocoder();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onChunk(const float* data);
	void onEnd();

private:
	aubio_pvoc_t* mPvoc;
	cvec_t* mFftBuff;
};

#endif
