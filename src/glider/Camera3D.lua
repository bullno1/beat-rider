local Director = require "glider.Director"

return component(..., function()
	depends "glider.Transform"

	property("Camera",
		function(self, ent)
			return ent:getTransform()
		end
	)

	property("LayerName",
		function(self, ent)
			return self.layerName
		end,
		function(self, ent, val)
			local camera = ent:getTransform()

			if val then
				Director.getLayer(val):setCamera(camera)
			end
			self.layerName = val
		end
	)

	msg("onCreate", function(self, ent)
		ent:_requestTransformType("MOAICamera")
	end)
end)
