local Xml = require "glider.Xml"
local SceneXml = require "glider.SceneXml"

return function(name)
	local path = "./assets/scenes/"..name..".xml"
	local dom = assert(Xml.parseFile(path))

	for _, child in ipairs(dom.kids) do
		if child.type == "element" and child.name == "scene" then
			return SceneXml.parse(child, path)
		end
	end

	return nil, "Invalid scene file"
end
