-- An eDSL for a component-based entity system

global("component", function(name, descriptor)
	local msgs = {}
	local queries = {}
	local deps = {}
	local props = {}

	local descEnv = setmetatable({}, {__index = _G})

	function descEnv.depends(depName)
		local success, componentOrError = pcall(require, depName)
		assertp(
			success,
			"Component "..name.." specifies an unloadable dependency: "..depName.."\n"..tostring(componentOrError)
		)
		assertp(
			type(componentOrError) == "table" and rawget(componentOrError, "type") == "component",
			"Component "..name.." specifies an invalid dependency: "..depName
		)
		table.insert(deps, componentOrError)
	end

	function descEnv.property(name, getter, setter)
		assert(props[name] == nil, "Property "..name.." already exists")

		if getter == nil and setter == nil then--simple property
			local propKey = "$"..name
			props[name] = {
				getter = function(self, ent) return self[propKey] end,
				setter = function(self, ent, val) self[propKey] = val end
			}
		else
			props[name] = {
				getter = getter,
				setter = setter
			}
		end
	end

	function descEnv.msg(name, handler)
		assert(msgs[name] == nil, "Message handler "..name.." already exists")

		msgs[name] = handler
	end

	function descEnv.query(name, handler)
		assert(queries[name] == nil, "Query handler "..name.." already exists")

		queries[name] = handler
	end

	setfenv(descriptor, descEnv)
	descriptor()
	-- Disallow further modifications
	getmetatable(descEnv).__newindex = _G

	return {
		name = name,
		type = "component",
		messageHandlers = msgs,
		queryHandlers = queries,
		dependencies = deps,
		properties = props
	}
end)
