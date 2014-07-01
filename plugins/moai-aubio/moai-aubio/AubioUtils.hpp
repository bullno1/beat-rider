#ifndef MOAI_AUBIO_AUBIO_UTILS_HPP
#define MOAI_AUBIO_AUBIO_UTILS_HPP

#define ALLOC_AUBIO_FVEC(Name, Ptr, Size) \
	fvec_t Name##vec = { Size, const_cast<float*>(Ptr) }; \
	fvec_t* Name = &Name##vec;

#define ALLOC_AUBIO_TEMP_VEC(Name, Size) \
	float Name##vec_storage[Size]; \
	fvec_t Name##vec = { Size, Name##vec_storage }; \
	fvec_t* Name = &Name##vec;

#endif
