local Event = require "glider.Event"

local m = {}

local multiplex

function m.init(config)
	local device = MOAIInputMgr.device
	if device.keyboard then
		m.keyboard = multiplex(device.keyboard)
	end
end

multiplex = function(sensor)
	local event = Event.new()
	sensor:setCallback(function(...)
		return event:fire(...)
	end)
	return event
end

return m
