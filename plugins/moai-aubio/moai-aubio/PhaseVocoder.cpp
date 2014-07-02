#include <moai-core/headers.h>
#include "PhaseVocoder.hpp"
#include "AubioUtils.hpp"

PhaseVocoder::PhaseVocoder()
	:mPvoc(NULL)
	,mFftBuff(NULL)
{
	RTTI_BEGIN
		RTTI_EXTEND(ChunkProcessor<float>);
		RTTI_EXTEND(Source<cvec_t>);
	RTTI_END
}

PhaseVocoder::~PhaseVocoder()
{
	if(mPvoc)
	{
		del_aubio_pvoc(mPvoc);
		mPvoc = NULL;
	}

	if(mFftBuff)
	{
		del_cvec(mFftBuff);
		mFftBuff = NULL;
	}
}

void PhaseVocoder::onBegin()
{
	ChunkProcessor<float>::onBegin();
	Source<cvec_t>::beginStream();

	mPvoc = new_aubio_pvoc(getChunkSize() * 2, getChunkSize());
	mFftBuff = new_cvec(getChunkSize() * 2);
}

void PhaseVocoder::onChunk(const float* data)
{
	ALLOC_AUBIO_FVEC(dataVec, data, getChunkSize());

	aubio_pvoc_do(mPvoc, dataVec, mFftBuff);
	Source<cvec_t>::pushData(mFftBuff, 1);
}

void PhaseVocoder::onEnd()
{
	del_aubio_pvoc(mPvoc);
	mPvoc = NULL;

	del_cvec(mFftBuff);
	mFftBuff = NULL;

	Source<cvec_t>::endStream();
	ChunkProcessor<float>::onEnd();
}

void PhaseVocoder::RegisterLuaFuncs(MOAILuaState& state)
{
	ChunkProcessor<float>::RegisterLuaFuncs(state);
	Source<cvec_t>::RegisterLuaFuncs(state);
}
