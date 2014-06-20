local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Asset = require "glider.Asset"

return component(..., function()
	depends "glider.Actor"

	local TIME_SCALE = 1000

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(ride, self, ent)
	end)

	function ride(self, ent, path)
		local sceneData = Director.getSceneData()

		local heightScale = 200
		local aubio = sceneData.aubio
		local hopSize = aubio:getHopSize()
		local sampRate, _numFrames = aubio:getAudioInfo()
		local mesh = generateTrack(sceneData.track, sampRate, hopSize)

		local meshInstance = Entity.create("glider.presets.Mesh")
		meshInstance:getProp():setDeck(mesh)
		meshInstance:setLayerName("Objects")
		meshInstance:setYScale(heightScale)

		for i, note in ipairs(sceneData.notes) do
			local marker = Entity.create("presets.Note")
			local time = note.time
			local score = note.score

			local heightSlot = math.floor(time * sampRate / hopSize + 0.5) + 1
			marker:setX((math.random(3) - 2) * 100)
			marker:setY(sceneData.track[heightSlot] * heightScale + 20)
			marker:setZ(-time * TIME_SCALE)
			
			if not score then
				marker:getProp():setColor(0, 0, 0)
			end

			marker:getProp():setBillboard(true)
			marker:setDepthTest(MOAIProp.DEPTH_TEST_LESS)
		end

		-- Ride along the track
		aubio:play()
		local fmt = "Playing %.1f\nFPS: %.1f\nError: %.3f\nStep: %.3f"
		local camera = Director.getCamera("Visualizer")
		local pos = aubio:getPosition()
		local ship = Entity.getByName("Ship")
		local step = 0
		local halfWidth = MOAIGfxDevice.getViewSize() / 2
		local txtProgress = Entity.getByName("txtProgress")
		local rideCamera = Director.getCamera("RideCamera")
		local ship = Entity.getByName("Ship")
		rideCamera:getCamera():setAttrLink(MOAITransform.INHERIT_LOC, ship:getProp(), MOAITransform.TRANSFORM_TRAIT)
		while true do
			local position = aubio:getPosition()
			pos = pos + step
			local err = aubio:getPosition() - pos
			txtProgress:setText(fmt:format(position, MOAISim.getPerformance(), math.abs(err), step))
			local heightSlot = math.floor(pos * sampRate / hopSize + 0.5) + 1
			camera:setX(pos * TIME_SCALE + halfWidth)
			ship:setY(sceneData.track[heightSlot] * heightScale + 20)
			ship:setZ(-pos * TIME_SCALE)
			pos = pos + 0.001 * err
			step = coroutine.yield()
		end
	end

	function generateTrack(data, sampRate, hopSize)
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		vbo:reserveVerts(#data * 2)
		for index, y in ipairs(data) do
			local distance = (index  - 1) * hopSize / sampRate * TIME_SCALE

			vbo:writeFloat(200, y, -distance)
			vbo:writeFloat(-200, y, -distance)
		end
		vbo:bless()

		local track = MOAIMesh.new()
		track:setVertexBuffer(vbo)
		track:setPrimType(MOAIMesh.GL_TRIANGLE_STRIP)
		local trackTexture = Asset.get("texture:track.png")
		trackTexture:setWrap(true)
		track:setTexture(trackTexture)
		local textureHeight = select(2, trackTexture:getSize())
		local trackShader = Asset.get("shader:track")
		trackShader:setAttr(2, 1 / textureHeight / 4)
		track:setShader(trackShader)

		return track
	end
end)
