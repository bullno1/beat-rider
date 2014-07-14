function math.clamp(value, lower, upper)
	return math.min(math.max(value, lower), upper)
end

function math.lerp(v1, v2, t)
	return v1 * (1 - t) + v2 * t
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
