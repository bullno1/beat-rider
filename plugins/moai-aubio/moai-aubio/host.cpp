#include <aubio.h>
#include <moai-core/headers.h>
#include <moai-core/MOAILua.h>
#include "Aubio.hpp"

void MOAIAubioAppInitialize()
{
}

void MOAIAubioContextInitialize()
{
	REGISTER_LUA_CLASS(Aubio);
}

void MOAIAubioAppFinalize()
{
	aubio_cleanup();
}
