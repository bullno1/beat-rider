local glider = require "glider"

glider.start{
	Director = {
		updatePhases = {
			"GameLogic",
			"Visual"
		},
		firstScene = os.getenv("FIRST_SCENE") or "scenes.Analyze"
	},
	DebugLines = {
		PARTITION_CELLS        = false,
		PARTITION_PADDED_CELLS = false,
		PROP_MODEL_BOUNDS      = false,
		PROP_WORLD_BOUNDS      = false,
		TEXT_BOX               = true,
		TEXT_BOX_BASELINES     = true,
		TEXT_BOX_LAYOUT        = true
	}
}

--MOAIUntzSystem.initialize(44100, 1000)
--aubio = Aubio.new()
--aubio:setHopSize(1024)
--print(aubio:getHopSize())
--aubio:addSpectralDescriptor("energy")
--local start = MOAISim.getDeviceTime()
--aubio:load("assets/DontSayGoodbye.mp3")

--MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 2, 1, 1, 1 )
----MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX, 2, 1, 1, 1 )
----MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX_LAYOUT, 2, 1, 1, 1 )
----MOAIDebugLines.setStyle ( MOAIDebugLines.TEXT_BOX_BASELINES, 2, 1, 1, 1 )
--MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_WORLD_BOUNDS, 1, 0.5, 0.5, 0.5 )

--local viewport = MOAIViewport.new ()
--local devWidth, devHeight = MOAIGfxDevice.getViewSize()
--viewport:setSize(devWidth, devHeight)
--viewport:setScale(devWidth, devHeight)
--MOAIGfxDevice.getFrameBuffer():setClearDepth(true)

--local layer = MOAILayer.new ()
--layer:setViewport ( viewport )
--local overlay = MOAILayer2D.new()
--overlay:setViewport(viewport)
--MOAIRenderMgr.setRenderTable{layer, overlay}

--camera = MOAICamera.new ()
--camera:setLoc(0, 100, camera:getFocalLength(MOAIGfxDevice.getViewSize()))
--layer:setCamera(camera)

--local function makeMesh(graph)
	--local mesh = MOAIMesh.new()
	--local vbo = MOAIVertexBuffer.new()
	--local vertexFormat = MOAIVertexFormat.new ()
	--local texture = MOAITexture.new()
	--texture:load("assets/moai.png")
	--texture:setWrap(true)

	--vertexFormat:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
	--vertexFormat:declareUV(2, MOAIVertexFormat.GL_FLOAT, 2)
	--vertexFormat:declareColor(3, MOAIVertexFormat.GL_UNSIGNED_BYTE)

	--vbo:setFormat(vertexFormat)

	--local unit = 50

	--vbo:reserveVerts(#graph * 2)
	--for index, y in ipairs(graph) do
		---- position
		--vbo:writeFloat(unit, y, -index * unit)
		---- uv
		--vbo:writeFloat(1, 1 - index)
		---- color
		--vbo:writeColor32(1, 1, 1)

		---- position
		--vbo:writeFloat(-unit, y, -index * unit)
		---- uv
		--vbo:writeFloat(0, 1 - index)
		---- color
		--vbo:writeColor32(1, 1, 1)
	--end

	--vbo:bless()
	--mesh:setTexture(texture)
	--mesh:setVertexBuffer(vbo)
	--mesh:setPrimType(MOAIMesh.GL_TRIANGLE_STRIP)

	--local prop = MOAIProp.new ()
	--prop:setDeck ( mesh )
	--layer:insertProp ( prop )
	--prop:setDepthTest(MOAIProp.DEPTH_TEST_LESS)
--end

--local loader = require "mesh"
--local mesh = loader("assets/spaceship.dae")
--mesh:setTexture("./assets/HULL.jpg")
--local prop = MOAIProp.new ()
--prop:setDeck (mesh)
--layer:insertProp (prop)
--prop:setDepthTest(MOAIProp.DEPTH_TEST_LESS)

--local lastX, lastY
--local lastDistance
--local touch = MOAIInputMgr.device.touch
--MOAIInputMgr.device.touch:setCallback(function(event, id, x, y, tapCount)
	--if event == MOAITouchSensor.TOUCH_DOWN then
		--local firstTouch, secondTouch = touch:getActiveTouches()
		--if firstTouch and secondTouch then
			--local x1, y1 = touch:getTouch(firstTouch)
			--local x2, y2 = touch:getTouch(secondTouch)
			--lastDistance = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
		--end
	--elseif event == MOAITouchSensor.TOUCH_MOVE then
		--local firstTouch, secondTouch = touch:getActiveTouches()
		--if firstTouch and secondTouch then
			--local x1, y1 = touch:getTouch(firstTouch)
			--local x2, y2 = touch:getTouch(secondTouch)
			--local distance = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
			--local diff = distance - lastDistance

			--camera:setLoc(camera:modelToWorld(0, 0, -diff * 2))

			--lastDistance = distance
		--else
			--local diffX, diffY = x - lastX, y - lastY
			--camera:addRot(diffY / 10, diffX / 10, 0)
		--end
	--end
	
	--lastX, lastY = x, y
--end)

--local font = MOAIFont.new()
--font:load("assets/hermit.ttf")
--local txt = MOAITextBox.new()
--txt:setFont(font)
--txt:setTextSize(23)
--txt:setYFlip(true)
--txt:setRect(0, -100, 200, 0)
--txt:setAlignment(MOAITextBox.LEFT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY)
--txt:setString("Test")
--txt:setLoc(-devWidth / 2, devHeight / 2)
--overlay:insertProp(txt)

--print(tostring(aubio:getBeats()))
--print(tostring(aubio:getOnsets()))
--local statusToText = {
	--"Ready",
	--"Loading",
	--"Loaded",
	--"Failed"
--}
--MOAICoroutine.new():run(function()
	--repeat
		--local progress = aubio:getProgress()
		--local status = aubio:getStatus()
		--txt:setString(statusToText[status + 1].." "..tostring(math.floor(progress * 100)) .. "%")
		--if status == Aubio.STATUS_LOADED then
			--local finish = MOAISim.getDeviceTime()
			--print("Total time:", finish - start)
			--local beats = aubio:getBeats()
			--local onsets = aubio:getOnsets()
			--local energies = aubio:getSpectralDescription("energy")
			--local yolo = aubio:getSpectralDescription("yolo")
			--print(#beats)
			--print(#onsets)
			--print(#energies)
			--print(yolo)
			--makeMesh(energies)
			--aubio:play()
			--break
		--end
		--coroutine.yield()
	--until status ~= Aubio.STATUS_LOADING
--end)
