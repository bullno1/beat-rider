local Asset = require "glider.Asset"

return component(..., function()
	depends "glider.PlainRenderable"
	depends "glider.Actor"

	property("SpriteName",
		function(self, ent)
			return self.spriteName
		end,
		function(self, ent, val)
			self.spriteName = val

			local sprite = Asset.get("sprite", val)
			local prop = ent:getProp()
			local anim = self.anim

			ent:setDeckName("sprite:"..val)
			prop:setIndex(1)
			anim:stop()
			anim:setLink(1, sprite.animCurve, prop, MOAIProp2D.ATTR_INDEX)
			anim:setMode(sprite.mode)
			anim:setSpeed(1 / sprite.animTime)

			if ent:getAutoPlay() then
				ent:playAnimation()
			end
		end
	)

	property "AutoPlay"

	msg("onCreate", function(self, ent)
		local anim = MOAIAnim.new()
		anim:reserveLinks(1)
		self.anim = anim
	end)

	msg("playAnimation", function(self, ent)
		ent:performAction(self.anim)
	end)

	msg("stopAnimation", function(self, ent)
		self.anim:stop()
	end)
end)
