local m = {}

local destroyedEntities = {}
local numDestroyedEntities = 0

-- Create an entity from preset
function m.create(preset)
	local preset = type(preset) == "string" and require(preset) or preset

	local components = {}
	for _, component in ipairs(preset.components) do
		components[component.name] = {}
	end
	local entity = setmetatable(
		{
			__components = components,
			alive = true
		},
		preset.metatable
	)
	entity:onCreate()

	for name, value in pairs(preset.defaultProps) do
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
