local Event = require "glider.Event"

local m = {}

local multiplex

function m.init(config)
	local device = MOAIInputMgr.device

	m.keyboard = multiplex(device.keyboard)
	m.touch = multiplex(device.touch)
end

multiplex = function(sensor)
	if sensor then
		local event = Event.new()
		sensor:setCallback(function(...)
			return event:fire(...)
		end)
		return event
	end
end

return m
