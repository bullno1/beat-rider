local Entity = require "glider.Entity"
local Animation = require "glider.Animation"

return component(..., function()
	depends "glider.Renderable"
	depends "glider.Actor"

	local ROT_CURVE = Animation.createCurve{
		{ 0.0,   0, MOAIEaseType.LINEAR },
		{ 0.2, -10, MOAIEaseType.LINEAR }
	}

	local ALPHA_CURVE = Animation.createCurve{
		{ 0.0, 0.9, MOAIEaseType.LINEAR },
		{ 0.1, 1.0, MOAIEaseType.LINEAR },
		{ 0.2, 0.5, MOAIEaseType.LINEAR }
	}

	local SCL_CURVE = Animation.createCurve{
		{ 0.0, 1.7, MOAIEaseType.LINEAR },
		{ 0.2, 0.1, MOAIEaseType.LINEAR }
	}

	local ANIM_SPECS = {
		{ ROT_CURVE,   MOAITransform.ATTR_Z_ROT, true },
		{ SCL_CURVE,   MOAITransform.ATTR_X_SCL },
		{ SCL_CURVE,   MOAITransform.ATTR_Y_SCL },
		{ ALPHA_CURVE, MOAIColor.ATTR_A_COL     },
	}

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(spark, self, ent)
	end)

	function spark(self, ent)
		ent:setZRotation(math.random(0, 360))

		local anim = Animation.createAnim(ent:getProp(), ANIM_SPECS)
		ent:performAction(anim)
		MOAICoroutine.blockOnAction(anim)
		Entity.destroy(ent)
	end
end)
