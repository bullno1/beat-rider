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
		self.distanceAt = toScalarFunctionOfTime(distances, sampRate, hopSize)
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

	msg("update", function(self, ent)
		local rideController = Entity.getByName("RideController")
		local distance = self.distanceAt(rideController:getSongPos())
		self.shader:setAttr(2, distance)
	end)

	function toFunctionOfTime(data, sampRate, hopSize)
		local numPoints = #data
		local temp = {}
		local floor = math.floor
		local ceil = math.ceil
		local lerp = math.lerp
		local clamp = math.clamp

		return function(time)
			local index = time * sampRate / hopSize + 1
			local leftIndex = clamp(floor(index), 1, numPoints)
			local rightIndex = clamp(ceil(index), 1, numPoints)
			local left = data[leftIndex]
			local right = data[rightIndex]
			local blend = index - leftIndex
			-- Unroll loop
			local x = lerp(left[1], right[1], blend)
			local y = lerp(left[2], right[2], blend)
			local z = lerp(left[3], right[3], blend)
			return x, y, z
		end
	end

	function toScalarFunctionOfTime(data, sampRate, hopSize)
		local numPoints = #data
		local temp = {}
		local floor = math.floor
		local ceil = math.ceil
		local lerp = math.lerp
		local clamp = math.clamp

		return function(time)
			local index = time * sampRate / hopSize + 1
			local leftIndex = clamp(floor(index), 1, numPoints)
			local rightIndex = clamp(ceil(index), 1, numPoints)
			local left = data[leftIndex]
			local right = data[rightIndex]
			local blend = index - leftIndex

			return lerp(left, right, blend)
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
		format:declareAttribute(3, MOAIVertexFormat.GL_FLOAT, 1)

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
		local distances = {}
		for index, y in ipairs(trackData) do
			local height = maxBumpHeight * y
			local slopeFactor = slope[index] * 2 - 1 -- From [0, 1] to [-1, 1]

			local xAngle = - slopeFactor * maxElevation
			trackTransform:setRot(xAngle, angles[index], 0)

			local step = trackStep + slopeFactor * maxSpeedVariation * trackStep
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

			distance = distance + step
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
		local moaiTexture = Asset.get("texture", "moai.png")
		moaiTexture:setWrap(true)
		multiTexture:setTexture(2, moaiTexture)
		trackMesh:setShader(trackShader)
		trackMesh:setTexture(multiTexture)

		return trackMesh, trackShader, distances, positions, rotations, baseRotations
	end
end)
