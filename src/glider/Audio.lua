local m = {}

function m.init(config)
	return MOAIUntzSystem.initialize(config.sampleRate, config.numFrames)
end

return m
