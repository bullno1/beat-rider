-- String utilities

-- Check if a string begins with a prefix
function string.beginswith(string, prefix)
	return string.sub(string, 1, string.len(prefix)) == prefix
end

-- Check if a string ends with a suffix
function string.endswith(string, suffix)
	return suffix == '' or string.sub(string, -string.len(suffix)) == suffix
end

local strfind = string.find
local strsub = string.sub
local tinsert = table.insert
-- Split a string using a separator (which can be a pattern)
function string.split(string, separator)
	local list = {}
	local pos = 1
	if strfind("", separator, 1) then -- this would result in endless loops
		error("separator matches empty string!")
	end
	while 1 do
		local first, last = strfind(string, separator, pos)
		if first then -- found?
			tinsert(list, strsub(string, pos, first-1))
			pos = last+1
		else
			tinsert(list, strsub(string, pos))
			break
		end
	end
	return list
end
