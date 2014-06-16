return component(..., function()
	property("X",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_X_LOC)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_X_LOC, val)
		end
	)

	property("Y",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Y_LOC)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Y_LOC, val)
		end
	)

	property("Z",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Z_LOC)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Z_LOC, val)
		end
	)

	property("XScale",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_X_SCL)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_X_SCL, val)
		end
	)

	property("YScale",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Y_SCL)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Y_SCL, val)
		end
	)

	property("ZScale",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Z_SCL)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Z_SCL, val)
		end
	)

	property("XRotation",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_X_ROT)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_X_ROT, val)
		end
	)

	property("YRotation",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Y_ROT)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Y_ROT, val)
		end
	)

	property("ZRotation",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Z_ROT)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Z_ROT, val)
		end
	)

	property("Rotation",
		function(self, ent)
			return self.transform:getAttr(MOAITransform.ATTR_Z_ROT)
		end,
		function(self, ent, val)
			return self.transform:setAttr(MOAITransform.ATTR_Z_ROT, val)
		end
	)

	property("Transform",
		function(self, ent)
			return self.transform
		end
	)

	query("_requestTransformType", function(self, ent, typeName)
		if self.transformType ~= nil and self.transformType ~= typeName then
			error("Entity already has a conflicting transform of type '"..self.transformType.."'", 1)
		else
			self.transformType = typeName
			self.transform = _G[typeName].new()
			self.transform.entity = ent
		end

		return self.transform
	end)
end)
