#ifndef MOAI_AUBIO_SPEC_DESC_HPP
#define MOAI_AUBIO_SPEC_DESC_HPP

#include <moai-core/MOAILua.h>
#include <aubio.h>
#include <string>
#include "ChunkProcessor.hpp"
#include "Source.hpp"

class SpecDesc
	:public Sink<cvec_t>
	,public Source<float>
{
public:
	DECL_LUA_FACTORY(SpecDesc);

	SpecDesc();
	virtual ~SpecDesc();

	void RegisterLuaFuncs(MOAILuaState& state);

protected:
	void onBegin();
	void onData(const cvec_t* fftGrains, size_t size);
	void onEnd();

	static int _setFunction(lua_State* L);
	static int _setFrameSize(lua_State* L);

private:
	std::string mFunction;
	aubio_specdesc_t* mSpecDesc;
	uint_t mFrameSize;
};

#endif
