local Asset = require "glider.Asset"

return function(name)
	local dataFileName = "./assets/tilesets/"..name..".lua"
	local tilesetData = assert(dofile(dataFileName), "Can't load data file for '"..name.."'")

	local sourceName = tilesetData.source
	local sourceType = tilesetData.source:split(":")[1]
	if sourceType == "texture" then
		local texture = Asset.get(sourceName)
		local deck = MOAITileDeck2D.new()
		deck:setTexture(texture)
		deck:setSize(tilesetData.width, tilesetData.height)
		return deck
	else
		return nil, "Unsupported source type for tileset: "..sourceType
	end
end
