local Entity = require "glider.Entity"

return component(..., function()
	depends "glider.Renderable"
	depends "glider.Actor"

	local rotationCurve
	local alphaCurve
	local scaleCurve

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(spark, self, ent)
	end)

	function spark(self, ent)
		if rotationCurve == nil then
			rotationCurve = MOAIAnimCurve.new()
			rotationCurve:reserveKeys(2)
			rotationCurve:setKey(1, 0, 0, MOAIEaseType.LINEAR)
			rotationCurve:setKey(2, 0.2, -10, MOAIEaseType.LINEAR)

			alphaCurve = MOAIAnimCurve.new()
			alphaCurve:reserveKeys(3)
			alphaCurve:setKey(1, 0, 0.9, MOAIEaseType.LINEAR)
			alphaCurve:setKey(2, 0.1, 1, MOAIEaseType.LINEAR)
			alphaCurve:setKey(3, 0.2, 0.5, MOAIEaseType.LINEAR)

			scaleCurve = MOAIAnimCurve.new()
			scaleCurve:reserveKeys(3)
			scaleCurve:setKey(1, 0, 0.1, MOAIEaseType.LINEAR)
			scaleCurve:setKey(2, 0.1, 2, MOAIEaseType.LINEAR)
			scaleCurve:setKey(3, 0.2, 0.1, MOAIEaseType.LINEAR)
		end

		ent:setZRotation(math.random(0, 360))

		local anim = MOAIAnim.new()
		anim:reserveLinks(4)
		anim:setLink(1, rotationCurve, ent:getProp(), MOAITransform.ATTR_Z_ROT, true)
		anim:setLink(2, scaleCurve, ent:getProp(), MOAITransform.ATTR_X_SCL)
		anim:setLink(3, scaleCurve, ent:getProp(), MOAITransform.ATTR_Y_SCL)
		anim:setLink(4, alphaCurve, ent:getProp(), MOAIColor.ATTR_A_COL)

		ent:performAction(anim)
		MOAICoroutine.blockOnAction(anim)
		Entity.destroy(ent)
	end
end)
