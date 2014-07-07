local Xml = require "glider.Xml"
local Preset = require "glider.Preset"

return function(name)
	local path = "./assets/presets/"..name..".xml"
	local dom = assert(Xml.parseFile(path))

	for _, child in ipairs(dom.kids) do
		if child.type == "element" and child.name == "preset" then
			return Preset.parsePreset(child, path)
		end
	end

	return nil, "Invalid preset file"
end
