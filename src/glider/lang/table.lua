function table.clear(table)
	for key in pairs(table) do
		table[key] = nil
	end
end
