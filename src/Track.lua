local Director = require "glider.Director"
local Entity = require "glider.Entity"
local Asset = require "glider.Asset"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		local sceneData = Director.getSceneData()
		local sampRate = sceneData.song:getInfo()
		local trackData = sceneData.track
		local slope = sceneData.slope
		local turn = sceneData.turn
		local trackMesh, trackShader, distances, trackPositions, trackRotations, baseRotations =
			createTrackMesh(trackData, slope, turn, sampRate)

		ent:getProp():setDeck(trackMesh)

		local hopSize = Options.getDevOptions().analysis.hop_size
		self.shader = trackShader
		self.distanceCurve = toCurve(distances, sampRate, hopSize)
		self.timeCurve = toInvCurve(distances, sampRate, hopSize)
		self.positionCurve = toVectorCurve(trackPositions, sampRate, hopSize)
		self.orientationCurve = toVectorCurve(trackRotations, sampRate, hopSize)
		self.baseOrientationCurve = toVectorCurve(baseRotations, sampRate, hopSize)
	end)

	query("getDistance", function(self, ent, time)
		return self.distanceCurve:getValueAtTime(time)
	end)

	query("getTrackPosition", function(self, ent, time)
		return self.positionCurve:getValueAtTime(time)
	end)

	query("getTrackOrientation", function(self, ent, time)
		return self.orientationCurve:getValueAtTime(time)
	end)

	query("getBaseOrientation", function(self, ent, time)
		return self.baseOrientationCurve:getValueAtTime(time)
	end)

	query("distanceToTime", function(self, ent, distance)
		return self.timeCurve:getValueAtTime(distance)
	end)

	msg("update", function(self, ent)
		local rideController = Entity.getByName("RideController")
		local distance = ent:getDistance(rideController:getSongPos())
		self.shader:setAttr(2, distance)
	end)

	function toVectorCurve(data, sampRate, hopSize)
		local curve = MOAIAnimCurveVec.new()
		curve:reserveKeys(#data)

		for index, point in ipairs(data) do
			curve:setKey(index, index * hopSize / sampRate, point[1], point[2], point[3], MOAIEaseType.LINEAR)
		end

		return curve
	end

	function toCurve(data, sampRate, hopSize)
		local curve = MOAIAnimCurve.new()
		curve:reserveKeys(#data)

		for index, point in ipairs(data) do
			curve:setKey(index, index * hopSize / sampRate, point, MOAIEaseType.LINEAR)
		end

		return curve
	end

	function toInvCurve(data, sampRate, hopSize)
		local curve = MOAIAnimCurve.new()
		curve:reserveKeys(#data)

		for index, point in ipairs(data) do
			curve:setKey(index, point, index * hopSize / sampRate, MOAIEaseType.LINEAR)
		end

		return curve
	end

	function createTrackMesh(trackData, slope, turn, sampRate)
		local devOpts = Options.getDevOptions()
		local opts = devOpts.ride

		-- Identify descending parts of the slope to make turns
		local angles = {}
		local numPoints = #trackData
		for i = 1, numPoints do
			angles[i] = 0
		end

		local currentAngle = 0
		local lastSlope = slope[1]
		local dropDuration = 0
		local dropStartTime = 0
		local dropStartSlope = 0
		local turnDir = 1
		local minDropDuration = opts.turn.min_drop_duration
		local minDropSlope = opts.turn.min_drop_slope
		local turningSpeed = opts.turn.speed

		for i, slope in ipairs(slope) do
			if slope < lastSlope then -- is this a drop?
				if dropDuration == 0 then
					dropStartTime = i
					dropStartSlope = slope
				end
				dropDuration = dropDuration + 1
			else
				if dropDuration > minDropDuration and dropStartSlope - slope > minDropSlope then
					-- Make the track turn for the duration of the drop
					for j = dropStartTime, i do
						angles[j] = currentAngle
						currentAngle = currentAngle + turningSpeed * turnDir
					end
					for j = i + 1, numPoints do
						angles[j] = currentAngle
					end
					turnDir = -turnDir
				end
				dropDuration = 0
			end

			lastSlope = slope
		end

		-- Load texture first to compute UV based on its size
		local trackTexture = Asset.get("texture", "track.png")
		trackTexture:setWrap(true)
		local textureHeight = select(2, trackTexture:getSize())
		local distanceToTexCoord = 1 / textureHeight / 4

		-- VBO
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
		format:declareUV(2, MOAIVertexFormat.GL_FLOAT, 2)
		format:declareAttribute(3, MOAIVertexFormat.GL_FLOAT, 1)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		local timeScale = opts.time_scale
		local halfTrackWidth = opts.track_width / 2
		local maxBumpHeight = opts.max_bump_height
		local hopSize = devOpts.analysis.hop_size
		local maxElevation = opts.max_elevation
		local maxSpeedVariation = opts.max_speed_variation

		vbo:reserveVerts(#trackData * 2)
		local trackTransform = MOAITransform.new()
		local trackStep = -hopSize / sampRate * timeScale
		local positions = {}
		local rotations = {}
		local baseRotations = {}
		local distance = 0
		local distances = {}
		for index, y in ipairs(trackData) do
			local height = maxBumpHeight * y
			local slopeFactor = slope[index] * 2 - 1 -- From [0, 1] to [-1, 1]

			local xAngle = - slopeFactor * maxElevation
			trackTransform:setRot(xAngle, angles[index], 0)

			local step = trackStep + slopeFactor * maxSpeedVariation * trackStep
			distance = distance + step
			trackTransform:setLoc(trackTransform:modelToWorld(0, 0, step))
			trackTransform:forceUpdate()

			local x, y, z = trackTransform:modelToWorld(0, height, 0)
			local v = distance * distanceToTexCoord % 1.0
			-- Left
			vbo:writeFloat(trackTransform:modelToWorld(-halfTrackWidth, height, 0))
			vbo:writeFloat(0, v)
			vbo:writeFloat(-distance)
			-- Right
			vbo:writeFloat(trackTransform:modelToWorld(halfTrackWidth, height, 0))
			vbo:writeFloat(1, v)
			vbo:writeFloat(-distance)

			table.insert(distances, -distance)

			if index == 1 then
				table.insert(rotations, { 0, 0, 0 })
			else
				local lastX, lastY, lastZ = unpack(positions[index - 1])
				local dx, dy, dz = x - lastX, y - lastY, z - lastZ
				local zl = math.sqrt(dx * dx + dz * dz)
				local xRot = math.deg(math.atan2(dy, zl))
				table.insert(rotations, { xRot, angles[index], 0 })
			end
			table.insert(baseRotations, {trackTransform:getRot()})
			table.insert(positions, { x, y, z })
		end
		vbo:bless()

		-- Create mesh
		local trackMesh = MOAIMesh.new()
		trackMesh:setVertexBuffer(vbo)
		trackMesh:setPrimType(MOAIMesh.GL_TRIANGLE_STRIP)

		-- Set shader and texture
		local trackShader = Asset.get("shader", "track")
		local multiTexture = MOAIMultiTexture.new()
		multiTexture:reserve(2)
		multiTexture:setTexture(1, trackTexture)
		local gridTexture = Asset.get("rt-texture", "grid")
		gridTexture:setFilter(MOAITexture.GL_LINEAR)
		multiTexture:setTexture(2, gridTexture)
		trackMesh:setShader(trackShader)
		trackMesh:setTexture(multiTexture)

		return trackMesh, trackShader, distances, positions, rotations, baseRotations
	end
end)
