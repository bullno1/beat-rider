#include <aubio.h>
#include <moai-core/headers.h>
#include <moai-core/MOAILua.h>
#include "Aubio.hpp"
#include <mpg123.h>

void MOAIAubioAppInitialize()
{
	mpg123_init();
}

void MOAIAubioContextInitialize()
{
	REGISTER_LUA_CLASS(Aubio);
}

void MOAIAubioAppFinalize()
{
	mpg123_exit();
	aubio_cleanup();
}
