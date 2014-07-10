local Asset = require "glider.Asset"
local Entity = require "glider.Entity"
local Screen = require "glider.Screen"

return module(function()
	exports {
		"init",
		"changeScene",
		"getSceneData",
		"getUpdatePhase",
		"getPartition",
		"pickFirstEntityAt"
	}

	local updatePhases = {}
	local renderTable = {}
	local partitions = {}
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

		local frontBuffer = MOAIGfxDevice.getFrameBuffer()
		frontBuffer:setRenderTable(renderTable)
		frontBuffer:setClearDepth(true)

		if config.firstScene then
			changeScene(config.firstScene, config.sceneData)
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

	function getPartition(name)
		return partitions[name]
	end

	function pickFirstEntityAt(x, y, predicate)
		return pickEntityInRenderTable(renderTable, x, y, predicate)
	end

	-- Private

	function pickEntityInRenderTable(renderTable, windowX, windowY, predicate)
		local numEntries = #renderTable
		-- Go in reverse order because layers rendered last appear on top
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
				print("Changing to scene '"..nextScene.."'")

				Entity.destroyAll()
				Entity.cleanupEntities()

				-- Stop all actions
				for _, phase in pairs(updatePhases) do
					phase:clear()
				end

				table.clear(renderTable)
				table.clear(partitions)

				local scene = Asset.get("scene", nextScene)
				initScene(scene)

				MOAISim.forceGC()
				nextScene = nil
			end
			yield()
		end
	end

	function initScene(sceneSpecs)
		-- Create partitions
		for partitionName, partitionSpec in pairs(sceneSpecs.partitions) do
			local partition = MOAIPartition.new()
			partition:setPlane(partition.plane)
			-- TODO: implement levels
			partitions[partitionName] = partition
		end

		-- Create entities
		for entityIndex, entitySpec in ipairs(sceneSpecs.entities) do
			local preset, properties = unpack(entitySpec)
			local entity = Entity.create(preset)
			for propertyIndex, propertyKV in ipairs(properties) do
				local name, value = unpack(propertyKV)
				entity["set"..name](entity, value)
			end
		end

		-- Create viewports
		local viewports = {}
		for viewportName, viewportSpec in pairs(sceneSpecs.viewports) do
			local viewport = MOAIViewport.new()
			local fullWidthPx, fullHeightPx = Screen.getSize "px"
			local viewScaleX, viewScaleY = Screen.getSize(viewportSpec.unit)
			viewport:setSize(fullWidthPx * viewportSpec.width, fullHeightPx * viewportSpec.height)
			viewport:setScale(viewScaleX * viewportSpec.xScale, viewScaleY * viewportSpec.yScale)
			viewport:setOffset(viewportSpec.xOffset, viewportSpec.yOffset)
			viewports[viewportName] = viewport
		end

		-- Create render table
		for entryIndex, entrySpec in ipairs(sceneSpecs.renderTables.main) do
			local entry

			if entrySpec.type == "layer" then
				entry = MOAILayer.new()
				entry:setPartition(assert(partitions[entrySpec.partition], "Partition '"..entrySpec.partition.."' does not exists"))
				entry:setViewport(assert(viewports[entrySpec.viewport], "Viewport '"..entrySpec.viewport.."' does not exists"))
				entry:setSortMode(entrySpec.sort)

				local cameraName = entrySpec.camera
				if cameraName then
					local entity = assert(Entity.getByName(cameraName), "Entity '"..cameraName.."' does not exists")
					assert(entity.getCamera, "Entity '"..cameraName.."' is not a camera")
					entry:setCamera(entity:getCamera())
				end
			end

			renderTable[entryIndex] = entry
		end
	end
end)
