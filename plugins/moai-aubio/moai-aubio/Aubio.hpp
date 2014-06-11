#ifndef MOAI_AUBIO_HPP
#define MOAI_AUBIO_HPP

#include <moai-core/MOAILua.h>
#include <UntzSound.h>

class Aubio: public virtual MOAILuaObject
{
	class Impl;
public:
	friend class Impl;

	DECL_LUA_FACTORY(Aubio);
	Aubio();
	virtual ~Aubio();
	void RegisterLuaClass(MOAILuaState& state);
	void RegisterLuaFuncs(MOAILuaState& state);
private:
	float* mAudioData;
	UNTZ::Sound* mSound;
};

#endif
