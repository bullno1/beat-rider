function table.clear(table)
	for key in pairs(table) do
		table[key] = nil
	end
end

table.empty = setmetatable({}, {
	__newindex = function()
		error("Cannot modify empty table", 2)
	end
})
