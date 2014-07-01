#ifndef MOAI_AUBIO_ROOT_HPP
#define MOAI_AUBIO_ROOT_HPP

#include <moai-core/MOAILua.h>
#include "Source.hpp"

template<typename T>
class Root: public Source<T>
{
public:
	Root();
	virtual ~Root();

	void RegisterLuaFuncs(MOAILuaState& state);

	void setChunkSize(size_t chunkSize);
	void pump();

protected:
	virtual size_t pull(T* buff, size_t size) = 0;

private:
	static int _pump(lua_State* L);
	static int _setChunkSize(lua_State* L);

	bool mFirstPump;
	size_t mChunkSize;
	T* mBuffer;
};

#include "Root.inl"

#endif
