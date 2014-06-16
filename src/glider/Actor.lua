local Director = require "glider.Director"

return component(..., function()
	property("UpdatePhase",
		function(self, ent)
			return self.updatePhase
		end,
		function(self, ent, value)
			local action = self.action
			action:start(Director.getUpdatePhase(value))
			self.updatePhase = value
		end
	)

	local tick
	msg("onCreate", function(self, ent)
		local action = MOAIAction.new()
		action:setAutoStop(false)
		self.action = action

		if ent.update then
			local updateAction = MOAICoroutine.new()
			updateAction:run(tick, ent)
			updateAction:attach(self.action)
		end
	end)

	msg("onDestroy", function(self, ent)
		self.action:stop()
	end)

	msg("performAction", function(self, ent, action)
		action:start(self.action)
	end)

	local yield = coroutine.yield
	tick = function(ent)
		local update = ent.update
		while true do
			update(ent)
			yield()
		end
	end
end)
