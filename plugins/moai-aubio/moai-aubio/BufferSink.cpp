#include <moai-core/headers.h>
#include "BufferSink.hpp"
#include <limits>
#include <algorithm>

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
	mBuffer.insert(mBuffer.end(), data, data + size);
}

void BufferSink::onEnd()
{}

int BufferSink::_getAsTable(lua_State* L)
{
	MOAI_LUA_SETUP(BufferSink, "U");

	bool normalize = state.GetValue(2, false);

	lua_createtable(L, self->mBuffer.size(), 0);

	if(normalize)
	{
		float min = std::numeric_limits<float>::max();
		float max = std::numeric_limits<float>::min();

		for(std::vector<float>::iterator itr = self->mBuffer.begin(); itr != self->mBuffer.end(); ++itr)
		{
			min = std::min(min, *itr);
			max = std::max(max, *itr);
		}

		float range = max - min;

		for(size_t i = 0; i < self->mBuffer.size(); ++i)
		{
			lua_pushnumber(state, (self->mBuffer[i] - min) / range);
			lua_rawseti(state, -2, i + 1);
		}
	}
	else
	{
		state.WriteArray(self->mBuffer.size(), self->mBuffer.data());
	}

	return 1;
}
