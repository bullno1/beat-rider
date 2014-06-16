local Entity = require "glider.Entity"

return component(..., function()
	property("Name",
		function(self, ent)
			return self.name
		end,
		function(self, ent, val)
			if val ~= nil then
				Entity._nameEntity(ent, val)
			elseif self.name ~= nil then
				Entity._unnameEntity(self.name)
			end
			self.name = val
		end
	)

	msg("onDestroy", function(self, ent)
		ent:setName()
	end)
end)
