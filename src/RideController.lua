local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Asset = require "glider.Asset"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(ride, self, ent)
	end)

	function ride(self, ent)
		local rideOpts = Options.getDevOptions().ride
		local timeScale = rideOpts.time_scale
		local trackWidth = rideOpts.track_width
		local trackHeight = rideOpts.track_height

		local sceneData = Director.getSceneData()

		local txtProgress = Entity.getByName("txtProgress")
		local song = UntzSoundEx.new()
		assert(song:open(sceneData.path), "Failed to load song")
		repeat
			local status, progress = song:loadChunk(65536)
			if status == UntzSoundEx.STATUS_MORE then
				txtProgress:setText(tostring(math.floor(progress * 100)))
			end
			coroutine.yield()
		until status ~= UntzSoundEx.STATUS_MORE
		local sampRate = song:getInfo()

		local hopSize = Options.getDevOptions().analysis.hop_size
		local mesh = generateTrack(sceneData.track, sampRate, hopSize, timeScale, trackWidth)

		local track = Entity.create("glider.presets.Mesh")
		track:getProp():setDeck(mesh)
		track:setLayerName("Objects")
		track:setYScale(trackHeight)

		for i, note in ipairs(sceneData.notes) do
			local marker = Entity.create("presets.Note")
			local time, column, score = unpack(note)

			marker:setX((column - 2) * trackWidth / 3)

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
		song:play()

		local fmt = "Playing %.1f\nFPS: %.1f\nError: %.3f\nStep: %.3f"
		local camera = Director.getCamera("Visualizer")
		local pos = song:getPosition()
		local ship = Entity.getByName("Ship")
		local step = 0
		local halfWidth = MOAIGfxDevice.getViewSize() / 2
		local txtProgress = Entity.getByName("txtProgress")
		local rideCamera = Director.getCamera("RideCamera")
		local ship = Entity.getByName("Ship")
		rideCamera:getCamera():setAttrLink(MOAITransform.INHERIT_LOC, ship:getProp(), MOAITransform.TRANSFORM_TRAIT)
		while true do
			local position = song:getPosition()
			pos = pos + step
			local err = song:getPosition() - pos
			txtProgress:setText(fmt:format(position, MOAISim.getPerformance(), math.abs(err), step))
			local heightSlot = math.floor(pos * sampRate / hopSize + 0.5) + 1
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
