require "glider.lang"

local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Input = require "glider.Input"
local Event = require "glider.Event"
local Audio = require "glider.Audio"
local Options = require "glider.Options"
local App = require "glider.App"
local DevConsole = require "glider.DevConsole"

local m = {}

function m.start(config)
	MOAISim.clearLoopFlags()
	MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED)

	config = config or {}
	App.init()
	Entity.initManager(config.Entity or {})
	Director.init(config.Director or {})
	Input.init(config.Input or {})
	Audio.init(config.Audio or {})
	Options.init(config.Options or {})
	DevConsole.init(config.DevConsole or {})

	local DebugLines = config.DebugLines or {}
	for lineName, visible in pairs(DebugLines) do
		MOAIDebugLines.showStyle(MOAIDebugLines[lineName], visible)
	end

	local oldPrint = print
	local locationFormat = "%s:%s:"
	global("print", function(...)
		local info = debug.getinfo(2, "Sl")
		return oldPrint(locationFormat:format(info.source:sub(2), info.currentline), ...)
	end)
end

return m
