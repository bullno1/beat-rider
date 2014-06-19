-- Protect global environment

-- Global variables must be explicitly declared
function global(name, value)
	if value == nil then
		error("Cannot set a nil global variable", 2)
	end
	rawset(_G, name, value)
end

-- Forbid all implicit modifications
setmetatable(_G, {
	__index = function(table, index)
		error("Trying to access non-existent global variable '" .. index.."'", 2)
	end,
	__newindex = function(table, index)
		error("Cannot implicitly create global variable '"..index.."'", 2)
	end
})
