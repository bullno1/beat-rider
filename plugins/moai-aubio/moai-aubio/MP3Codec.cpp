#include "MP3Codec.hpp"
#include <limits>
#include <mpg123.h>
#include <stdlib.h>

#define FAIL_IF_FALSE(cond) if(!(cond)) { return false; }

namespace {
	ssize_t vfsRead(void* file, void* buff, size_t size)
	{
		return fread(buff, 1, size, (FILE*)file);
	}

	off_t vfsSeek(void* file, off_t offset, int whence)
	{
		return fseek((FILE*)file, offset, whence);
	}

	class ScopedFile
	{
	public:
		ScopedFile(const char* name, const char* mode)
			:mFile(fopen(name, mode))
		{}

		~ScopedFile()
		{
			fclose(mFile);
		}

		operator FILE*() const
		{
			return mFile;
		}
	private:
		FILE* mFile;
	};

	class ScopedDecoder
	{
	public:
		ScopedDecoder()
		{
			int err;
			mDecoder = mpg123_new(NULL, &err);
		}

		~ScopedDecoder()
		{
			mpg123_delete(mDecoder);
		}

		operator mpg123_handle*() const
		{
			return mDecoder;
		}
	private:
		mpg123_handle* mDecoder;
	};
}

bool decodeMP3(
	void* context,
	ProgressCallback progressCallback,
	const std::string& path,
	UNTZ::SoundInfo& soundInfo,
	std::vector<float>& samples
)
{
	int err;
	ScopedDecoder decoder;
	FAIL_IF_FALSE(decoder != NULL);

	ScopedFile file(path.c_str(), "rb");
	FAIL_IF_FALSE(mpg123_replace_reader_handle(decoder, &vfsRead, &vfsSeek, NULL) == MPG123_OK);
	FAIL_IF_FALSE(mpg123_open_handle(decoder, file) == MPG123_OK);

	long rate;
	int channels, encodings;
	FAIL_IF_FALSE(mpg123_getformat(decoder, &rate, &channels, &encodings) == MPG123_OK);
	FAIL_IF_FALSE(mpg123_format_none(decoder) == MPG123_OK);
	FAIL_IF_FALSE(mpg123_format(decoder, rate, channels, MPG123_ENC_SIGNED_16) == MPG123_OK);

	size_t oldSize = samples.size();
	std::vector<s16> buff;
	buff.resize(mpg123_outblock(decoder));
	size_t bytesRead;
	bool done = false;
	long oldPos = ftell(file);
	fseek(file, 0, SEEK_END);
	long fileSize = ftell(file);
	fseek(file, oldPos, SEEK_SET);

	while(!done)
	{
		int err = mpg123_read(decoder, reinterpret_cast<unsigned char*>(buff.data()), buff.size() * sizeof(s16), &bytesRead);

		size_t numSamples = bytesRead / sizeof(s16);
		for(size_t i = 0; i < numSamples; ++i)
		{
			samples.push_back((float)buff[i] / (float)std::numeric_limits<s16>::max());
		}

		switch(err)
		{
			case MPG123_OK:
				break;
			case MPG123_DONE:
				done = true;
				break;
			default:
				return false;
		}

		float progress = (float)ftell(file) / (float)fileSize;
		FAIL_IF_FALSE(progressCallback(context, progress));
	}

	size_t numSamples = samples.size() - oldSize;
	soundInfo.mChannels = channels;
	soundInfo.mTotalFrames = (samples.size() - oldSize) / channels;
	soundInfo.mBitsPerSample = 32;
	soundInfo.mSampleRate = rate;
	soundInfo.mLength = (double)soundInfo.mTotalFrames / (double)rate;

	return true;
}
