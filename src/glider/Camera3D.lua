return component(..., function()
	depends "glider.Transform"

	property("Camera",
		function(self, ent)
			return ent:getTransform()
		end
	)

	msg("onCreate", function(self, ent)
		ent:_requestTransformType("MOAICamera")
	end)
end)
