global("assertp", function(cond, errorMsg, level)
	level = level or 2
	if not cond then
		error(errorMsg, level + 1)
	end
end)
