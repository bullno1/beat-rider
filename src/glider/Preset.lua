local Xml = require "glider.Xml"
local childElementsOf = Xml.childElementsOf
local Tracked = require "glider.Tracked"
local Asset = require "glider.Asset"

return module(function()
	exports {
		"create",
		"parsePreset",
		"parseProperties"
	}

	function create(componentSpecs, defaultProperties)
		local components = {}
		local addedComponents = {}
		local propertyTable = {}
		local entityProto = {}

		-- Add all components and presets
		for specIndex, componentSpec in ipairs(componentSpecs) do
			if componentSpec.type == "component" then
				addComponent(entityProto, componentSpec, components, addedComponents)
			elseif componentSpec.type == "preset" then
				-- Add all components in this preset
				for componentIndex, component in ipairs(componentSpec.components) do
					addComponent(entityProto, component, components, addedComponents)
				end

				-- Copy all default properties
				for propertyIndex, propertyKV in ipairs(componentSpec.defaultProperties) do
					setProperty(propertyTable, unpack(propertyKV))
				end
			else
				error("Invalid data at index: "..specIndex)
			end
		end

		-- Make all entities trackable
		addComponent(entityProto, Tracked, components, addedComponents)
		table.remove(components)

		-- Add message handlers
		local msgHandlers = {}
		for componentIndex, component in ipairs(components) do
			local messageHandlers = component.messageHandlers

			for handlerName, handler in pairs(messageHandlers) do
				local handlerTable = msgHandlers[handlerName] or {}
				msgHandlers[handlerName] = handlerTable
				table.insert(handlerTable, { component.name, handler })
			end
		end

		for msgName, handlerTable in pairs(msgHandlers) do
			entityProto[msgName] = function(self, ...)
				for _, handler in ipairs(handlerTable) do
					local componentName, handlerFunc = unpack(handler)
					local componentInstance = self[componentName]
					handlerFunc(componentInstance, self, ...)
				end
			end
		end

		-- Override other presets' properties
		for propIndex, propKV in ipairs(defaultProperties) do
			local name, value = unpack(propKV)
			if entityProto["set"..name] then
				setProperty(propertyTable, name, value)
			else
				error("Property '"..key.."' is non-existent or readonly")
			end
		end

		return {
			type = "preset",
			components = components,
			prototype = entityProto,
			defaultProperties = propertyTable,
			metatable = { __index = entityProto }
		}
	end

	function addComponent(entityProto, component, componentList, addedComponents)
		local componentName = component.name
		if not addedComponents[componentName] then
			addedComponents[componentName] = true

			local dependencies = component.dependencies
			for _, dependency in ipairs(dependencies) do
				addComponent(entityProto, dependency, componentList, addedComponents)
			end

			table.insert(componentList, component)

			local properties = component.properties

			-- Add properties
			for name, accessor in pairs(properties) do
				local getter = accessor.getter
				local setter = accessor.setter
				local getterName = "get"..name
				local setterName = "set"..name

				assert(entityProto[getterName] == nil, "Property "..name.." is already defined")
				entityProto[getterName] = function(self)
					local componentInstance = self[componentName]
					return getter(componentInstance, self)
				end

				if setter then
					assert(entityProto[setterName] == nil, "Property "..name.." is already defined")
					entityProto[setterName] = function(self, value)
						local componentInstance = self[componentName]
						return setter(componentInstance, self, value)
					end
				end
			end

			-- Add query handlers
			local queryHandlers = component.queryHandlers
			for name, handler in pairs(queryHandlers) do
				assert(entityProto[name] == nil, "Method "..name.." already exists")

				entityProto[name] = function(self, ...)
					local componentInstance = self[componentName]
					return handler(componentInstance, self, ...)
				end
			end
		end
	end


	function parsePreset(presetXml, context)
		context = context or ""
		local components, properties

		for elemIndex, elem in childElementsOf(presetXml) do
			if elem.name == "components" then
				components = parseComponents(elem, context.."/components")
			elseif elem.name == "properties" then
				properties = parseProperties(elem, context.."/properties")
			end
		end

		assert(components ~= nil and #components ~= 0, "Preset does not specify any components\nContext: "..context)

		return create(components, properties or {})
	end

	function parseComponents(componentsXml, context)
		local components = {}

		for elemIndex, elem in childElementsOf(componentsXml) do
			local context = context.."["..elemIndex.."]"

			if elem.name == "component" then
				local componentName = elem.attr.name
				local success, componentOrError = pcall(require, componentName)
				local errorTag = "\n".."Component: '"..componentName.."'\nContext: "..context
				assert(
					success,
					tostring(componentOrError)..errorTag
				)
				assert(
					type(componentOrError) == "table" and rawget(componentOrError, "type") == "component",
					"Invalid component "..errorTag
				)
				table.insert(components, componentOrError)
			elseif elem.name == "preset" then
				local presetName = elem.attr.name
				local success, presetOrError = pcall(Asset.get, "preset", presetName)
				local errorTag = "\n".."Preset: '"..presetName.."'\nContext: "..context
				assert(
					success,
					tostring(presetOrError)..errorTag
				)
				assert(
					type(presetOrError) == "table" and rawget(presetOrError, "type") == "preset",
					"Invalid preset "..errorTag
				)
				table.insert(components, presetOrError)
			end
		end

		return components
	end

	function parseProperties(propertiesXml, context)
		context = context or ""
		local properties = {}

		for elemIndex, elem in childElementsOf(propertiesXml) do
			local context = context.."["..elemIndex.."]"
			local propName = assert(elem.attr.name, "Unnamed property\nContext:"..context)
			local context = context.."/"..propName.."("..elemIndex..")"
			if elem.name == "string" then
				setProperty(properties, propName, getString(elem, context..":string"))
			elseif elem.name == "number" then
				setProperty(properties, propName, getNumber(elem, context..":number"))
			elseif elem.name == "list" then
				setProperty(properties, propName, getList(elem, context..":list"))
			elseif elem.name == "boolean" then
				setProperty(properties, propName, getBoolean(elem, context..":boolean"))
			end
		end

		return properties
	end

	function setProperty(propTable, name, value)
		for i, prop in ipairs(propTable) do
			local k, v = unpack(prop)
			if k == name then
				prop[k] = value
				return
			end
		end

		table.insert(propTable, {name, value})
	end

	function getString(elem)
		for childIndex, childXml in ipairs(elem.kids) do
			if childXml.type == "text" and #childXml.value > 0 then
				return childXml.value
			end
		end

		return ""
	end

	function getNumber(elem, context)
		local str = getString(elem, context)
		return assert(tonumber(str), context..": Invalid number '"..str.."'")
	end

	local listEnv = setmetatable({}, {
		__index = function(tab, key) return tostring(key) end,
		__newindex = function(tab, key, val) end
	})

	function getList(elem, context)
		local str = getString(elem, context)
		local listCode = "return { "..str.." }"
		local listFunc = assert(load(listCode), context..": Invalid list '"..str.."'")
		setfenv(listFunc, listEnv)
		local success, listOrErr = pcall(listFunc)
		if not success then
			error(context..": Invalid list '"..str.."' ("..listOrErr..")")
		else
			return listOrErr
		end
	end

	function getBoolean(elem, context)
		local str = getString(elem, context)
		return str == "true"
	end
end)
