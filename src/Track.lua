local Director = require "glider.Director"
local Asset = require "glider.Asset"
local Options = require "glider.Options"

return component(..., function()
	msg("onCreate", function(self, ent)
		local sceneData = Director.getSceneData()
		local sampRate = sceneData.song:getInfo()
		local trackData = sceneData.track
		local trackMesh, trackPositions = createTrackMesh(trackData, sampRate)

		ent:getProp():setDeck(trackMesh)

		self.trackPositions = trackPositions
		self.sampRate = sampRate
		self.hopSize = Options.getDevOptions().analysis.hop_size
		self.numPositions = #trackPositions
	end)

	query("getTrackTransform", function(self, ent, time)
		local sampRate = self.sampRate
		local hopSize = self.hopSize
		local hopIndex = math.clamp(math.floor(time * sampRate / hopSize + 1.5), 0, self.numPositions)
		return self.trackPositions[hopIndex]
	end)

	function createTrackMesh(trackData, sampRate)
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
		for index, y in ipairs(trackData) do
			local height = maxBumpHeight * y
			trackTransform:setLoc(trackTransform:modelToWorld(0, 0, trackStep))
			trackTransform:forceUpdate()

			local x, y, z = trackTransform:modelToWorld(0, height, 0)
			vbo:writeFloat(halfTrackWidth, y, z)
			vbo:writeFloat(-halfTrackWidth, y, z)

			table.insert(positions, {x, y, z})
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

		return trackMesh, positions
	end
end)
