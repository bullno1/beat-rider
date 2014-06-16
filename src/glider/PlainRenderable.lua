local Asset = require "glider.Asset"

return component(..., function()
	depends "glider.Renderable"

	property("DeckName",
		function(self, ent)
			return self.deckName
		end,
		function(self, ent, val)
			ent:getProp():setDeck(Asset.get(val))
			self.deckName = val
		end
	)

	msg("onCreate", function(self, ent)
		local prop = ent:_requestTransformType("MOAIProp")
		prop.entity = ent
	end)
end)
