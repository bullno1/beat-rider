#include <moai-core/headers.h>

template<typename T>
Source<T>::Source()
{
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject);
	RTTI_END
}

template<typename T>
Source<T>::~Source()
{
	for(typename std::vector<MOAILuaMemberRef*>::iterator itr = mSinkRefs.begin(); itr!= mSinkRefs.end(); ++itr)
	{
		delete *itr;
	}
	mSinkRefs.clear();
	mSinks.clear();
}

template<typename T>
int Source<T>::_connect(lua_State* L)
{
	MOAI_LUA_SETUP(Source<T>, "UU");

	SinkType* sink = state.GetLuaObject<SinkType>(2, true);
	if(sink)
	{
		MOAILuaMemberRef* ref = new MOAILuaMemberRef();
		ref->SetRef(*self, state, 2);
		self->mSinkRefs.push_back(ref);
		self->mSinks.push_back(sink);
	}

	return 0;
}

template<typename T>
void Source<T>::RegisterLuaFuncs(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ "connect", &Source<T>::_connect },
		{ NULL, NULL }
	};

	luaL_register(state, 0, regTable);
}

template<typename T>
void Source<T>::beginStream()
{
	for(typename std::vector<SinkType*>::iterator itr = mSinks.begin(); itr!= mSinks.end(); ++itr)
	{
		(*itr)->onBegin();
	}
}

template<typename T>
void Source<T>::pushData(const T* data, size_t size)
{
	for(typename std::vector<SinkType*>::iterator itr = mSinks.begin(); itr!= mSinks.end(); ++itr)
	{
		(*itr)->onData(data, size);
	}
}

template<typename T>
void Source<T>::endStream()
{
	for(typename std::vector<SinkType*>::iterator itr = mSinks.begin(); itr!= mSinks.end(); ++itr)
	{
		(*itr)->onEnd();
	}
}

template<>
inline cc8* Source<float>::TypeName() const
{
	return "Source<float>";
}
