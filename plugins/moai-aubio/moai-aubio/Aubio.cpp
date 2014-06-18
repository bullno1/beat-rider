#include <moai-core/headers.h>
#include <pthread.h>
#include "Aubio.hpp"
#include "MP3Codec.hpp"

#define RETURN_NULL_IF_LOADING() if(self->mStatus == Aubio::LOADING) { state.Push(); return 1; }

class Aubio::Impl
{
public:
	static int load(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "US");

		stopAsyncThread(self);
		self->mAudioData.clear();
		disposeSound(self->mSound);

		self->mFilename = state.GetValue(2, "");
		if(MOAILogMessages::CheckFileExists(self->mFilename.c_str()))
		{
			startAsyncThread(self);
		}
		else
		{
			self->mStatus = Aubio::FAILED;
		}

		return 0;
	}

	static int play(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");
		RETURN_NULL_IF_LOADING();

		self->mSound->play();

		return 0;
	}

	static int getProgress(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");

		state.Push(self->mAsyncThreadProgress);
		return 1;
	}

	static int getStatus(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");

		state.Push(self->mStatus);
		return 1;
	}

	static int getBeats(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");
		RETURN_NULL_IF_LOADING();

		lua_newtable(L);
		state.WriteArray(self->mBeatTimes.size(), self->mBeatTimes.data());
		return 1;
	}

	static int getOnsets(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");
		RETURN_NULL_IF_LOADING();

		lua_newtable(L);
		state.WriteArray(self->mOnsetTimes.size(), self->mOnsetTimes.data());
		return 1;
	}

	static int addSpectralDescriptor(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "US");
		RETURN_NULL_IF_LOADING();

		//TODO: validate descriptor name
		self->mSpectralDescs[state.GetValue(2, "")] = FloatVec();

		return 0;
	}

	static int removeSpectralDescriptor(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "US");
		RETURN_NULL_IF_LOADING();

		SpectralDescriptions::iterator itr = self->mSpectralDescs.find(state.GetValue(2, ""));
		if(itr != self->mSpectralDescs.end())
		{
			self->mSpectralDescs.erase(itr);
		}

		return 0;
	}

	static int getSpectralDescription(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "US");
		RETURN_NULL_IF_LOADING();

		SpectralDescriptions::iterator itr = self->mSpectralDescs.find(state.GetValue(2, ""));
		if(itr != self->mSpectralDescs.end())
		{
			lua_newtable(L);
			state.WriteArray(itr->second.size(), itr->second.data());
		}
		else
		{
			state.Push();
		}

		return 1;
	}

	static int getHopSize(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");

		state.Push(self->mHopSize);
		return 1;
	}

	static int setHopSize(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "UN");

		//TODO: validate whether hop size is a power of two
		self->mHopSize = state.GetValue<uint_t>(2, 512);
		return 0;
	}

	static int getPosition(lua_State* L)
	{
		MOAI_LUA_SETUP(Aubio, "U");
		RETURN_NULL_IF_LOADING();

		state.Push(self->mSound->getPosition());
		return 1;
	}

	static void startAsyncThread(Aubio* self)
	{
		self->mAsyncThreadShouldStop = false;
		self->mAsyncThreadProgress = 0.0f;
		self->mStatus = LOADING;
		pthread_create(&self->mAsyncThread, NULL, &asyncThreadEntry, self);
	}

	static void stopAsyncThread(Aubio* self)
	{
		if(self->mStatus == LOADING)
		{
			self->mAsyncThreadShouldStop = true;
			pthread_join(self->mAsyncThread, NULL);
			self->mStatus = READY;
		}
	}

	static void* asyncThreadEntry(void* selfPtr)
	{
		Aubio* self = static_cast<Aubio*>(selfPtr);

		// Load audio
		self->mAudioData.clear();
		if(!decodeMP3(self, &reportProgress, self->mFilename, self->mSoundInfo, self->mAudioData))
		{
			self->mStatus = FAILED;
			return NULL;
		}

		self->mSound = UNTZ::Sound::create(self->mSoundInfo, self->mAudioData.data(), false);

		// Reset old feature buffers
		self->mBeatTimes.clear();
		self->mOnsetTimes.clear();
		for(SpectralDescriptions::iterator itr = self->mSpectralDescs.begin(); itr != self->mSpectralDescs.end(); ++itr)
		{
			itr->second.clear();
		}

		// Extract some book keeping info
		uint_t hopSize = self->mHopSize;
		const FloatVec& samples = self->mAudioData;

		UNTZ::SoundInfo& soundInfo = self->mSoundInfo;
		UInt32 numChannels = soundInfo.mChannels;
		UInt32 numFrames = soundInfo.mTotalFrames;
		UInt32 numHops = numFrames / self->mHopSize;
		UInt32 sampRate = soundInfo.mSampleRate;

		// Create analyzers
		fvec_t* hopBuff = new_fvec(self->mHopSize);
		fvec_t* tempBuff = new_fvec(2);
		aubio_onset_t* onset = new_aubio_onset(
			const_cast<char_t*>("hfc"),
			hopSize * 2,
			hopSize,
			sampRate
		);

		aubio_tempo_t* tempo = new_aubio_tempo(
			const_cast<char_t*>("default"),
			hopSize * 2,
			hopSize,
			sampRate
		);

		std::map<std::string, aubio_specdesc_t*> specdescs;
		for(SpectralDescriptions::const_iterator itr = self->mSpectralDescs.begin(); itr != self->mSpectralDescs.end(); ++itr)
		{
			specdescs[itr->first] = new_aubio_specdesc(const_cast<char_t*>(itr->first.c_str()), hopSize * 2);
		}
		aubio_pvoc_t* pvoc = new_aubio_pvoc(hopSize * 2, hopSize);
		cvec_t* fftBuff = new_cvec(hopSize * 2);

		// Mix all channels for analysis
		for(unsigned int hopIndex = 0; hopIndex < numHops && !self->mAsyncThreadShouldStop; ++hopIndex)
		{
			self->mAsyncThreadProgress = 0.5 + (float)(hopIndex + 1) / (float)numHops / 2.0f;
			for(unsigned int frameIndex = 0; frameIndex < hopSize; ++frameIndex)
			{
				float sum = 0.0f;
				for(unsigned int channelIndex = 0; channelIndex < numChannels; ++channelIndex)
				{
					unsigned int sampleIndex = hopIndex * hopSize * numChannels + frameIndex * numChannels + channelIndex;
					sum += samples[sampleIndex];
				}
				fvec_set_sample(hopBuff, sum / (float)numChannels, frameIndex);
			}

			//Beat detection
			aubio_tempo_do(tempo, hopBuff, tempBuff);
			if(fvec_get_sample(tempBuff, 0))
			{
				self->mBeatTimes.push_back(aubio_tempo_get_last_s(tempo));
			}
			//Onset detection
			aubio_onset_do(onset, hopBuff, tempBuff);
			if(fvec_get_sample(tempBuff, 0))
			{
				self->mOnsetTimes.push_back(aubio_onset_get_last_s(onset));
			}
			//Spectral description
			aubio_pvoc_do(pvoc, hopBuff, fftBuff);
			for(SpectralDescriptions::iterator itr = self->mSpectralDescs.begin(); itr != self->mSpectralDescs.end(); ++itr)
			{
				aubio_specdesc_do(specdescs[itr->first], fftBuff, tempBuff);
				itr->second.push_back(fvec_get_sample(tempBuff, 0));
			}
		}

		del_cvec(fftBuff);
		del_aubio_pvoc(pvoc);
		for(std::map<std::string, aubio_specdesc_t*>::iterator itr = specdescs.begin(); itr != specdescs.end(); ++itr)
		{
			del_aubio_specdesc(itr->second);
		}
		del_aubio_tempo(tempo);
		del_aubio_onset(onset);
		del_fvec(hopBuff);

		if(!self->mAsyncThreadShouldStop)//if thread was not interrupted
		{
			self->mStatus = LOADED;
		}

		return NULL;
	}

	static bool reportProgress(void* context, float progress)
	{
		Aubio* self = reinterpret_cast<Aubio*>(context);
		self->mAsyncThreadProgress = progress / 2.0f;//decoding is considered half of the workload
		return !self->mAsyncThreadShouldStop;
	}

	static void disposeSound(UNTZ::Sound*& sound)
	{
		if(sound)
		{
			UNTZ::Sound::dispose(sound);
			sound = 0;
		}
	}
};

