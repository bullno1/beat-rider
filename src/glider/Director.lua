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
		"getCamera",
		"pickFirstEntityAt"
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

	function pickFirstEntityAt(x, y, predicate)
		return pickEntityInRenderTable(renderTable, x, y, predicate)
	end

	-- Private
	function pickEntityInRenderTable(renderTable, windowX, windowY, predicate)
		local numEntries = #renderTable
		for entryIndex = numEntries, 1, -1 do
			local renderPass = renderTable[entryIndex]

			-- if the render pass is a layer
			local wndToWorld = renderPass.wndToWorld
			if wndToWorld then
				local localX, localY = renderPass:wndToWorld(windowX, windowY)
				local partition = renderPass:getPartition()
				if partition then
					local entity = pickFirstEntity(predicate, partition:propListForPoint(localX, localY))
					if entity then
						return entity
					end
				end
			elseif getmetatable(renderPass) == nil then--if renderPass is a table
				local entity, localX, localY = pickEntityInRenderTable(renderPass, windowX, windowY, predicate)
				if entity ~= nil then
					return entity
				end
			end
		end
	end

	function pickFirstEntity(predicate, prop, ...)
		if prop then
			local entity = prop.entity
			if entity and predicate(entity) then
				return entity
			else
				return pickFirstEntity(predicate, ...)
			end
		end
	end

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
				MOAISim.forceGC()
				nextScene = nil
			end
			yield()
		end
	end
end)
