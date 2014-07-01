#include <moai-core/headers.h>
#include "BufferSink.hpp"

BufferSink::BufferSink()
{
	RTTI_BEGIN
		RTTI_EXTEND(Sink<float>);
	RTTI_END
}

BufferSink::~BufferSink()
{}

void BufferSink::RegisterLuaFuncs(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ "getAsTable", _getAsTable },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

void BufferSink::onBegin()
{
	mBuffer.clear();
}

void BufferSink::onData(const float* data, size_t size)
{
	mBuffer.insert(mBuffer.begin(), data, data + size);
}

void BufferSink::onEnd()
{}

int BufferSink::_getAsTable(lua_State* L)
{
	MOAI_LUA_SETUP(BufferSink, "U");

	lua_createtable(L, self->mBuffer.size(), 0);
	state.WriteArray(self->mBuffer.size(), self->mBuffer.data());
	return 1;
}
