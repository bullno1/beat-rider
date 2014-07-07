local runtimeMetatable = {__index = _G, __newindex = _G}

local moduleMetatable = {
	__index = function(table, key)
		error("Trying to access unexported symbol '"..tostring(key).."'", 2)
	end,
	__newindex = function(table, key)
		error("Trying to add symbol '"..tostring(key).."'", 2)
	end
}

global("module", function(defFunc)
	assertp(type(defFunc) == "function", "Module must be declared with a function")

	local compileEnv = setmetatable({}, {__index = _G})

	local exportedSymbols = {}
	function compileEnv.exports(symbols)
		for i, symbol in ipairs(symbols) do
			table.insert(exportedSymbols, symbol)
		end
	end

	local moduleEnv = {}
	setmetatable(moduleEnv, {__index = compileEnv})
	setfenv(defFunc, moduleEnv)
	defFunc()
	setmetatable(moduleEnv, runtimeMetatable)

	local exports = {}

	for i, symbol in ipairs(exportedSymbols) do
		exports[symbol] = rawget(moduleEnv, symbol)
	end

	return setmetatable(exports, moduleMetatable)
end)
