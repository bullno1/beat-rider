function math.clamp(value, lower, upper)
	return math.min(math.max(value, lower), upper)
end

function math.sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	else
		return 0
	end
end
