#ifndef MOAI_UNTZ_SOUND_PLUS_HPP
#define MOAI_UNTZ_SOUND_PLUS_HPP

#include <moai-core/MOAILua.h>
#include <UntzSound.h>
#include <vector>
#include "Decoder.hpp"

class MOAIUntzSoundPlus: public virtual MOAILuaObject
{
public:
	DECL_LUA_FACTORY(MOAIUntzSoundPlus);

	MOAIUntzSoundPlus();
	virtual ~MOAIUntzSoundPlus();

	void RegisterLuaFuncs(MOAILuaState& state);
private:
	static Int64 streamCallback(float* buffers,	UInt32 numChannels,	UInt32 length,void* userdata);
	static int _load(lua_State* L);
	static int _play(lua_State* L);
	static int _pause(lua_State* L);
	static int _getLength(lua_State* L);
	static int _getPosition(lua_State* L);

	UNTZ::Sound* mSound;
	AudioStream* mAudioStream;
	double mLength;
	bool mEos;
	std::vector<float> mTempBuff;
};

#endif
