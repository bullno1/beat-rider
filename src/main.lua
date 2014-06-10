MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_MODEL_BOUNDS, 2, 1, 1, 1 )
MOAIDebugLines.setStyle ( MOAIDebugLines.PROP_WORLD_BOUNDS, 1, 0.5, 0.5, 0.5 )

local viewport = MOAIViewport.new ()
local devWidth, devHeight = MOAIGfxDevice.getViewSize()
viewport:setSize(devWidth, devHeight)
viewport:setScale(devWidth, devHeight)
MOAIGfxDevice.getFrameBuffer():setClearDepth(true)

local layer = MOAILayer.new ()
layer:setViewport ( viewport )
MOAIRenderMgr.setRenderTable{layer}

camera = MOAICamera.new ()
--camera:setLoc(0, 0, camera:getFocalLength(MOAIGfxDevice.getViewSize()))
layer:setCamera(camera)

local mesh = MOAIMesh.new()
local vbo = MOAIVertexBuffer.new()
local vertexFormat = MOAIVertexFormat.new ()
local texture = MOAITexture.new()
texture:load("assets/moai.png")
texture:setWrap(true)

vertexFormat:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
vertexFormat:declareUV(2, MOAIVertexFormat.GL_FLOAT, 2)
vertexFormat:declareColor(3, MOAIVertexFormat.GL_UNSIGNED_BYTE)

vbo:setFormat(vertexFormat)
local graph = {0, 10, 30, 50, 10, 50}

local unit = 50

vbo:reserveVerts(#graph * 2)
for index, y in ipairs(graph) do
	-- position
	vbo:writeFloat(unit, y, -index * unit)
	-- uv
	vbo:writeFloat(1, 1 - index)
	-- color
	vbo:writeColor32(1, 1, 1)

	-- position
	vbo:writeFloat(-unit, y, -index * unit)
	-- uv
	vbo:writeFloat(0, 1 - index)
	-- color
	vbo:writeColor32(1, 1, 1)
end

vbo:bless()
mesh:setTexture(texture)
mesh:setVertexBuffer(vbo)
mesh:setPrimType(MOAIMesh.GL_TRIANGLE_STRIP)

local prop = MOAIProp.new ()
prop:setDeck ( mesh )
layer:insertProp ( prop )
prop:setDepthTest(MOAIProp.DEPTH_TEST_LESS)

local loader = require "mesh"
local mesh = loader("assets/spaceship.dae")
mesh:setTexture("./assets/HULL.jpg")
local prop = MOAIProp.new ()
prop:setDeck (mesh)
layer:insertProp (prop)
prop:setDepthTest(MOAIProp.DEPTH_TEST_LESS)

local lastX, lastY
local lastDistance
local touch = MOAIInputMgr.device.touch
MOAIInputMgr.device.touch:setCallback(function(event, id, x, y, tapCount)
	if event == MOAITouchSensor.TOUCH_DOWN then
		local firstTouch, secondTouch = touch:getActiveTouches()
		if firstTouch and secondTouch then
			local x1, y1 = touch:getTouch(firstTouch)
			local x2, y2 = touch:getTouch(secondTouch)
			lastDistance = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
		end
	elseif event == MOAITouchSensor.TOUCH_MOVE then
		local firstTouch, secondTouch = touch:getActiveTouches()
		if firstTouch and secondTouch then
			local x1, y1 = touch:getTouch(firstTouch)
			local x2, y2 = touch:getTouch(secondTouch)
			local distance = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
			local diff = distance - lastDistance

			camera:setLoc(camera:modelToWorld(0, 0, -diff * 2))

			lastDistance = distance
		else
			local diffX, diffY = x - lastX, y - lastY
			camera:addRot(diffY / 10, diffX / 10, 0)
		end
	end
	
	lastX, lastY = x, y
end)
