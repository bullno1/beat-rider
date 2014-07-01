#include <moai-core/headers.h>

template<typename T>
Root<T>::Root()
	:mFirstPump(true)
	,mChunkSize(512)
	,mBuffer(new T[512])
{
	RTTI_BEGIN
		this->template ExtendRTTI< Source<T> >(this);
	RTTI_END
}

template<typename T>
Root<T>::~Root()
{
	if(mBuffer)
	{
		delete[] mBuffer;
		mBuffer = NULL;
	}
}

template<typename T>
void Root<T>::RegisterLuaFuncs(MOAILuaState& state)
{
	Source<T>::RegisterLuaFuncs(state);

	luaL_Reg regTable[] = {
		{ "setChunkSize", _setChunkSize },
		{ "pump", _pump },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

template<typename T>
int Root<T>::_setChunkSize(lua_State* L)
{
	MOAI_LUA_SETUP(Root<T>, "UN");

	self->setChunkSize(state.GetValue(2, 512));
	return 0;
}

template<typename T>
void Root<T>::setChunkSize(size_t size)
{
	mChunkSize = size;
	delete[] mBuffer;
	mBuffer = new T[size];
}

template<typename T>
int Root<T>::_pump(lua_State* L)
{
	MOAI_LUA_SETUP(Root<T>, "U");

	if(self->mFirstPump)
	{
		self->beginStream();
		self->mFirstPump = false;
	}

	size_t size = self->pull(self->mBuffer, self->mChunkSize);
	if(size != 0)
	{
		self->pushData(self->mBuffer, size);
	}
	else
	{
		self->endStream();
	}

	state.Push(size != 0);
	return 1;
}
