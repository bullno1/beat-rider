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
		if not addedComponents[component.name] then
			addedComponents[component.name] = true

			local dependencies = component.dependencies
			for _, dependencyName in ipairs(dependencies) do
				addComponent(dependencyName)
			end

			table.insert(components, component)

			local properties = component.properties

			-- Add properties
			for name, accessor in pairs(properties) do
				local getter = accessor.getter
				local setter = accessor.setter
				local getterName = "get"..name
				local setterName = "set"..name

				assert(entityProto[getterName] == nil, "Property "..name.." is already defined")
				entityProto[getterName] = function(self)
					local componentInstance = self[component.name]
					return getter(componentInstance, self)
				end

				if setter then
					assert(entityProto[setterName] == nil, "Property "..name.." is already defined")
					entityProto[setterName] = function(self, value)
						local componentInstance = self[component.name]
						return setter(componentInstance, self, value)
					end
				end
			end

			-- Add query handlers
			local queryHandlers = component.queryHandlers
			for name, handler in pairs(queryHandlers) do
				assert(entityProto[name] == nil, "Method "..name.." already exists")

				entityProto[name] = function(self, ...)
					local componentInstance = self[component.name]
					return handler(componentInstance, self, ...)
				end
			end
		end
	end

	function dsl.components(components)
		for _, component in ipairs(components) do
			addComponent(component)
		end
	end

	function dsl.copyFrom(preset)
		preset = type(preset) == "string" and require(preset) or preset
		for _, component in ipairs(preset.components) do
			addComponent(component)
		end
	end

	local shadowPresetName
	function dsl.shadowPreset(name)
		shadowPresetName = name
	end

	local syncSpecs = {}
	function dsl.sync(propertyName, syncParams)
		table.insert(
			syncSpecs,
			{
				propertyName = propertyName,
				syncParams = syncParams
			}
		)
	end

	local rpcSpecs = {}
	local rpcIds = {}
	function dsl.rpc(msgName, typedef)
		local spec = {
			msgName = msgName,
			msgType = ProtoPack.desc(typedef)
		}
		table.insert(rpcSpecs, spec)
		rpcIds[msgName] = #rpcSpecs
	end

	setfenv(descriptor, descEnv)
	descriptor()

	-- Cache synced getter and setter
	for propIndex, propSpec in ipairs(syncSpecs) do
		local propName = propSpec.propertyName
		propSpec.getter = assert(entityProto["get"..propName], "Preset "..name.." declared a non-existent property ("..propName..") to be synced")
		propSpec.setter = assert(entityProto["set"..propName], "Preset "..name.." declared a non-existent or readonly property ("..propName..") to be synced")
	end

	-- Mirror settings to shadow preset
	if shadowPresetName then
		local shadowPreset = require(shadowPresetName)

		local shadowSyncSpecs = shadowPreset.syncSpecs
		for propIndex, propSpec in ipairs(syncSpecs) do
			local propName = propSpec.propertyName
			shadowSyncSpecs[propIndex] = {
				propertyName = propSpec.propertyName,
				syncParams = propSpec.syncParams,
				getter = assert(
					shadowPreset.prototype["get"..propName],
					"Shadow preset "..shadowPresetName.." does not provide property '"..propName.."' to be synced"
				),
				setter = assert(
					shadowPreset.prototype["set"..propName],
					"Shadow preset "..shadowPresetName.." does not provide property '"..propName.."' to be synced"
				)
			}
		end

		shadowPreset.rpcSpecs = rpcSpecs
		shadowPreset.rpcIds = rpcIds
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
		shadowPreset = shadowPresetName,
		syncSpecs = syncSpecs,
		rpcSpecs = rpcSpecs,
		rpcIds = rpcIds,
		metatable = {__index = entityProto}
	}
	preset.metatable.preset = preset
	return preset
end)
