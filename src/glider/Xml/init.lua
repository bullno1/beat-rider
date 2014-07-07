local slaxml = require "glider.Xml.slaxdom"
local Asset = require "glider.Asset"

return module(function()
	exports {
		"parseFile",
		"parseString",
		"childElementsOf"
	}

	local PARSE_OPTIONS = { stripWhitespace = true }

	function parseFile(path)
		local file, err = io.open(path, "r")
		if file == nil then return file, err end

		local str = file:read("*a")
		file:close()
		return parseString(str)
	end

	function parseString(str)
		return slaxml:dom(str)
	end

	function childElementsOf(xmlNode)
		local index = 0
		local fakeIndex = 0
		local children = xmlNode.kids
		return function()
			while true do
				index = index + 1
				local elem = children[index]
				if elem ~= nil then
					if elem.type == "element" then
						fakeIndex = fakeIndex + 1
						return fakeIndex, elem
					end
				else
					return nil
				end
			end
		end
	end
end)
