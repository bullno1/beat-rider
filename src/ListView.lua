local Entity = require "glider.Entity"

return component(..., function()
	depends "glider.PlainRenderable"
	depends "glider.Widget"

	property("ItemPreset",
		function(self, ent)
			return self.itemPreset
		end,
		function(self, ent, val)
			self.itemPreset = val
		end
	)

	msg("onCreate", function(self, ent)
		self.items = {}
		self.bottom = 0
		self.listHandle = MOAITransform.new()
		self.listHandle:setAttrLink(MOAITransform.INHERIT_TRANSFORM, ent:getProp(), MOAITransform.TRANSFORM_TRAIT)
	end)

	msg("addItem", function(self, ent, data)
		assertp(self.itemPreset ~= nil, "An item preset is required before adding data")

		local item = Entity.create(self.itemPreset)

		-- Link item to list
		local itemProp = item:getProp()
		local listProp = ent:getProp()
		local listHandle = self.listHandle
		itemProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, listHandle, MOAITransform.TRANSFORM_TRAIT)
		itemProp:setAttrLink(MOAIColor.INHERIT_COLOR, listProp, MOAIColor.COLOR_TRAIT)
		itemProp:setAttrLink(MOAIProp.ATTR_PARTITION, listProp, MOAIProp.ATTR_PARTITION)
		-- Position item
		local xMin, yMin, zMin, xMax, yMax, zMax = itemProp:getBounds()
		local y = self.bottom - yMin
		item:setY(y)
		self.bottom = self.bottom + (yMax - yMin)
		-- Adjust list's bounds
		local listXMin, listYMin, listZMin, listXMax, listYMax, listZMax = listProp:getBounds()
		local min, max = math.min, math.max
		listXMin, listYMin, listZMin = min(listXMin or 0, xMin), min(listYMin or 0, yMin + y), min(listZMin or 0, zMin)
		listXMax, listYMax, listZMax = max(listXMax or 0, xMax), max(listYMax or 0, yMax + y), max(listZMax or 0, zMax)
		listProp:setBounds(listXMin, listYMin, listZMin, listXMax, listYMax, listZMax)

		item:setText(tostring(data))
	end)

	msg("onTouch", function(self, ent, evType, id, x, y, tapCount)
		if evType == "down" and self.touchId == nil then
			self.touchId = id
			ent:grabTouch(id)
			self.oldTouchY = y
			self.oldY = self.listHandle:getAttr(MOAITransform.ATTR_Y_LOC)
		elseif evType == "up" then
			self.touchId = nil
		elseif evType == "move" and id == self.touchId then
			local devWidth, devHeight = MOAIGfxDevice.getViewSize()
			local scrollPos = math.clamp(self.oldY + y - self.oldTouchY, 0, -self.bottom - devHeight)
			self.listHandle:setAttr(MOAITransform.ATTR_Y_LOC, scrollPos)
		elseif evType == "cancel" then
			self.touchId = nil
		end
	end)
end)
