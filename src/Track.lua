local Director = require "glider.Director"
local Asset = require "glider.Asset"
local Options = require "glider.Options"

return component(..., function()
	msg("onCreate", function(self, ent)
		local sceneData = Director.getSceneData()
		local sampRate = sceneData.song:getInfo()
		local trackData = sceneData.track
		local slope = sceneData.slope
		local trackMesh, trackPositions, trackRotations, baseRotations = createTrackMesh(trackData, slope, sampRate)

		ent:getProp():setDeck(trackMesh)

		local hopSize = Options.getDevOptions().analysis.hop_size
		self.trackPositionAt = toFunctionOfTime(trackPositions, sampRate, hopSize)
		self.trackOrientationAt = toFunctionOfTime(trackRotations, sampRate, hopSize)
		self.baseOrientationAt = toFunctionOfTime(baseRotations, sampRate, hopSize)
	end)

	query("getTrackPosition", function(self, ent, time)
		return unpack(self.trackPositionAt(time))
	end)

	query("getTrackOrientation", function(self, ent, time)
		return unpack(self.trackOrientationAt(time))
	end)

	query("getBaseOrientation", function(self, ent, time)
		return unpack(self.baseOrientationAt(time))
	end)

	function toFunctionOfTime(data, sampRate, hopSize)
		local numPoints = #data

		return function(time)
			local index = math.clamp(math.floor(time * sampRate / hopSize + 1.5), 0, numPoints)
			return data[index]
		end
	end

	function createTrackMesh(trackData, slope, sampRate)
		-- VBO
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		local devOpts = Options.getDevOptions()
		local opts = devOpts.ride
		local timeScale = opts.time_scale
		local halfTrackWidth = opts.track_width / 2
		local maxBumpHeight = opts.max_bump_height
		local hopSize = devOpts.analysis.hop_size

		vbo:reserveVerts(#trackData * 2)
		local trackTransform = MOAITransform.new()
		local trackStep = -hopSize / sampRate * timeScale
		local positions = {}
		local rotations = {}
		local baseRotations = {}
		for index, y in ipairs(trackData) do
			local height = maxBumpHeight * y
			local slopeFactor = slope[index] * 2 - 1
			local angle = - slopeFactor * 15

			trackTransform:setRot(angle, 0, 0)
			trackTransform:setLoc(trackTransform:modelToWorld(0, 0, trackStep - slopeFactor * 5))
			trackTransform:forceUpdate()

			local x, y, z = trackTransform:modelToWorld(0, height, 0)
			vbo:writeFloat(-halfTrackWidth, y, z)
			vbo:writeFloat(halfTrackWidth, y, z)

			if index == 1 then
				table.insert(rotations, { 0, 0, 0 })
			else
				local lastX, lastY, lastZ = unpack(positions[index - 1])
				local dx, dy, dz = x - lastX, y - lastY, z - lastZ
				local xRot = math.deg(math.atan2(dy, -dz))
				table.insert(rotations, { xRot, 0, 0 })
			end
			table.insert(baseRotations, {trackTransform:getRot()})
			table.insert(positions, { x, y, z })
		end
		vbo:bless()

		-- Mesh
		local trackMesh = MOAIMesh.new()
		trackMesh:setVertexBuffer(vbo)
		trackMesh:setPrimType(MOAIMesh.GL_TRIANGLE_STRIP)

		-- Texture
		local trackTexture = Asset.get("texture", "track.png")
		trackTexture:setWrap(true)
		trackMesh:setTexture(trackTexture)

		-- Shader
		local trackShader = Asset.get("shader", "track")
		local textureHeight = select(2, trackTexture:getSize())
		trackShader:setAttr(2, 1 / textureHeight / 4)
		trackMesh:setShader(trackShader)

		return trackMesh, positions, rotations, baseRotations
	end
end)
