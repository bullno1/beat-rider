return function(name)
	local texture = MOAITexture.new()
	texture:load("./assets/textures/"..name)
	texture:setFilter(MOAITexture.GL_LINEAR)
	texture:setWrap(true)

	local w, h = texture:getSize() -- A size of 0 means failure
	if w * h ~= 0 then
		return texture
	else
		return nil, "Failed to load texture "..name
	end
end