Aubio::Aubio()
	:mAudioData()
	,mSound(0)
	,mSoundInfo()
	,mAsyncThreadShouldStop(true)
	,mStatus(READY)
	,mHopSize(512)
{
	RTTI_BEGIN
		RTTI_EXTEND(MOAILuaObject)
	RTTI_END
}

Aubio::~Aubio()
{
	Impl::stopAsyncThread(this);
	Impl::disposeSound(mSound);
}

void Aubio::RegisterLuaClass(MOAILuaState& state)
{
	state.SetField(-1, "STATUS_READY", READY);
	state.SetField(-1, "STATUS_LOADING", LOADING);
	state.SetField(-1, "STATUS_LOADED", LOADED);
	state.SetField(-1, "STATUS_FAILED", FAILED);

	luaL_Reg regTable[] = {
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}

void Aubio::RegisterLuaFuncs(MOAILuaState& state)
{
	luaL_Reg regTable[] = {
		{ "load", &Impl::load },
		{ "play", &Impl::play },
		{ "getHopSize", &Impl::getHopSize },
		{ "setHopSize", &Impl::setHopSize },
		{ "getProgress", &Impl::getProgress },
		{ "getStatus", &Impl::getStatus },
		{ "getBeats", &Impl::getBeats },
		{ "getOnsets", &Impl::getOnsets },
		{ "addSpectralDescriptor", &Impl::addSpectralDescriptor },
		{ "removeSpectralDescriptor", &Impl::removeSpectralDescriptor },
		{ "getSpectralDescription", &Impl::getSpectralDescription },
		{ "getPosition", &Impl::getPosition },
		{ NULL, NULL }
	};
	luaL_register(state, 0, regTable);
}
