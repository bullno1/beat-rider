return function(name)
	local fontFileName = "./assets/fonts/"..name
	assert(MOAIFileSystem.checkFileExists(fontFileName), "Can't find font file "..fontFileName)

	local font = MOAIFont.new()

	if name:endswith(".fnt") then
		font:loadFromBMFont(fontFileName)
	elseif name:endswith(".ttf") then
		font:load(fontFileName)
	else
		return nil, "Unknown font type for: "..name
	end

	return font
end
