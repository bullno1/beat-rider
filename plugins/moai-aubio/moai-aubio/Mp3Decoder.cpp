#include "Mp3Decoder.hpp"
#include <limits>
#include <mpg123.h>
#include <stdlib.h>
#include <vector>
#include <moai-core/headers.h>

#define RETURN_IF_FAIL(cond) if(!(cond)) return;
#define MPG123_ASSERT(op) \
	do { \
		int errCode = (op); \
		if(errCode != MPG123_OK) \
		{ \
			ZLLog::Print("%s(%d): %s\n", __FILE__, __LINE__, mpg123_plain_strerror(errCode)); \
			return; \
		} \
	} while(false)

namespace {
	class Decoder
	{
	public:
		Decoder()
		{
			int error;
			mHandle = mpg123_new(NULL, &error);
		}

		~Decoder()
		{
			if(mHandle)
			{
				mpg123_delete(mHandle);
				mHandle = NULL;
			}
		}

		operator mpg123_handle*() const
		{
			return mHandle;
		}

	private:
		mpg123_handle* mHandle;
	};

	class File
	{
	public:
		File(const char* path)
		{
			mHandle = fopen(path, "rb");
		}

		~File()
		{
			if(mHandle)
			{
				fclose(mHandle);
				mHandle = NULL;
			}
		}

		off_t size()
		{
			long oldPos = ftell(mHandle);
			fseek(mHandle, 0, SEEK_END);
			long fileSize = ftell(mHandle);
			fseek(mHandle, oldPos, SEEK_SET);
			return fileSize;
		}

		operator FILE*() const
		{
			return mHandle;
		}

		static ssize_t read(void* file, void* buff, size_t size)
		{
			return fread(buff, 1, size, (FILE*)file);
		}

		static off_t seek(void* file, off_t offset, int whence)
		{
			return fseek((FILE*)file, offset, whence);
		}

	private:
		FILE* mHandle;
	};

	class Mp3Stream: public AudioStream
	{
	public:
		Mp3Stream(const char* path)
			:mOk(false)
			,mFile(path)
		{
			RETURN_IF_FAIL(mFile != NULL);
			RETURN_IF_FAIL(mDecoder != NULL);
			MPG123_ASSERT(mpg123_replace_reader_handle(mDecoder, &File::read, &File::seek, NULL));

			//Allow all rates and number of channels but force encoding to MPG123_ENC_SIGNED_16
			MPG123_ASSERT(mpg123_format_none(mDecoder));
			const long* availableRates = NULL;
			size_t numRates = 0;
			mpg123_rates(&availableRates, &numRates);
			for(size_t numChannels = MPG123_MONO; numChannels <= MPG123_STEREO; ++numChannels)
			{
				for(size_t rateIndex = 0; rateIndex < numRates; ++rateIndex)
				{
					MPG123_ASSERT(mpg123_format(mDecoder, availableRates[rateIndex], numChannels, MPG123_ENC_SIGNED_16));
				}
			}

			MPG123_ASSERT(mpg123_open_handle(mDecoder, mFile));
			MPG123_ASSERT(mpg123_set_filesize(mDecoder, mFile.size()));

			long rate;
			int channels, encoding;
			MPG123_ASSERT(mpg123_getformat(mDecoder, &rate, &channels, &encoding));

			mSampleRate = rate;
			mNumChannels = channels;
			mOk = true;
		}

		double getLength() const
		{
			off_t numSamples = mpg123_length(mDecoder);
			return (double)numSamples / (double)mSampleRate;
		}

		double getPosition() const
		{
			off_t pos = mpg123_tell(mDecoder);
			return (double)pos / (double)mSampleRate;
		}

		unsigned int getSampleRate() const { return mSampleRate; }

		unsigned int getNumChannels() const { return mNumChannels; }

		AudioStream::Status read(float* outputBuff, size_t numFrames, size_t& numFramesRead)
		{
			mTemp.resize(numFrames * mNumChannels);
			size_t numBytesRead;
			int err = mpg123_read(
				mDecoder,
				reinterpret_cast<unsigned char*>(mTemp.data()),
				numFrames * sizeof(int16_t) * mNumChannels,
				&numBytesRead
			);
			numFramesRead = numBytesRead / sizeof(int16_t) / mNumChannels;
			for(int i = 0; i < numBytesRead / sizeof(int16_t); ++i)
			{
				outputBuff[i] = (float)mTemp[i] / (float)std::numeric_limits<int16_t>::max();
			}

			switch(err)
			{
				case MPG123_OK:
					return AudioStream::OK;
				case MPG123_DONE:
					return AudioStream::EOS;
				default:
					return AudioStream::ERROR;
			}
		}

		void close()
		{
			delete this;
		}

		bool isOk()
		{
			return mOk;
		}

	private:
		bool mOk;
		Decoder mDecoder;
		File mFile;
		unsigned int mSampleRate;
		unsigned int mNumChannels;
		std::vector<int16_t> mTemp;
	};
}

AudioStream* createMp3Stream(const char* filename)
{
	Mp3Stream* stream = new Mp3Stream(filename);
	if(!stream->isOk())
	{
		stream->close();
		return NULL;
	}
	else
	{
		return stream;
	}
}
