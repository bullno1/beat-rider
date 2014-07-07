return component(..., function()
	depends "glider.Transform"

	property("Camera",
		function(self, ent)
			return ent:getTransform()
		end
	)

	local function wrapProperty(name, readOnly)
		local getterName = "get"..name
		local setterName = "set"..name

		local function getter(self, ent)
			local transform = ent:getTransform()
			return transform[getterName](transform)
		end

		local function setter(self, ent, val)
			local transform = ent:getTransform()
			return transform[setterName](transform, val)
		end

		if readOnly then
			property(name, getter)
		else
			property(name, getter, setter)
		end
	end

	wrapProperty("NearPlane")
	wrapProperty("FarPlane")
	wrapProperty("Ortho")
	wrapProperty("FieldOfView")
	wrapProperty("FocalLength", true)

	msg("onCreate", function(self, ent)
		ent:_requestTransformType("MOAICamera")
	end)
end)
