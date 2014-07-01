#ifndef MOAI_AUBIO_SUBSTREAM_HPP
#define MOAI_AUBIO_SUBSTREAM_HPP

#include <moai-core/MOAILua.h>
#include "Source.hpp"

template<typename T>
class Substream: public Source<T>
{
public:
	void beginStream() { Source<T>::beginStream(); }
	void pushData(const T* data, size_t size) { Source<T>::pushData(data, size); }
	void endStream() { Source<T>::endStream(); }
};

#endif
