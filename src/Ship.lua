local Input = require "glider.Input"
local Screen = require "glider.Screen"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Transform"
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(control, self, ent)
		self.lastX = 0
	end)

	msg("update", function(self, ent)
		local lastX = self.lastX
		local x = ent:getX()
		local tolerance = 0.3
		local rotTarget
		if x > lastX + tolerance then
			rotTarget = -20
		elseif x < lastX - tolerance then
			rotTarget = 20
		else
			rotTarget = 0
		end
		self.lastX = x

		local rotZ = normalizeAngle(ent:getZRotation())
		local diff = rotTarget - rotZ
		local turningRate = 3
		if math.abs(diff) < turningRate then
			ent:setZRotation(rotTarget)
		else
			ent:setZRotation(rotZ + math.sign(diff) * turningRate)
		end
	end)

	function normalizeAngle(angle)
		local angle =  angle % 360
		return angle > 180 and angle - 360 or angle
	end

	function control(self, ent)
		local motionSensor = MOAIInputMgr.device.level
		local mouseSensor = MOAIInputMgr.device.mouse

		if motionSensor then
			return motionControl(self, ent, motionSensor)
		elseif mouseSensor then
			return mouseControl(self, ent, mouseSensor)
		else
			print("Can't find any supported sensor")
		end
	end

	function motionControl(self, ent, motionSensor)
		local smoothingFactor = 0.2
		local lastSmooth = 0
		local trackWidth = Options.getDevOptions().ride.track_width
		local accuracy = 0.01

		while true do
			local x, y, z = motionSensor:getLevel()
			local y = math.clamp(y, -0.2, 0.2) / 0.2
			y = math.floor(y / accuracy + 0.5) * accuracy
			local smooth = smoothingFactor * y + (1 - smoothingFactor) * lastSmooth
			ent:setX(smooth * trackWidth / 2)
			lastSmooth = smooth
			coroutine.yield()
		end
	end

	function mouseControl(self, ent, mouseSensor)
		local halfTrackWidth = Options.getDevOptions().ride.track_width / 2
		local screenWidth = Screen.getSize("px")

		while true do
			local x, y = mouseSensor:getLoc()
			ent:setX(((x / screenWidth) * 2 - 1) * halfTrackWidth)
			coroutine.yield()
		end
	end
end)
