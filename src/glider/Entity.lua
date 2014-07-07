local Asset = require "glider.Asset"

local m = {}

local aliveEntities = {}
local destroyedEntities = {}
local numDestroyedEntities = 0
local anonPresetCount = 0
local nameToEntity = {}
local entityToName = {}

-- Create an entity from preset
function m.create(preset)
	preset = type(preset) == "string" and Asset.get("preset", preset) or preset
	-- Create a table for every component to store its state
	local entity = {}
	for _, component in ipairs(preset.components) do
		entity[component.name] = {}
	end
	setmetatable(entity, preset.metatable)
	aliveEntities[entity] = true
	m.send(entity, "onCreate")

	for propertyIndex, propertyKV in pairs(preset.defaultProperties) do
		local name, value = unpack(propertyKV)
		entity["set"..name](entity, value)
	end

	return entity
end

-- Destroy an entity
function m.destroy(ent)
	if aliveEntities[ent] then
		aliveEntities[ent] = nil

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

function m.isAlive(ent)
	return aliveEntities[ent] ~= nil
end

function m.link(ent, target)
	local linkedEntities = target.linkedEntities or {}
	linkedEntities[ent] = true
	target.linkedEntities = linkedEntities
end

function m.getPreset(ent)
	return getmetatable(ent).preset
end

function m.init()
	local yield = coroutine.yield
	MOAICoroutine.new():run(function()
		while true do
			m.cleanupEntities()
			yield()
		end
	end)
end

function m.cleanupEntities()
	for i = 1, numDestroyedEntities do
		local ent = destroyedEntities[i]
		m._setName(ent, nil)
		m.send(ent, "onDestroy")

		destroyedEntities[i] = nil
	end
	numDestroyedEntities = 0
end

function m.send(entity, msg, ...)
	local handler = entity[msg]
	if handler then
		return handler(entity, ...)
	end
end

function m.destroyAll()
	for entity in pairs(aliveEntities) do
		m.destroy(entity)
	end
end

function m.getByName(name)
	return nameToEntity[name]
end

function m.hasComponent(entity, name)
	return entity[name] ~= nil
end

function m._setName(entity, name)
	local oldName = entityToName[entity]
	if oldName ~= nil then
		nameToEntity[oldName] = nil
	end

	if name ~= nil then
		assert(nameToEntity[name] == nil, "Name '"..name.."' is already taken")
		nameToEntity[name] = entity
	end

	entityToName[entity] = name
end

function m._getName(entity)
	return entityToName[entity]
end

return m
