local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Screen = require "glider.Screen"

global("scene", function(name, descriptor)
	return function(...)
		local defaultViewport = MOAIViewport.new()
		defaultViewport:setSize(Screen.getSize("px"))
		defaultViewport:setScale(Screen.getSize("dp"))

		local guiViewport = MOAIViewport.new()
		guiViewport:setSize(Screen.getSize("px"))
		local w, h = Screen.getSize("dp")
		guiViewport:setScale(w, -h)
		guiViewport:setOffset(-1, 1)

		local currentLayer
		local currentEntity

		local dsl = setmetatable({}, {__index = _G})
		local descEnv = setmetatable({}, {
			__index = dsl,
			__metatable = 0,
			__newindex = function(table, key, value)
				assertp(currentEntity ~= nil, "No entity to set property")
				assertp(currentEntity["set"..key] ~= nil, "Property '"..key.."' is non-existent or readonly")
				return currentEntity["set"..key](currentEntity, value)
			end
		})

		function dsl.camera(name)
			local camera = dsl.entity("glider.presets.Camera")
			Director.addCamera(name, camera)
		end

		function dsl.camera3D(name)
			local camera = dsl.entity("glider.presets.Camera3D")
			Director.addCamera(name, camera)
			return camera
		end

		function dsl.layerGUI(name)
			currentLayer = MOAILayer2D.new()
			currentLayer:setViewport(guiViewport)
			Director.addLayer(name, currentLayer)
			return currentLayer
		end

		function dsl.layer(name)
			currentLayer = MOAILayer2D.new()
			currentLayer:setViewport(defaultViewport)
			Director.addLayer(name, currentLayer)
			return currentLayer
		end

		function dsl.layer3D(name)
			currentLayer = MOAILayer.new()
			currentLayer:setViewport(defaultViewport)
			Director.addLayer(name, currentLayer)
			MOAIGfxDevice.getFrameBuffer():setClearDepth(true)
			return currentLayer
		end

		function dsl.useCamera(name)
			assertp(currentLayer ~= nil, "No layer defined")
			local camera = Director.getCamera(name)
			assertp(camera ~= nil, "Camera does not exists")
			currentLayer:setCamera(camera:getCamera())
		end

		function dsl.sort(sortMode)
			currentLayer:setSortMode(MOAILayer2D["SORT_"..sortMode])
		end

		function dsl.entity(preset)
			currentEntity = Entity.create(preset)
			return currentEntity
		end

		setfenv(descriptor, descEnv)
		return descriptor(...)
	end
end)
