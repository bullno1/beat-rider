local Entity = require "glider.Entity"

return component(..., function()
	depends "TrackBound"
	depends "glider.Actor"

	property "TrackOffset"

	msg("onCreate", function(self, ent)
		self.rideController = Entity.getByName("RideController")
		ent:setTrackOffset(0)
	end)

	msg("update", function(self, ent)
		local pos = self.rideController:getSongPos()
		ent:setTrackPosition(pos + ent:getTrackOffset())
	end)
end)
