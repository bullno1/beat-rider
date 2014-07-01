#ifndef MOAI_AUBIO_TEMPO_DETECTOR_HPP
#define MOAI_AUBIO_TEMPO_DETECTOR_HPP

#include <moai-core/MOAILua.h>
#include "Substream.hpp"
#include "ChunkProcessor.hpp"
#include <aubio.h>

class TempoDetector: public virtual ChunkProcessor<float>
{
public:
	DECL_LUA_FACTORY(TempoDetector);

	TempoDetector();
	virtual ~TempoDetector();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onChunk(const float* data);
	void onEnd();

private:
	void affirmSubstreams();

	static int _setMethod(lua_State* L);
	static int _setSampleRate(lua_State* L);
	static int _getBpmStream(lua_State* L);
	static int _getBeatStream(lua_State* L);

	std::string mMethod;
	uint_t mSampRate;
	MOAILuaSharedPtr< Substream<float> > mBpmStream;
	MOAILuaSharedPtr< Substream<float> > mBeatStream;
	aubio_tempo_t* mTempo;
};

#endif
