local Entity = require "glider.Entity"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Transform"
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		self.ship = Entity.getByName("Ship")
		self.trackWidth = Options.getDevOptions().ride.track_width
	end)

	msg("update", function(self, ent)
		local shipX = self.ship:getX()
		ent:setX(shipX / 1.5)
	end)
end)
