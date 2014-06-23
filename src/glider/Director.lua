local Entity = require "glider.Entity"

return module(function()
	exports {
		"init",
		"changeScene",
		"getSceneData",
		"getUpdatePhase",
		"addLayer",
		"getLayer",
		"addCamera",
		"getCamera"
	}

	local updatePhases = {}
	local renderTable = {}
	local layerMap = {}
	local cameras = setmetatable({}, {__mode='v'})

	function init(config)
		local updatePhaseNames = config.updatePhases or {}
		for _, name in ipairs(updatePhaseNames) do
			local phase = MOAIAction.new()
			phase:setAutoStop(false)
			phase:start()

			updatePhases[name] = phase
		end

		local yield = coroutine.yield
		MOAICoroutine.new():run(changeSceneIfNeeded)

		MOAIRenderMgr.setRenderTable(renderTable)

		if config.firstScene then
			changeScene(config.firstScene)
		end
	end

	local nextScene
	local sceneParams

	function changeScene(sceneName, ...)
		nextScene = sceneName
		sceneParams = {...}
	end

	function getSceneData()
		return unpack(sceneParams)
	end

	function getUpdatePhase(name)
		return updatePhases[name]
	end

	function addLayer(name, layer)
		assert(layerMap[name] == nil, "Layer "..name.." is already defined")

		table.insert(renderTable, 1, layer)
		layerMap[name] = layer
	end

	function getLayer(name)
		return layerMap[name]
	end

	function addCamera(name, camera)
		cameras[name] = camera
	end

	function getCamera(name)
		return cameras[name]
	end

	-- Private
	local yield = coroutine.yield
	function changeSceneIfNeeded()
		while true do
			if nextScene ~= nil then
				Entity.destroyAll()
				Entity.cleanupEntities()

				print("Changing to scene '"..nextScene.."'")
				-- Stop all actions
				for _, phase in pairs(updatePhases) do
					phase:clear()
				end

				table.clear(renderTable)
				table.clear(layerMap)

				local sceneFunc = require(nextScene)
				sceneFunc(unpack(sceneParams))
				nextScene = nil
			end
			yield()
		end
	end
end)
