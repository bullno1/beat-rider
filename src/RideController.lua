local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Asset = require "glider.Asset"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(ride, self, ent)
	end)

	function ride(self, ent, path)
		local rideOpts = Options.getDevOptions().ride
		local timeScale = rideOpts.time_scale
		local trackWidth = rideOpts.track_width
		local trackHeight = rideOpts.track_height

		local sceneData = Director.getSceneData()

		local aubio = sceneData.aubio
		local hopSize = aubio:getHopSize()
		local sampRate, _numFrames = aubio:getAudioInfo()
		local mesh = generateTrack(sceneData.track, sampRate, hopSize, timeScale, trackWidth)

		local meshInstance = Entity.create("glider.presets.Mesh")
		meshInstance:getProp():setDeck(mesh)
		meshInstance:setLayerName("Objects")
		meshInstance:setYScale(trackHeight)

		local lastTime = 0
		local lastX = 0
		local clusterDistance = rideOpts.cluster_max_length
		local clusterLimit = rideOpts.cluster_max_size
		local currentClusterSize = 0
		for i, note in ipairs(sceneData.notes) do
			local marker = Entity.create("presets.Note")
			local time = note.time
			local score = note.score

			-- X is random with clustering
			local x
			if time - lastTime < clusterDistance and currentClusterSize < clusterLimit - 1 then
				x = lastX
				currentClusterSize = currentClusterSize + 1
			else
				x = math.random(3) - 2 --3 lanes
				currentClusterSize = 0
			end

			marker:setX(x * trackWidth / 3)
			lastX = x
			lastTime = time

			-- Y is based on track's height at that time
			local heightSlot = math.floor(time * sampRate / hopSize + 0.5) + 1
			marker:setY(sceneData.track[heightSlot] * trackHeight + rideOpts.ship_height)

			-- Z is based on time
			marker:setZ(-time * timeScale)
			
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
			--camera:setX(pos * TIME_SCALE + halfWidth)
			ship:setY(sceneData.track[heightSlot] * trackHeight + 20)
			ship:setZ(-pos * timeScale)
			pos = pos + 0.001 * err
			step = coroutine.yield()
		end
	end

	function generateTrack(data, sampRate, hopSize, timeScale, trackWidth)
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		vbo:reserveVerts(#data * 2)
		for index, y in ipairs(data) do
			local distance = (index - 1) * hopSize / sampRate * timeScale

			vbo:writeFloat(trackWidth / 2, y, -distance)
			vbo:writeFloat(-trackWidth / 2, y, -distance)
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
