local Entity = require "glider.Entity"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Transform"
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		self.shakeX = 0
		self.ship = Entity.getByName("Ship")
		self.trackWidth = Options.getDevOptions().ride.track_width
	end)

	msg("update", function(self, ent)
		local shipX = self.ship:getX()
		ent:setX(shipX / 1.5 + self.shakeX)
	end)

	msg("shake", function(self, ent)
		ent:spawnCoroutine(shake, self)
	end)

	function shake(self)
		local shakeDuration = 0.5
		local numShakes = 7
		local shakeRadius = 8
		local numFrames = 1 / MOAISim.getStep() * shakeDuration
		for i = 1, numFrames do
			self.shakeX = math.sin(i / numFrames * math.pi * numShakes) * shakeRadius
			coroutine.yield()
		end

		self.shakeX = 0
	end
end)
