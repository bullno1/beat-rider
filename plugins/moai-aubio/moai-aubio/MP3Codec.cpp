#include "MP3Codec.hpp"
extern "C"
{
	#include <mp3tl.h>
}
#include <limits>

gsize slurp(const char* path, const guint8** buff)
{
	FILE* file;
	file = fopen(path, "rb");
	if(file == NULL) return 0;
	fseek(file, 0, SEEK_END);
	long fileSize = ftell(file);
	rewind(file);
	void* buffer = malloc(fileSize);
	fread(buffer, 1, fileSize, file);
	*buff = (const guint8*)buffer;
	return fileSize;
}

bool decodeMP3(
	void* context,
	ProgressCallback progressCallback,
	const std::string& path,
	UNTZ::SoundInfo& soundInfo,
	std::vector<float>& samples
)
{
	const std::string extension = path.substr(path.find_last_of('.') + 1);
	if(extension != "mp3") return false;

	// Read whole file into a buffer
	const guint8* fileBuff = 0;
	gsize fileSize = slurp(path.c_str(), &fileBuff);
	// Create decoder
	std::vector<guint8> frameBuff;//temporary buffer to hold a frame
	Bit_stream_struc* bs = bs_new();
	bs_set_data(bs, fileBuff, fileSize);
	mp3tl* decoder = mp3tl_new(bs, MP3TL_MODE_16BIT);
	const fr_header* header;
	bool success = true;
	std::size_t oldSize = samples.size();
	gint offset = 0;
	gint length = 0;

	while(bs_bits_avail(bs))
	{
		mp3tl_gather_frame(decoder, &offset, &length);
		mp3tl_sync(decoder);
		mp3tl_decode_header(decoder, &header);
		size_t frameSize = header->channels * (header->sample_size >> 3) * header->frame_samples;
		frameBuff.resize(frameSize);
		Mp3TlRetcode result = mp3tl_decode_frame(decoder, frameBuff.data(), frameSize);

		if(result != MP3TL_ERR_OK)
		{
			success = false;
			break;
		}
		else
		{
			//convert 16bit integer samples to floating point samples
			const s16* frameSamples = reinterpret_cast<const s16*>(frameBuff.data());
			const size_t numSamples = frameBuff.size() / (sizeof(s16) / sizeof(guint8));
			for(size_t i = 0; i < numSamples; ++i)
			{
				samples.push_back((float)frameSamples[i] / (float)std::numeric_limits<s16>::max());
			}
		}

		float progress = (float)(bs_pos(bs) >> 3) / (float)fileSize;
		if(!progressCallback(context, progress))
		{
			success = false;
			break;
		}
	}

	soundInfo.mBitsPerSample = sizeof(float) << 3;
	soundInfo.mChannels = header->channels;
	soundInfo.mTotalFrames = (samples.size() - oldSize) / header->channels;
	soundInfo.mSampleRate = (double)header->sample_rate;
	soundInfo.mLength = (double)soundInfo.mTotalFrames / soundInfo.mSampleRate;

	mp3tl_free(decoder);
	bs_free(bs);
	free((void*)fileBuff);

	return success;
}
