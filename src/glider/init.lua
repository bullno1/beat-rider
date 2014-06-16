require "glider.lang"

local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Input = require "glider.Input"
local Network = require "glider.Network"
local Event = require "glider.Event"
local Audio = require "glider.Audio"

local m = {}

m.appFinalize = Event.new()

function m.start(config)
	MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_MULTISTEP)

	config = config or {}
	Entity.initManager(config.Entity or {})
	Director.init(config.Director or {})
	Input.init(config.Input or {})
	Network.init(config.Network or {})
	Audio.init(config.Audio or {})

	local DebugLines = config.DebugLines or {}
	for lineName, visible in pairs(DebugLines) do
		MOAIDebugLines.showStyle(MOAIDebugLines[lineName], visible)
	end

	MOAISim.setListener(MOAISim.EVENT_FINALIZE, function(...)
		m.appFinalize:fire(...)
	end)

	local oldPrint = print
	local locationFormat = "%s:%s:"
	global("print", function(...)
		local info = debug.getinfo(2, "Sl")
		return oldPrint(locationFormat:format(info.source:sub(2), info.currentline), ...)
	end)
end

return m
