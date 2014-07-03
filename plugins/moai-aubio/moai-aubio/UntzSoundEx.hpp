#ifndef MOAI_AUBIO_UNTZ_SOUND_EX_HPP
#define MOAI_AUBIO_UNTZ_SOUND_EX_HPP

#include <moai-core/MOAILua.h>
#include <UntzSound.h>
#include <vector>
#include "Decoder.hpp"

class UntzSoundEx: public virtual MOAILuaObject
{
public:
	enum Status
	{
		MORE,
		DONE,
		ERROR
	};

	DECL_LUA_FACTORY(UntzSoundEx);

	UntzSoundEx();
	virtual ~UntzSoundEx();

	void RegisterLuaClass(MOAILuaState& state);
	void RegisterLuaFuncs(MOAILuaState& state);

private:
	static int _open(lua_State* L);
	static int _loadChunk(lua_State* L);
	static int _play(lua_State* L);
	static int _pause(lua_State* L);
	static int _getPosition(lua_State* L);
	static int _getInfo(lua_State* L);

	AudioStream* mStream;
	UNTZ::Sound* mSound;
	UNTZ::SoundInfo mSoundInfo;
	std::vector<float> mTempBuff;
	std::vector<float> mSoundData;
};

#endif
