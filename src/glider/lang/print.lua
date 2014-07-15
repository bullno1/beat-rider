local oldPrint = print
local locationFormat = "%s:%s:"
global("print", function(...)
	local info = debug.getinfo(2, "Sl")
	if info then
		return oldPrint(locationFormat:format(info.source:sub(2), info.currentline), ...)
	else
		return oldPrint(...)
	end
end)
