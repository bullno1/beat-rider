return scene(..., function()
	camera3D "RideCamera"
		Y = 50
		Z = 120
		XRotation = -10

	layer "GUI"
		sort "NONE"
	
	layer3D "Objects"
		sort "NONE"
		useCamera "RideCamera"

	entity "glider.presets.Text"
		Name = "txtProgress"
		LayerName = "GUI"
		FontName = "hermit.ttf"
		FontSize = 21
		TextRect = { 0, 0, 200, -200 }
		TextAlignment = { "top", "left" }
		Text = "Yo"
		X = -viewWidth / 2
		Y = viewHeight / 2

	entity(function()
		copyFrom "glider.presets.Mesh"
		components { "Ship" }

		LayerName = "Objects"
		Name = "Ship"
		DeckName = "mesh:spaceship.dae"
		UpdatePhase = "GameLogic"
	end)

	entity(function()
		components { "RideController" }

		UpdatePhase = "GameLogic"
	end)
end)
