local Director = require "glider.Director"
local Asset = require "glider.Asset"
local Options = require "glider.Options"

return component(..., function()
	msg("onCreate", function(self, ent)
		local sceneData = Director.getSceneData()
		local sampRate = sceneData.song:getInfo()
		local trackData = sceneData.track
		local slope = sceneData.slope
		local turn = sceneData.turn
		local trackMesh, trackPositions, trackRotations, baseRotations = createTrackMesh(trackData, slope, turn, sampRate)

		ent:getProp():setDeck(trackMesh)

		local hopSize = Options.getDevOptions().analysis.hop_size
		self.trackPositionAt = toFunctionOfTime(trackPositions, sampRate, hopSize)
		self.trackOrientationAt = toFunctionOfTime(trackRotations, sampRate, hopSize)
		self.baseOrientationAt = toFunctionOfTime(baseRotations, sampRate, hopSize)
	end)

	query("getTrackPosition", function(self, ent, time)
		return self.trackPositionAt(time)
	end)

	query("getTrackOrientation", function(self, ent, time)
		return self.trackOrientationAt(time)
	end)

	query("getBaseOrientation", function(self, ent, time)
		return self.baseOrientationAt(time)
	end)

	function toFunctionOfTime(data, sampRate, hopSize)
		local numPoints = #data
		local temp = {}

		return function(time)
			local index = time * sampRate / hopSize + 1
			local leftIndex = math.clamp(math.floor(index), 1, numPoints)
			local rightIndex = math.clamp(math.ceil(index), 1, numPoints)
			local left = data[leftIndex]
			local right = data[rightIndex]
			for i = 1, #left do
				temp[i] = math.lerp(left[i], right[i], index - leftIndex)
			end
			return unpack(temp)
		end
	end

	function createTrackMesh(trackData, slope, turn, sampRate)
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
		for i, slope in ipairs(slope) do
			if slope < lastSlope then -- is this a drop?
				if dropDuration == 0 then
					dropStartTime = i
					dropStartSlope = slope
				end
				dropDuration = dropDuration + 1
			else
				if dropDuration > 100 and dropStartSlope - slope > 0.02 then
					-- Make the track turn for the duration of the drop
					for j = dropStartTime, i do
						angles[j] = currentAngle
						currentAngle = currentAngle + 0.2 * turnDir
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

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		local devOpts = Options.getDevOptions()
		local opts = devOpts.ride
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
		for index, y in ipairs(trackData) do
			local height = maxBumpHeight * y
			local slopeFactor = slope[index] * 2 - 1 -- From [0, 1] to [-1, 1]

			local xAngle = - slopeFactor * maxElevation
			trackTransform:setRot(xAngle, angles[index], 0)

			local step = trackStep + slopeFactor * maxSpeedVariation * trackStep
			trackTransform:setLoc(trackTransform:modelToWorld(0, 0, step))
			trackTransform:forceUpdate()

			local x, y, z = trackTransform:modelToWorld(0, height, 0)
			local v = distance * distanceToTexCoord
			vbo:writeFloat(trackTransform:modelToWorld(-halfTrackWidth, height, 0))
			vbo:writeFloat(0, v)
			vbo:writeFloat(trackTransform:modelToWorld(halfTrackWidth, height, 0))
			vbo:writeFloat(1, v)

			distance = distance + step

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
		trackMesh:setShader(trackShader)
		trackMesh:setTexture(trackTexture)

		return trackMesh, positions, rotations, baseRotations
	end
end)
