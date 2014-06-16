local lockTable = {
	__index = function(table, key)
		error("Invalid enum "..tostring(key), 2)
	end,
	__newindex = function(table, key, value)
		error("Cannot add enum "..tostring(key), 2)
	end
}

global("enum", function(codeToName)
	local result = {}
	for index, name in ipairs(codeToName) do
		result[name] = index
	end

	function result.tostring(code)
		return codeToName[code]
	end

	return setmetatable(result, lockTable)
end)
