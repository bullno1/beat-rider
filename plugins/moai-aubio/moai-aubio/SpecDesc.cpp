#include <moai-core/headers.h>
#include "SpecDesc.hpp"
#include "AubioUtils.hpp"

SpecDesc::SpecDesc()
	:mSpecDesc(NULL)
	,mFrameSize(1024)
{
	RTTI_BEGIN
		RTTI_EXTEND(Sink<cvec_t>);
		RTTI_EXTEND(Source<float>);
	RTTI_END
}

SpecDesc::~SpecDesc()
{
	if(mSpecDesc)
	{
		del_aubio_specdesc(mSpecDesc);
		mSpecDesc = NULL;
	}
}

void SpecDesc::onBegin()
{
	Source<float>::beginStream();

	mSpecDesc = new_aubio_specdesc(const_cast<char*>(mFunction.c_str()), mFrameSize);
}

void SpecDesc::onData(const cvec_t* fftGrains, size_t size)
{
	ALLOC_AUBIO_TEMP_VEC(out, 1);

	for(size_t i = 0; i < size; ++i)
	{
		aubio_specdesc_do(mSpecDesc, const_cast<cvec_t*>(&fftGrains[i]), out);
		smpl_t outVal = fvec_get_sample(out, 0);
		Source<float>::pushData(&outVal, 1);
	}
}

void SpecDesc::onEnd()
{
	del_aubio_specdesc(mSpecDesc);
	mSpecDesc = NULL;

	Source<float>::endStream();
}

void SpecDesc::RegisterLuaFuncs(MOAILuaState& state)
{
	Source<float>::RegisterLuaFuncs(state);

	luaL_reg regTable[] = {
		{ "setFunction", _setFunction },
		{ "setFrameSize", _setFrameSize },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

int SpecDesc::_setFunction(lua_State* L)
{
	MOAI_LUA_SETUP(SpecDesc, "US");

	self->mFunction = state.GetValue(2, "");
	return 0;
}

int SpecDesc::_setFrameSize(lua_State* L)
{
	MOAI_LUA_SETUP(SpecDesc, "UN");

	self->mFrameSize = state.GetValue(2, 1024);
	return 0;
}
