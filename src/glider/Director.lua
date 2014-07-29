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
		"getFrameBuffer",
		"pickFirstEntityAt",
		"getRenderTableEntry"
	}

	local updatePhases = {}
	local renderTables = {}
	local partitions = {}
	local frameBuffers = {}
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

	function getFrameBuffer(name)
		for _, buffer in ipairs(frameBuffers) do
			if buffer.name == name then
				return buffer
			end
		end
		return nil
	end

	function pickFirstEntityAt(x, y, predicate)
		return pickEntityInRenderTable(renderTable, x, y, predicate)
	end

	function getRenderTableEntry(renderTableName, entryName)
		local renderTable = assert(renderTables[renderTableName], "Render table '"..renderTableName.."' does not exist")
		-- TODO: handle nested table
		for _, entry in ipairs(renderTable) do
			if entry.name == entryName then
				return entry
			end
		end
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

				table.clear(renderTables)
				table.clear(partitions)

				-- Purge framebuffer textures
				for _, buff in ipairs(frameBuffers) do
					Asset.purge("rt-texture", buff.name)
				end
				table.clear(frameBuffers)

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

		-- Create frame buffers
		for buffIndex, buffSpec in pairs(sceneSpecs.frameBuffers or table.empty) do
			local frameBuffer = MOAIFrameBufferTexture.new()
			local bufferName = buffSpec.name
			frameBuffer:init(buffSpec.width, buffSpec.height, 78)
			frameBuffer.name = bufferName
			frameBuffers[buffIndex] = frameBuffer
		end

		if #frameBuffers > 0 then
			MOAIRenderMgr.setBufferTable(frameBuffers)
		else
			MOAIRenderMgr.setBufferTable(nil)
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
			local viewWidth, viewHeight, viewScaleX, viewScaleY

			if viewportSpec.mode == "relative" then
				local fullWidthPx, fullHeightPx = Screen.getSize "px"
				viewWidth, viewHeight = fullWidthPx * viewportSpec.width, fullHeightPx * viewportSpec.height
				local width, height = Screen.getSize(viewportSpec.unit)
				viewScaleX, viewScaleY = width * viewportSpec.xScale, height * viewportSpec.yScale
			else
				viewWidth, viewHeight = viewportSpec.width, viewportSpec.height
				viewScaleX, viewScaleY = viewportSpec.xScale * viewWidth, viewportSpec.yScale * viewHeight
			end

			viewport:setSize(viewWidth, viewHeight)
			viewport:setScale(viewScaleX, viewScaleY)
			viewport:setOffset(viewportSpec.xOffset, viewportSpec.yOffset)
			viewports[viewportName] = viewport
		end

		-- Create render tables
		for tableName, tableSpec in pairs(sceneSpecs.renderTables) do
			local renderTable = {}
			for entryIndex, entrySpec in ipairs(tableSpec) do
				local entry

				if entrySpec.type == "layer" then
					entry = MOAILayer.new()
					entry:setPartition(assert(partitions[entrySpec.partition], "Partition '"..entrySpec.partition.."' does not exists"))
					entry:setViewport(assert(viewports[entrySpec.viewport], "Viewport '"..entrySpec.viewport.."' does not exists"))
					entry:setSortMode(entrySpec.sort)
					entry.name = entrySpec.name

					local cameraName = entrySpec.camera
					if cameraName then
						local entity = assert(Entity.getByName(cameraName), "Entity '"..cameraName.."' does not exists")
						assert(entity.getCamera, "Entity '"..cameraName.."' is not a camera")
						entry:setCamera(entity:getCamera())
					end
				end

				renderTable[entryIndex] = entry
			end
			renderTables[tableName] = renderTable
		end

		MOAIGfxDevice.getFrameBuffer():setRenderTable(renderTables.main)

		-- Init frame buffers
		for buffIndex, buffSpec in pairs(sceneSpecs.frameBuffers or table.empty) do
			local renderTable = assert(
				renderTables[buffSpec.renderTable],
				"Buffer "..tostring(buffSpec.name).."("..buffIndex..") specify an invalid render table: '"..buffSpec.renderTable.."'"
			)
			frameBuffers[buffIndex]:setRenderTable(renderTable)
			-- TODO: use setting from xml
			frameBuffers[buffIndex]:setClearColor(0, 0, 0, 0)
		end
	end
end)
