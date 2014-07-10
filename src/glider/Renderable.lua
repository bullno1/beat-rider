local Director = require "glider.Director"
local Entity = require "glider.Entity"
local Asset = require "glider.Asset"

return component(..., function()
	depends "glider.Transform"

	property("Prop",
		function(self, ent)
			return ent:getTransform()
		end
	)

	property("PartitionName",
		function(self, ent)
			return self.layerName
		end,
		function(self, ent, val)
			local prop = ent:getTransform()

			local oldPartition = self.partitionName
			if oldPartition then
				Director.getPartition(oldPartition):removeProp(prop)
			end

			self.partitionName = val

			if val then
				local partition = assert(Director.getPartition(val), "Invalid partition '"..val.."'")
				partition:insertProp(prop)
			end
		end
	)

	property("DepthTest",
		function(self, ent)
			return self.depthTest
		end,
		function(self, ent, val)
			self.depthTest = val
			ent:getProp():setDepthTest(MOAIProp["DEPTH_TEST_"..val:upper()])
		end
	)

	property("CullMode",
		function(self, ent)
			return self.cullMode
		end,
		function(self, ent, val)
			self.cullMode = val
			ent:getProp():setCullMode(MOAIProp["CULL_"..val:upper()])
		end
	)

	property("ShaderName",
		function(self, ent)
			return self.shaderName
		end,
		function(self, ent, val)
			self.shaderName = val
			ent:getProp():setShader(Asset.get("shader", val))
		end
	)

	msg("onCreate", function(self, ent)
		self.depthTest = "disable"
		self.cullMode = "none"
	end)

	msg("onDestroy", function(self, ent)
		ent:setPartitionName(nil)
	end)
end)
