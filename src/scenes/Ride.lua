return scene(..., function()
	local viewWidth, viewHeight = MOAIGfxDevice.getViewSize()
	viewport(viewWidth, viewHeight)
	viewScale(viewWidth, viewHeight)

	camera "Visualizer"

	camera3D "RideCamera"
		Y = 50
		Z = 120
		XRotation = -10

	layer "Visualizer"
		sort "NONE"
		useCamera "Visualizer"

	layer "GUI"
		sort "NONE"
	
	layer3D "Objects"
		sort "NONE"
		useCamera "RideCamera"

	entity "glider.presets.Text"
		Name = "txtProgress"
		LayerName = "GUI"
		FontName = "hermit.ttf"
		FontSize = 20
		TextRect = { 0, 0, 200, -200 }
		TextAlignment = { "top", "left" }
		Text = "Yo"
		X = -viewWidth / 2
		Y = viewHeight / 2

	entity "glider.presets.Mesh"
		Name = "Ship"
		LayerName = "Objects"
		DeckName = "mesh:spaceship.dae"

	entity(function()
		components { "RideController" }

		UpdatePhase = "GameLogic"
	end)
end)
