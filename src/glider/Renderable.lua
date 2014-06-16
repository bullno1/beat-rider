local Director = require "glider.Director"
local Entity = require "glider.Entity"

return component(..., function()
	depends "glider.Transform"

	property("Prop",
		function(self, ent)
			return ent:getTransform()
		end
	)

	property("LayerName",
		function(self, ent)
			return self.layerName
		end,
		function(self, ent, val)
			local prop = ent:getTransform()

			local oldLayer = self.layerName
			if oldLayer then
				Director.getLayer(oldLayer):removeProp(prop)
			end

			self.layerName = val

			if val then
				Director.getLayer(val):insertProp(prop)
			end
		end
	)

	property("DepthTest",
		function(self, ent)
			return self.depthTest
		end,
		function(self, ent, val)
			ent:getProp():setDepthTest(val)
		end
	)

	msg("onDestroy", function(self, ent)
		ent:setLayerName(nil)
	end)
end)
