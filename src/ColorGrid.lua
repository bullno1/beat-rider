return component(..., function()
	depends "glider.CustomDraw"

	msg("onDraw", function(self, ent)
		MOAIGfxDevice.setPenWidth(8)
		MOAIDraw.drawRect(10, 10, 254, 200)
		MOAIDraw.drawLine(10, 10, 254, 254)
	end)
end)
