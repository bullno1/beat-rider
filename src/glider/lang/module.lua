local runtimeMetatable = {__index = _G, __newindex = _G}

global("module", function(defFunc)
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
		exports[symbol] = moduleEnv[symbol]
	end

	return exports
end)
