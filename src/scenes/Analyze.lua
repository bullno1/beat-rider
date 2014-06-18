return scene(..., function()
	local viewWidth, viewHeight = MOAIGfxDevice.getViewSize()
	viewport(viewWidth, viewHeight)
	viewScale(viewWidth, viewHeight)

	layer "GUI"
		sort "None"

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
	
	entity(function()
		components { "AnalyzeController" }
		UpdatePhase = "GameLogic"
	end)
end)
