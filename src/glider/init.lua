require "glider.lang"

return module(function()
	exports{ "start" }

	function start(config)
		MOAISim.clearLoopFlags()
		MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED)

		config = config or {}

		local function initSubsystems(names)
			for _, name in ipairs(names) do
				initSubsystem(name, config)
			end
		end

		initSubsystems{
			"App",
			"Options",
			"Input",
			"Screen",
			"Director",
			"Entity",
			"Audio",
			"DevConsole",
			"WidgetManager"
		}

		local DebugLines = config.DebugLines or {}
		for lineName, visible in pairs(DebugLines) do
			MOAIDebugLines.showStyle(MOAIDebugLines[lineName], visible)
		end
	end

	function initSubsystem(name, config)
		print("Initializing "..name)
		local sys = require("glider."..name)
		sys.init(config[name] or {})
	end
end)
