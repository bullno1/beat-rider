#ifndef MOAI_AUBIO_TABLE_SINK_HPP
#define MOAI_AUBIO_TABLE_SINK_HPP

#include <moai-core/MOAILua.h>
#include "Sink.hpp"
#include <vector>

class BufferSink: public Sink<float>
{
public:
	DECL_LUA_FACTORY(BufferSink);

	BufferSink();
	virtual ~BufferSink();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onData(const float* data, size_t size);
	void onEnd();

private:
	static int _getAsTable(lua_State* L);

	std::vector<float> mBuffer;
};

#endif
