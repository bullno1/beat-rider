#ifndef MOAI_AUBIO_CHUNK_PROCESSOR_HPP
#define MOAI_AUBIO_CHUNK_PROCESSOR_HPP

#include <moai-core/MOAILua.h>
#include "Sink.hpp"

template<typename T>
class ChunkProcessor: public virtual Sink<T>
{
public:
	DECL_LUA_FACTORY(ChunkProcessor<T>);

	ChunkProcessor();
	virtual ~ChunkProcessor();

	void RegisterLuaFuncs(MOAILuaState& state);

	void setChunkSize(size_t size);
	size_t getChunkSize() const;

protected:
	void onBegin();
	void onData(const T* data, size_t size);
	void onEnd();

	virtual void onChunk(const T* data) {};

	static int _setChunkSize(lua_State* L);

private:
	size_t mChunkSize;
	size_t mCursor;
	T* mBuffer;
};

#include "ChunkProcessor.inl"

#endif
