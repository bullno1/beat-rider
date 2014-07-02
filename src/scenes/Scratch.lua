return scene(..., function()
	layerGUI "GUI"

	entity(function()
		copyFrom "glider.presets.Sprite"
		components { "glider.Widget" }
	end)

		LayerName = "GUI"
		SpriteName = "gem#gui"
		Left = 0
		Top = 0
		Right = 20
end)
