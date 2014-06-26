local WidgetManger = require "glider.WidgetManager"

return component(..., function()
	depends "glider.Renderable"

	property("Enabled")

	msg("onCreate", function(self, ent)
		ent:setEnabled(true)
	end)

	msg("grabTouch", function(self, ent, id)
		WidgetManger._grabTouch(ent, id)
	end)
end)
