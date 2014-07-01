#ifndef MOAI_AUBIO_SINK_HPP
#define MOAI_AUBIO_SINK_HPP

#include <moai-core/MOAILua.h>
#include <typeinfo>

template<typename T>
class Source;

template<typename T>
class Sink: public virtual MOAILuaObject
{
	friend class Source<T>;
public:
	DECL_LUA_FACTORY(Sink<T>);

	Sink();
	virtual ~Sink();

protected:
	virtual void onBegin() {};
	virtual void onData(const T* data, size_t size) {};
	virtual void onEnd() {};
};

#include "Sink.inl"

#endif
