local Entity = require "glider.Entity"

return component(..., function()
	depends "glider.Transform"

	property("TrackPosition",
		function(self, ent)
			return self.trackPosition
		end,
		function(self, ent, val)
			self.trackPosition = val

			local track = Entity.getByName("Track")
			local location, rotation = track:getTrackTransform(val)
			self.trackTransform:setLoc(unpack(location))
		end
	)

	msg("onCreate", function(self, ent)
		local entTransform = ent:getTransform()
		local trackTransform = MOAITransform.new()
		entTransform:setAttrLink(MOAITransform.INHERIT_TRANSFORM, trackTransform, MOAITransform.TRANSFORM_TRAIT)
		self.trackTransform = trackTransform
	end)
end)
