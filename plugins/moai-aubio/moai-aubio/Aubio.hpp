#ifndef MOAI_AUBIO_HPP
#define MOAI_AUBIO_HPP

#include <moai-core/MOAILua.h>
#include <UntzSound.h>
#include <pthread.h>
#include <aubio.h>
#include <vector>
#include <map>
#include <string>

class Aubio: public virtual MOAILuaObject
{
	class Impl;
	enum Status
	{
		READY,
		LOADING,
		LOADED,
		FAILED
	};

public:
	friend class Impl;

	DECL_LUA_FACTORY(Aubio);
	Aubio();
	virtual ~Aubio();
	void RegisterLuaClass(MOAILuaState& state);
	void RegisterLuaFuncs(MOAILuaState& state);
private:
	typedef std::vector<float> FloatVec;
	typedef std::map<std::string, FloatVec> SpectralDescriptions;

	// Untz audio
	FloatVec mAudioData;
	UNTZ::Sound* mSound;
	UNTZ::SoundInfo mSoundInfo;
	// Threading
	volatile bool mAsyncThreadShouldStop;
	volatile Status mStatus;
	pthread_t mAsyncThread;
	// Analysis
	bool mSkipAnalysis;
	STLString mFilename;
	volatile float mAsyncThreadProgress;
	uint_t mHopSize;
	FloatVec mBeatTimes;
	FloatVec mOnsetTimes;
	SpectralDescriptions mSpectralDescs;
};

#endif
