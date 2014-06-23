local MessagePack = require "glider.MessagePack"
local App = require "glider.App"

return module(function()
	exports {
		"init",
		"getDevOptions"
	}

	local userOptions
	local devOptions

	function init(config)
		local developerOptionsPath = MOAIEnvironment.documentDirectory .. "/developer.options"
		local developerOptionsSchema = loadOptionSchema(config.developer)
		devOptions = loadOptions(developerOptionsSchema, developerOptionsPath)

		App.finalize:addListener(function()
			saveOptions(devOptions, developerOptionsPath)
		end)
	end

	function getDevOptions()
		return devOptions
	end

	function loadOptionSchema(moduleName)
		local path, err = package.searchpath(moduleName, package.path)
		if path == nil then
			error("Cannot find schema '"..moduleName.."'"..err)
		end

		local schemaFunc = assert(loadfile(path))

		local defaults = {}
		local schemaEnv = {}
		local schemaEnvMeta = {}
		setmetatable(schemaEnv, schemaEnvMeta)

		local groups = {}

		local groupIndex, groupNewIndex, newGroup, getGroup -- letrec

		newGroup = function(path)
			local group = setmetatable({}, {path = path, __index = groupIndex, __newindex = groupNewIndex})
			groups[path] = group
			return group
		end

		getGroup = function(path)
			return groups[path] or newGroup(path)
		end

		groupIndex = function(table, key)
			return getGroup(getmetatable(table).path .. "." .. key)
		end

		groupNewIndex = function(table, key, value)
			defaults[getmetatable(table).path .. "." .. key] = value
		end

		function schemaEnvMeta.__index(table, key)
			return getGroup(key)
		end

		function schemaEnvMeta.__newindex(table, key, value)
			defaults[key] = value
		end

		setfenv(schemaFunc, schemaEnv)
		schemaFunc()

		for groupName in pairs(groups) do
			groups[groupName] = true
		end

		return {
			defaults = defaults,
			groups = groups
		}
	end

	function loadOptions(schema, path)
		local options

		if MOAIFileSystem.checkFileExists(path) then
			local file = assert(io.open(path, "rb"))
			local fileContent = file:read("*a")
			file:close()

			local status, data = pcall(MessagePack.unpack, fileContent)

			if status then
				options = data
			else
				options = {}
			end
		else
			options = {}
		end

		return bless(options, schema)
	end

	function bless(options, schema)
		setmetatable(options, {__index = schema.defaults})--options look for missing keys in schema's defaults

		-- Build a proxy to validate all accesses to options
		local groups = {}

		local function groupIndex(group, key)
			local groupName = getmetatable(group).name
			local path = groupName.."."..key
			if schema.groups[path] ~= nil then--if this is a valid group
				return groups[path]
			elseif schema.defaults[path] ~= nil then--if this is a valid key
				return options[path]
			else
				error("Invalid group or key '"..path.."'", 2)
			end
		end

		local function groupNewIndex(group, key, value)
			local groupName = getmetatable(group).name
			local path = groupName.."."..key
			if schema.defaults[path] ~= nil then--if this is a valid key
				options[path] = value
			else
				error("Invalid key '"..path.."'", 2)
			end
		end

		local function groupToString(group)
			-- Find all keys under this group
			local prefix = getmetatable(group).name .. "."
			local matchedPaths = {}

			for path in pairs(schema.defaults) do
				if path:beginswith(prefix) then
					table.insert(matchedPaths, path)
				end
			end

			-- Build a string representation of them
			table.sort(matchedPaths)
			local buff = {}

			for i, path in ipairs(matchedPaths) do
				table.insert(buff, path)
				table.insert(buff, " = ")
				table.insert(buff, tostring(options[path]))
				table.insert(buff, "\n")
			end

			return table.concat(buff)
		end

		-- Create all groups
		for groupName in pairs(schema.groups) do
			groups[groupName] = setmetatable(
				{},
				{
					name = groupName,
					__index = groupIndex,
					__newindex = groupNewIndex,
					__tostring = groupToString
				}
			)
		end

		local proxyMetatable = {options = options}
		function proxyMetatable.__index(table, key)
			if schema.groups[key] ~= nil then--if this is a valid group name
				return groups[key]
			elseif schema.defaults[key] ~= nil then--if this is a valid key name
				return options[key]
			else
				error("Invalid group or key '"..key.."'", 2)
			end
		end

		function proxyMetatable.__newindex(table, key, value)
			if schema.defaults[key] ~= nil then--only set if this is a valid key name
				options[key] = value
			else
				error("Invalid key '"..path.."'", 2)
			end
		end

		local sortedKeys = {}
		for key in pairs(schema.defaults) do
			table.insert(sortedKeys, key)
		end
		table.sort(sortedKeys)

		function proxyMetatable.__tostring()
			local buff = {}

			for i, key in pairs(sortedKeys) do
				table.insert(buff, key)
				table.insert(buff, " = ")
				table.insert(buff, tostring(options[key]))
				table.insert(buff, "\n")
			end

			return table.concat(buff)
		end

		local proxy = {}
		setmetatable(proxy, proxyMetatable)
		return proxy
	end

	function saveOptions(options, path)
		local options = getmetatable(options).options
		local fileContent = MessagePack.pack(options)
		local file = assert(io.open(path, "w+b"))
		file:write(fileContent)
		file:close()
	end
end)
