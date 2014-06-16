-- An eDSL for a component-based entity system

global("component", function(name, descriptor)
	local msgs = {}
	local queries = {}
	local deps = {}
	local props = {}

	local descEnv = setmetatable({}, {__index = _G})

	function descEnv.depends(name)
		table.insert(deps, name)
	end

	function descEnv.property(name, getter, setter)
		assert(props[name] == nil, "Property "..name.." already exists")
		if getter then
			setfenv(getter, _G)
		end
		if setter then
			setfenv(setter, _G)
		end

		if getter == nil and setter == nil then--simple property
			local propValue
			props[name] = {
				getter = function(self, ent) return propValue end,
				setter = function(self, ent, val) propValue = val end
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

		setfenv(handler, _G)
		msgs[name] = handler
	end

	function descEnv.query(name, handler)
		assert(queries[name] == nil, "Query handler "..name.." already exists")

		setfenv(handler, _G)
		queries[name] = handler
	end

	setfenv(descriptor, descEnv)
	descriptor()

	return {
		name = name,
		messageHandlers = msgs,
		queryHandlers = queries,
		dependencies = deps,
		properties = props
	}
end)
