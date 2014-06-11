#ifndef MOAI_AUBIO_HPP
#define MOAI_AUBIO_HPP

#include <moai-core/MOAILua.h>
#include <UntzSound.h>
#include <pthread.h>
#include <aubio.h>
#include <vector>

class Aubio: public virtual MOAILuaObject
{
	class Impl;
public:
	friend class Impl;

	DECL_LUA_FACTORY(Aubio);
	Aubio();
	virtual ~Aubio();
	void RegisterLuaClass(MOAILuaState& state);
	void RegisterLuaFuncs(MOAILuaState& state);
private:
	// Untz audio
	float* mAudioData;
	UNTZ::Sound* mSound;
	UNTZ::SoundInfo mSoundInfo;
	// Threading
	volatile bool mAnalyzerRunning;
	volatile bool mAnalyzerShouldStop;
	pthread_t mAnalyzerThread;
	// Analysis
	volatile float mAnalysisProgress;
	uint_t mHopSize;
	std::vector<float> mBeatTimes;
	std::vector<float> mOnsetTimes;
};

#endif
