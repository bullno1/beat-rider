return scene(..., function()
	local viewWidth, viewHeight = MOAIGfxDevice.getViewSize()
	viewport(viewWidth, viewHeight)
	viewScale(viewWidth, viewHeight)

	camera "Visualizer"

	camera3D "RideCamera"
		Z = 30

	layer "Visualizer"
		sort "NONE"
		useCamera "Visualizer"

	layer "GUI"
		sort "NONE"
	
	layer3D "Objects"
		sort "NONE"
		useCamera "RideCamera"

	entity(function()
		copyFrom"glider.presets.Mesh"
		components {"glider.Tracked"}

		Name = "Ship"
		LayerName = "Objects"
		DeckName = "mesh:spaceship.dae"

	end)
	entity(function()
		copyFrom "glider.presets.Text"
		components { "glider.Tracked" }

		Name = "txtProgress"
		LayerName = "GUI"
		FontName = "hermit.ttf"
		FontSize = 20
		TextRect = { 0, 0, 200, -200 }
		TextAlignment = { "top", "left" }
		Text = "Yo"
		X = -viewWidth / 2
		Y = viewHeight / 2
	end)

	entity(function()
		components { "RideController" }

		UpdatePhase = "GameLogic"
	end)
end)
