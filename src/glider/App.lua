local Event = require "glider.Event"

return module(function()
	exports {
		"init",
		"pause",
		"resume",
		"finalize"
	}

	pause = Event.new()
	resume = Event.new()
	finalize = Event.new()

	function init()
		muxEvent(MOAISim.EVENT_FINALIZE, finalize)
		muxEvent(MOAISim.EVENT_PAUSE, pause)
		muxEvent(MOAISim.EVENT_RESUME, resume)
	end

	function muxEvent(eventId, event)
		MOAISim.setListener(eventId, function(...)
			return event:fire(...)
		end)
	end
end)
