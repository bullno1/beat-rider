local Entity = require "glider.Entity"

return scene(..., function()
	layerGUI "GUI"

	local fileList = entity(function()
		components{"ListView"}

		Name = "FileList"
		LayerName = "GUI"
	end)

	fileList:setItemPreset(
		preset("Anon", function()
			copyFrom "glider.presets.Text"

			FontName = "hermit.ttf"
			FontSize = 20
			TextRect = { 0, 0, 40, 50 }
			TextAlignment = { "center", "center" }
		end)
	)

	for i = 1, 15 do
		fileList:addItem(i)
	end
end)
