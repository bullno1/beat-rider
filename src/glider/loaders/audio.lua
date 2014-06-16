return function(name)
	local audio = MOAIUntzSound.new()
	local audioPath = "./assets/sfx/"..name
	audio:load(audioPath)

	local length = audio:getLength() -- A size of 0 means failure
	if length ~= 0 then
		return audio
	else
		return nil, "Can't load audio "..name
	end
end
