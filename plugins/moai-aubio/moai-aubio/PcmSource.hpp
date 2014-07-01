#ifndef MOAI_AUBIO_PCM_SOURCE_HPP
#define MOAI_AUBIO_PCM_SOURCE_HPP

#include <moai-core/MOAILua.h>
#include "Root.hpp"
#include "Decoder.hpp"
#include <vector>

class PcmSource: public Root<float>
{
public:
	DECL_LUA_FACTORY(PcmSource);

	PcmSource();
	virtual ~PcmSource();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	size_t pull(float* buff, size_t size);

private:
	static int _open(lua_State* L);
	static int _getProgress(lua_State* L);
	static int _getSampleRate(lua_State* L);

	AudioStream* mStream;
	bool mEos;
	std::vector<float> mTempBuff;
};

#endif
