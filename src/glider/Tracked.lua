local Entity = require "glider.Entity"

return component(..., function()
	property("Name",
		function(self, ent)
			return Entity._getName(ent)
		end,
		function(self, ent, val)
			return Entity._setName(ent, val)
		end
	)

	msg("onDestroy", function(self, ent)
		Entity._setName(ent, nil)
	end)
end)
