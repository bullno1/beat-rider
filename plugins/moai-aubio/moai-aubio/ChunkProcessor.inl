#include <moai-core/headers.h>
#include <cstring>
#include <algorithm>

template<typename T>
ChunkProcessor<T>::ChunkProcessor()
	:mChunkSize(512)
	,mCursor(0)
	,mBuffer(new float[512])
{
	RTTI_BEGIN
		this->template ExtendRTTI< Sink<T> >(this);
	RTTI_END
}

template<typename T>
ChunkProcessor<T>::~ChunkProcessor()
{
	delete[] mBuffer;
}

template<typename T>
void ChunkProcessor<T>::onBegin()
{
	mCursor = 0;
}

template<typename T>
void ChunkProcessor<T>::onData(const T* data, size_t size)
{
	while(size > 0)
	{
		size_t copySize = std::min(size, mChunkSize - mCursor);
		memcpy(&mBuffer[mCursor], data, copySize * sizeof(T));
		mCursor += copySize;
		size -= copySize;
		data += copySize;

		if(mCursor == mChunkSize)
		{
			onChunk(mBuffer);
			mCursor = 0;
		}
	}
}

template<typename T>
void ChunkProcessor<T>::onEnd()
{}

template<typename T>
void ChunkProcessor<T>::RegisterLuaFuncs(MOAILuaState& state)
{
	Sink<T>::RegisterLuaFuncs(state);

	luaL_Reg regTable[] = {
		{ "setChunkSize", _setChunkSize },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

template<typename T>
int ChunkProcessor<T>::_setChunkSize(lua_State* L)
{
	MOAI_LUA_SETUP(ChunkProcessor<T>, "UN");

	self->setChunkSize(state.GetValue(2, 512));
	return 0;
}

template<typename T>
void ChunkProcessor<T>::setChunkSize(size_t size)
{
	mChunkSize = size;
	delete[] mBuffer;
	mBuffer = new float[size];
}

template<typename T>
size_t ChunkProcessor<T>::getChunkSize() const
{
	return mChunkSize;
}
