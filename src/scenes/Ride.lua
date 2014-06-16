return scene(..., function()
	local viewWidth, viewHeight = MOAIGfxDevice.getViewSize()
	viewport(viewWidth, viewHeight)
	viewScale(viewWidth, viewHeight)

	layer "GUI"
		sort "NONE"
	
	layer3D "Objects"
		sort "NONE"

	entity "glider.presets.Camera3D"
		LayerName = "Objects"
		Z = 30

	entity "glider.presets.Mesh"
		LayerName = "Objects"
		DeckName = "mesh:spaceship.dae"

	entity "glider.presets.Text"
		LayerName = "GUI"
		FontName = "hermit.ttf"
		FontSize = 20
		TextRect = { 0, 0, 100, -100 }
		TextAlignment = { "top", "left" }
		Text = "Yo"
		X = -viewWidth / 2
		Y = viewHeight / 2

	entity(function()
		components { "RideController" }
	end)
end)
