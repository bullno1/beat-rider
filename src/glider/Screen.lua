return module(function()
	exports {
		"init",
		"getSize"
	}

	local pxWidth, pxHeight
	local dpWidth, dpHeight

	function init()
		pxWidth, pxHeight = MOAIGfxDevice.getViewSize()
		local ratio = 160 / MOAIEnvironment.screenDpi
		dpWidth, dpHeight = pxWidth * ratio, pxHeight * ratio

		print("Screen size in px:", pxWidth, pxHeight)
		print("Screen size in dp:", dpWidth, dpHeight)
	end

	function getSize(unit)
		unit = unit or "dp"
		if unit == "dp" then
			return dpWidth, dpHeight
		elseif unit == "px" then
			return  pxWidth, pxHeight
		else
			return error("Unknown unit")
		end
	end
end)
