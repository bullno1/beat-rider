return component(..., function()
	depends "glider.PlainRenderable"

	property("Rect",
		function(self, ent)
			return self.rect
		end,
		function(self, ent, val)
			self.rect = val
			self.deck:setRect(unpack(val))
		end
	)

	msg("onCreate", function(self, ent)
		local prop = ent:getProp()
		local deck = MOAIScriptDeck.new()
		local drawHandler = ent.onDraw
		if drawHandler then
			deck:setDrawCallback(function(...)
				return drawHandler(ent, ...)
			end)
		end
		prop:setDeck(deck)
		self.deck = deck
	end)
end)
