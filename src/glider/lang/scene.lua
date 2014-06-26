local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Screen = require "glider.Screen"

global("scene", function(name, descriptor)
	return function(...)
		local currentViewport = MOAIViewport.new()
		currentViewport:setSize(Screen.getSize("px"))
		currentViewport:setScale(Screen.getSize("dp"))

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

		function dsl.layer(name)
			assertp(currentViewport ~= nil, "No viewport defined")
			currentLayer = MOAILayer2D.new()
			currentLayer:setViewport(currentViewport)
			Director.addLayer(name, currentLayer)
			return currentLayer
		end

		function dsl.layer3D(name)
			assertp(currentViewport ~= nil, "No viewport defined")
			currentLayer = MOAILayer.new()
			currentLayer:setViewport(currentViewport)
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

		function dsl.viewport(...)
			currentViewport = MOAIViewport.new()
			currentViewport:setSize(...)
		end

		function dsl.viewScale(x, y)
			currentViewport:setScale(x, y)
		end

		setfenv(descriptor, descEnv)
		return descriptor(...)
	end
end)
