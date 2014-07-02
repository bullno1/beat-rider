#include <moai-core/headers.h>

template<typename T>
Sink<T>::Sink()
{
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject);
	RTTI_END
}

template<typename T>
Sink<T>::~Sink()
{}

template<>
inline cc8* Sink<float>::TypeName() const
{
	return "Sink<float>";
}

#include <aubio.h>

template<>
inline cc8* Sink<cvec_t>::TypeName() const
{
	return "Sink<fft_grain>";
}
