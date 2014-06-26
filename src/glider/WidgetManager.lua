local Input = require "glider.Input"
local Director = require "glider.Director"
local Entity = require "glider.Entity"

return module(function()
	exports {
		"init",
		"_grabTouch"
	}

	local captors = {}
	local touchEvToString = {}
	touchEvToString[MOAITouchSensor.TOUCH_DOWN] = "down"
	touchEvToString[MOAITouchSensor.TOUCH_MOVE] = "move"
	touchEvToString[MOAITouchSensor.TOUCH_UP] = "up"
	touchEvToString[MOAITouchSensor.TOUCH_CANCEL] = "cancel"

	function init()
		Input.touch:addListener(onTouch)
	end

	function _grabTouch(entity, id)
		local oldCaptor = captors[id]
		if oldCaptor == nil or not Entity.isAlive(oldCaptor) then
			captors[id] = entity
		end
	end

	function onTouch(evType, id, wndX, wndY, tapCount)
		evType = touchEvToString[evType]

		local touchTarget
		local captor = captors[id]
		if captor and Entity.isAlive(captor) then
			touchTarget = captor
		else
			touchTarget = Director.pickFirstEntityAt(wndX, wndY, isEnabledWidget)
		end

		if touchTarget then
			local layer = Director.getLayer(touchTarget:getLayerName())
			local worldX, worldY = layer:wndToWorld(wndX, wndY)
			touchTarget:onTouch(evType, id, worldX, worldY, tapCount)
		end

		if evType == "up" or evType == "cancel" then
			captors[id] = nil
		end
	end

	function isEnabledWidget(entity)
		return Entity.hasComponent(entity, "glider.Widget") and entity:getEnabled()
	end
end)
