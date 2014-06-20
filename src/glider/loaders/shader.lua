local Asset = require "glider.Asset"

local metaPathTemplate = "./assets/shaders/%s.lua"
local vshPathTemplate = "./assets/shaders/%s.vsh"
local fshPathTemplate = "./assets/shaders/%s.fsh"

local function readFile(path)
	local file = assert(io.open(path))
	local content = file:read("*a")
	file:close()
	return content
end

return function(name)
	local metaPath = metaPathTemplate:format(name)
	local vshPath = vshPathTemplate:format(name)
	local fshPath = fshPathTemplate:format(name)

	local vsh = readFile(vshPath)
	local fsh = readFile(fshPath)
	local meta = assert(dofile(metaPath))

	local shader = MOAIShader.new()
	shader:load(vsh, fsh)

	local uniforms = meta.uniforms or {}
	shader:reserveUniforms(#uniforms)

	for index, uniformSpec in ipairs(uniforms) do
		local name, uniformTypeName, uniformValue = unpack(uniformSpec)
		local uniformType = assert(MOAIShader["UNIFORM_"..uniformTypeName], "Invalid uniform type '"..uniformTypeName.."'")
		shader:declareUniform(index, name, uniformType)

		if uniformValue
			and (uniformType == MOAIShader.UNIFORM_FLOAT
				 or uniformType == MOAIShader.UNIFORM_INT
				 or uniformType == MOAIShader.UNIFORM_SAMPLER) then

			shader:setAttr(index, uniformValue)
		end
	end

	local attributes = meta.attributes or {}
	for index, attributeName in ipairs(attributes) do
		shader:setVertexAttribute(index, attributeName)
	end

	return shader
end
