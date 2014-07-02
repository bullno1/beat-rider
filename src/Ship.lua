return component(..., function()
	depends "glider.Transform"
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
	end)

	msg("update", function(self, ent)
		local touch = MOAIInputMgr.device.touch

		local moveDirection = fold(examineTouch, 0, touch:getActiveTouches())
		local x = math.clamp(ent:getX() + moveDirection * 7, -80, 80)
		ent:setX(x)
	end)

	function fold(func, state, item, ...)
		if item ~= nil then
			local nextState = func(state, item)
			return fold(func, nextState, ...)
		else
			return state
		end
	end

	function examineTouch(direction, touchId)
		local x, y = MOAIInputMgr.device.touch:getTouch(touchId)
		local viewWidth = MOAIGfxDevice.getViewSize()

		if x < viewWidth / 4 then
			return -1
		elseif x > viewWidth / 4 * 3 then
			return 1
		else
			return direction
		end
	end
end)
