local Entity = require "glider.Entity"

return component(..., function()
	depends "glider.Transform"

	property("RotationMode")

	property("TrackPosition",
		function(self, ent)
			return self.trackPosition
		end,
		function(self, ent, val)
			self.trackPosition = val

			local track = Entity.getByName("Track")
			local trackTransform = self.trackTransform
			trackTransform:setLoc(track:getTrackPosition(val))

			if ent:getRotationMode() == "track" then
				trackTransform:setRot(track:getTrackOrientation(val))
			else
				trackTransform:setRot(track:getBaseOrientation(val))
			end
		end
	)

	msg("onCreate", function(self, ent)
		local entTransform = ent:getTransform()
		local trackTransform = MOAITransform.new()
		entTransform:setAttrLink(MOAITransform.INHERIT_TRANSFORM, trackTransform, MOAITransform.TRANSFORM_TRAIT)
		self.trackTransform = trackTransform

		ent:setRotationMode("track")
	end)
end)
