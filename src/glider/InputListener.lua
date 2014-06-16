local Input = require "glider.Input"

return component(..., function()
	property("ReceiveKeyboard",
		function(self, ent)
			return self.keyboard ~= nil
		end,
		function(self, ent, val)
			if val and self.keyboard == nil then
				self.keyboard = Input.keyboard:addListener(function(...)
					ent:onKeyboard(...)
				end)
			end
			if not val and self.keyboard ~= nil then
				Input.keyboard:removeListener(self.keyboard)
				self.keyboard = nil
			end
		end
	)

	msg("onDestroy", function(self, ent)
		if self.keyboard ~= nil then
			Input.keyboard:removeListener(self.keyboard)
		end
	end)
end)
