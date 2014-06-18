local Entity = require "glider.Entity"

local m = {}

local updatePhases = {}
local renderTable = {}
local layerMap = {}
local cameras = setmetatable({}, {__mode='v'})

local changeSceneIfNeeded
function m.init(config)
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
		m.changeScene(config.firstScene)
	end
end

local nextScene
local sceneParams

function m.changeScene(sceneName, ...)
	nextScene = sceneName
	sceneParams = {...}
end

local yield = coroutine.yield
changeSceneIfNeeded = function()
	while true do
		if nextScene ~= nil then
			Entity.destroyAll()

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
			sceneParams = nil
		end
		yield()
	end
end

function m.getUpdatePhase(name)
	return updatePhases[name]
end

function m.addLayer(name, layer)
	assert(layerMap[name] == nil, "Layer "..name.." is already defined")

	table.insert(renderTable, 1, layer)
	layerMap[name] = layer
end

function m.getLayer(name)
	return layerMap[name]
end

function m.addCamera(name, camera)
	cameras[name] = camera
end

function m.getCamera(name)
	return cameras[name]
end

return m
