#ifndef MOAI_AUBIO_DECODER_HPP
#define MOAI_AUBIO_DECODER_HPP

class AudioStream
{
public:
	enum Status
	{
		OK,
		EOS,
		ERROR
	};

	virtual ~AudioStream() {}
	virtual double getLength() const = 0;
	virtual double getPosition() const = 0;
	virtual unsigned int getSampleRate() const = 0;
	virtual unsigned int getNumChannels() const = 0;
	virtual Status read(float* outputBuff, size_t numFrames, size_t& numFramesRead) = 0;
	virtual void close() = 0;
};

#endif
