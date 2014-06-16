local m = {}

local destroyedEntities = {}
local numDestroyedEntities = 0
local anonPresetCount = 0

-- Create an entity from preset
function m.create(presetDesc)
	local presetDescType = type(presetDesc)
	local entityPreset
	if presetDescType == "string" then
		entityPreset = require(presetDesc)
	elseif presetDescType == "function" then
		anonPresetCount = anonPresetCount + 1
		entityPreset = preset("anonymousPreset#"..anonPresetCount, presetDesc)
	elseif presetDescType == "table" then
		entityPreset = presetDesc
	else
		error("Unknown preset description type '"..presetDescType.."'")
	end

	local components = {}
	for _, component in ipairs(entityPreset.components) do
		components[component.name] = {}
	end
	local entity = setmetatable(
		{
			__components = components,
			alive = true
		},
		entityPreset.metatable
	)
	entity:onCreate()

	for name, value in pairs(entityPreset.defaultProps) do
		entity["set"..name](entity, value)
	end

	return entity
end

-- Destroy an entity
function m.destroy(ent)
	if ent.alive then
		ent.alive = false

		local linkedEntities = ent.linkedEntities
		if linkedEntities then
			for linkedEnt in pairs(linkedEntities) do
				m.destroy(linkedEnt)
			end
		end

		numDestroyedEntities = numDestroyedEntities + 1
		destroyedEntities[numDestroyedEntities] = ent
	end
end

function m.link(ent, target)
	local linkedEntities = target.linkedEntities or {}
	linkedEntities[ent] = true
	target.linkedEntities = linkedEntities
end

function m.getPreset(ent)
	return getmetatable(ent).preset
end

function m.initManager()
	local yield = coroutine.yield
	MOAICoroutine.new():run(function()
		while true do
			for i = 1, numDestroyedEntities do
				local ent = destroyedEntities[i]
				ent:onDestroy()

				destroyedEntities[i] = nil
			end
			numDestroyedEntities = 0

			yield()
		end
	end)
end

return m
