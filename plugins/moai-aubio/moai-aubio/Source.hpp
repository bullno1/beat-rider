#ifndef MOAI_AUBIO_SOURCE_HPP
#define MOAI_AUBIO_SOURCE_HPP

#include <moai-core/MOAILua.h>
#include "Sink.hpp"
#include <typeinfo>

template<typename T>
class Source: public virtual MOAILuaObject
{
public:
	typedef Sink<T> SinkType;

	DECL_LUA_FACTORY(Source<T>);

	Source();
	virtual ~Source();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void beginStream();
	void pushData(const T* data, size_t size);
	void endStream();

private:
	static int _connect(lua_State* L);

	std::vector<MOAILuaMemberRef*> mSinkRefs;
	std::vector<SinkType*> mSinks;
};

#include "Source.inl"

#endif
