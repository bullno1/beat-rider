#include <moai-core/headers.h>
#include "Aubio.hpp"

template<typename T>
void safeArrayDelete(T*& ptr)
{
	if(ptr)
	{
		delete[] ptr;
		ptr = NULL;
	}
}

class Aubio::Impl
{
public:
	static void disposeSound(UNTZ::Sound*& sound)
	{
		if(sound)
		{
			UNTZ::Sound::dispose(sound);
			sound = 0;
		}
	}

	static int load(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "US");

		disposeSound(self->mSound);
		safeArrayDelete(reinterpret_cast<char*&>(self->mAudioData));

		STLString filename = state.GetValue(2, "");
		if(MOAILogMessages::CheckFileExists(filename.c_str()))
		{
			UNTZ::SoundInfo soundInfo;
			if(UNTZ::Sound::decode(filename, soundInfo, &self->mAudioData))
			{
				self->mSound = UNTZ::Sound::create(soundInfo, self->mAudioData, false);
				state.Push(true);
			}
			else
			{
				state.Push(false);
			}
		}
		else
		{
			state.Push(false);
		}

		return 1;
	}

	static int play(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");

		if(self->mSound)
		{
			MOAILogMgr::Get().Print("Test");
			self->mSound->play();
		}

		return 0;
	}
};

Aubio::Aubio()
	:mAudioData(0)
	,mSound(0)
{
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject)
	RTTI_END
}

Aubio::~Aubio()
{
	Impl::disposeSound(mSound);
	safeArrayDelete(reinterpret_cast<char*&>(mAudioData));
}

void Aubio::RegisterLuaClass(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

void Aubio::RegisterLuaFuncs(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ "load", &Impl::load },
		{ "play", &Impl::play },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}
