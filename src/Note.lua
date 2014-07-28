local Entity = require "glider.Entity"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Renderable"

	property("Colored",
		function(self, ent)
			return self.colored
		end,
		function(self, ent, val)
			self.colored = val

			local prop = ent:getProp()
			if val then
				prop:setColor(0.2, 0.8, 0.6)
			else
				prop:setColor(0.2, 0.2, 0.2)
			end
		end
	)

	property("Lane",
		function(self, ent)
			return self.lane
		end,
		function(self, ent, val)
			local trackWidth = Options.getDevOptions().ride.track_width
			self.lane = val
			ent:setX((val - 2) * trackWidth / 3)
		end
	)

	property("Primary",
		function(self, ent)
			return self.primary
		end,
		function(self, ent, val)
			self.primary = val
			ent:setXScale(val and 1 or 0.2)
			ent:setYScale(val and 1 or 0.2)
			ent:setZScale(val and 1 or 0.2)
			ent:setY(val and 0 or 5)
		end
	)
end)
