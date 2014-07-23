return module(function()
	exports {
		"createCurve",
		"createAnim"
	}

	function createCurve(keys)
		local curve = MOAIAnimCurve.new()
		curve:reserveKeys(#keys)

		for index, key in ipairs(keys) do
			curve:setKey(index, unpack(key))
		end

		return curve
	end

	function createAnim(target, links)
		local anim = MOAIAnim.new()
		anim:reserveLinks(#links)

		for index, link in ipairs(links) do
			anim:setLink(index, link[1], target, select(2, unpack(link)))
		end

		return anim
	end
end)
