local Entity = require "glider.Entity"

return component(..., function()
	depends "TrackBound"
	depends "glider.Actor"

	property "Speed"
	property "TargetTrackPosition"

	msg("onCreate", function(self, ent)
		self.rideController = Entity.getByName("RideController")
		ent:setSpeed(0.3)
		ent:setTargetTrackPosition(0)
	end)

	msg("update", function(self, ent)
		local songPos = self.rideController:getSongPos()
		local speed = ent:getSpeed()
		local target = ent:getTargetTrackPosition()
		ent:setTrackPosition(target - (target - songPos) * speed)
	end)
end)
