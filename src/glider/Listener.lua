local m = {}

function m.makeListener(name, eventTable, eventSpecs)
	return component(name, function()
		for _, eventSpec in ipairs(eventSpecs) do
			local propName, eventName, msgName = unpack(eventSpec)
			property(propName,
				function(self, ent)
					return self[eventName] ~= nil
				end,
				function(self, ent, val)
					if val and self[eventName] == nil then
						self[eventName] = eventTable[eventName]:addListener(function(...)
							ent[msgName](ent, ...)
						end)
					end
					if not val and self[eventName] ~= nil then
						eventTable[eventName]:removeListener(self[eventName])
						self[eventName] = nil
					end
				end
			)
		end

		msg("onDestroy", function(self, ent)
			for eventSpec in ipairs(eventSpecs) do
				local propName, eventName, msgName = unpack(eventSpec)
				if self[eventName] ~= nil then
					eventTable[eventName]:removeListener(self[eventName])
				end
			end
		end)
	end)
end

return m
