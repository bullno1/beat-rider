local ProtoPack = require "glider.ProtoPack"

global("preset", function(name, descriptor)
	local defaultProps = {}
	local entityProto = {}

	local dsl = setmetatable({}, {__index = _G})
	local descEnv = setmetatable({}, {
		__newindex = function(table, key, value)
			if entityProto["set"..key] then
				defaultProps[key] = value
			else
				error("Property '"..key.."' is non-existent or readonly", 2)
			end
		end,
		__index = dsl
	})

	local components = {}
	local addedComponents = {}

	local function addComponent(component)
		component = type(component) == "string" and require(component) or component
	end

	addComponent("glider.Tracked")
	table.remove(components)

	function dsl.copyFrom(preset)
		for _, component in ipairs(preset.components) do
			addComponent(component)
		end

		for name, value in pairs(preset.defaultProps) do
			defaultProps[name] = value
		end
	end

	-- Add message handlers
	local msgHandlers = {}

	local function addMsgHandler(componentName, name, handler)
		local handlerTable = msgHandlers[name] or {}
		msgHandlers[name] = handlerTable
		table.insert(handlerTable, {
			componentName = componentName,
			handlerFunc = handler
		})
	end

	for _, component in ipairs(components) do
		local messageHandlers = component.messageHandlers
		for name, handler in pairs(messageHandlers) do
			addMsgHandler(component.name, name, handler)
		end
	end

	for msgName, handlerTable in pairs(msgHandlers) do
		entityProto[msgName] = function(self, ...)
			for _, handler in ipairs(handlerTable) do
				local componentInstance = self[handler.componentName]
				local handlerFunc = handler.handlerFunc
				handlerFunc(componentInstance, self, ...)
			end
		end
	end

	local preset = {
		name = name,
		components = components,
		defaultProps = defaultProps,
		prototype = entityProto,
		metatable = {__index = entityProto}
	}
	return preset
end)
