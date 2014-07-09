local Entity = require "glider.Entity"

return component(..., function()
	depends "TrackBound"
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		self.rideController = Entity.getByName("RideController")
	end)

	msg("update", function(self, ent)
		local pos = self.rideController:getSongPos()
		ent:setTrackPosition(pos)
	end)
end)
