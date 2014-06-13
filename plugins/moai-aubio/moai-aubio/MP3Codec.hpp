#ifndef MOAI_AUBIO_MP3_CODEC_HPP
#define MOAI_AUBIO_MP3_CODEC_HPP

#include <vector>
#include <string>
#include <UntzSound.h>

typedef bool (*ProgressCallback)(void* context, float progress);

bool decodeMP3(
	void* context,
	ProgressCallback progressCallback,
	const std::string& path,
	UNTZ::SoundInfo& soundInfo,
	std::vector<float>& samples
);

#endif
