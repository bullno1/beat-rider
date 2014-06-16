local Action = require "glider.Action"
local ProtoPack = require "glider.ProtoPack"
local Protocol = require "glider.network.Protocol"
local Entity = require "glider.Entity"
local ServerCmd = Protocol.ServerCmd
local ClientCmdType = Protocol.ClientCmdType
local ServerCmdType = Protocol.ServerCmdType

local m = {}

local host
local config
local networkGroup
local events
local authorative = false
-- Player
local players = {}
local numPlayers = 0
-- Net actor
local actors = {}
local nextNetId = 1
-- World update
local snapshotTimer
local presetToId = {}

function m.init(networkGroup_, events_, config_)
	networkGroup = networkGroup_
	events = events_
	config = config_

	for presetId, presetName in ipairs(config.presets or {}) do
		presetToId[presetName] = presetId
	end
end

local sendSnapshot
function m.start(host_)
	host = host_

	authorative = true
	local tickRate = config.serverSnapshotRate or 30
	snapshotTimer = Action.spawnTimer(networkGroup, sendSnapshot, 1 / tickRate, true)
end

function m.stop()
	snapshotTimer:stop()
	authorative = false
end

function m.onConnect(peer, data)
	-- TODO: setup disconnect timer to kick unauthorized peers
end

function m.onDisconnect(peer)
	local player = players[peer]
	if player then
		players[peer] = nil
		numPlayers = numPlayers - 1

		events.playerLeave:fire(player.id)
	end
end

local sendCmd, dispatchRPC, findSnapshot, DUMMY_SNAPSHOT
function m.onCmd(cmd, peer, channel)
	if cmd.type == ClientCmdType.AUTH then
		sendCmd(
			peer,
			{
				type = ServerCmdType.AUTH_RESPONSE,
				authResponse = {
					accepted = true,
					boostrapData = {
						playerId = peer:index(),
						networkedPresets = {}
					}
				}
			},
			"reliable"
		)
	elseif cmd.type == ClientCmdType.CLOCK_SYNC then
		local sync = cmd.clockSync
		sendCmd(
			peer,
			{
				type = ServerCmdType.CLOCK_SYNC,
				clockSync = {
					sendTime = sync.sendTime,
					recvTime = MOAISim.getElapsedFrames()
				}
			},
			"unreliable"
		)
		host:flush()
	elseif cmd.type == ClientCmdType.READY then
		local playerId = peer:index()
		players[peer] = {
			id = playerId,
			lastSnapshot = DUMMY_SNAPSHOT,
			peer = peer
		}
		numPlayers = numPlayers + 1
		events.playerJoin:fire(playerId)
	elseif cmd.type == ClientCmdType.RPC then
		local rpc = cmd.rpc
		local player = players[peer]
		player.lastSnapshot = findSnapshot(rpc.lastSnapshotTimestamp)
		if player.lastSnapshot == DUMMY_SNAPSHOT then
			print("Warning: Full sync player "..player.id..". Last snapshot: "..rpc.lastSnapshotTimestamp)
		end

		for i, call in ipairs(rpc.rpcCalls) do
			dispatchRPC(player, call)
		end
	end
end

m.getTimestamp = MOAISim.getElapsedFrames

function m.registerNetActor(actor)
	assert(authorative, "glider.NetActor can only be created on server")
	actors[nextNetId] = actor
	actor:_setNetId(nextNetId)
	-- TODO: investigate if setting timestamp here is appropriate
	actor:_setLastUpdate(m.getTimestamp())
	nextNetId = nextNetId + 1
end

function m.deregisterNetActor(actor)
	actors[actor:getNetId()] = nil
end

-- Private

local takeSnapshot, diffSnapshot, addSnapshot
sendSnapshot = function()
	if numPlayers == 0 then return end

	local now = m.getTimestamp()

	-- Take a snapshot of the world
	local snapshot = {}
	local numEntities = 0
	for id, entity in pairs(actors) do
		numEntities = numEntities + 1
		snapshot[id] = takeSnapshot(entity)
	end

	-- Broadcast to all players
	for peer, player in pairs(players) do
		local lastSnapshot = player.lastSnapshot
		local changedEntities, destroyedEntities = diffSnapshot(lastSnapshot, snapshot)
		sendCmd(
			peer,
			{
				type = ServerCmdType.WORLD_SNAPSHOT,
				snapshot = {
					timestamp = now,
					changedEntities = changedEntities,
					destroyedEntities = destroyedEntities
				}
			},
			"unreliable"
		)
	end

	addSnapshot(now, snapshot)
end

takeSnapshot = function(entity)
	local syncSpecs = Entity.getPreset(entity).syncSpecs
	local snapshot = {}
	for propId, propSpec in ipairs(syncSpecs) do
		snapshot[propId] = propSpec.getter(entity)
	end
	return snapshot
end

diffSnapshot = function(before, now)
	local changedEntities = {}
	local destroyedEntities = {}

	-- Look for changed or added entities
	local numChangedEntities = 0
	for entityId, entityData in pairs(now) do
		local changed = false
		local oldEntity = before[entityId]

		if oldEntity then
			-- Check for changes
			for propId, propValue in ipairs(entityData) do
				if oldEntity[propId] ~= propValue then
					changed = true
					break
				end
			end
		else
			-- Add everything
			changed = true
		end

		if changed then
			numChangedEntities = numChangedEntities + 1
			local entity = actors[entityId]
			changedEntities[numChangedEntities] = {
				id = entityId,
				timestamp = entity:getLastUpdate(),
				presetId = presetToId[Entity.getPreset(entity).name],
				properties = entityData
			}
		end
	end

	-- Look for destroyed entities
	local numDestroyedEntities = 0
	for id in pairs(before) do
		if now[id] == nil then
			numDestroyedEntities = numDestroyedEntities + 1
			destroyedEntities[numDestroyedEntities] = id
		end
	end

	return changedEntities, destroyedEntities
end

local MAX_SNAPSHOTS = 30
DUMMY_SNAPSHOT = {}
local snapshotCursor = 0
local snapshotBuffer = {}
local timeBuffer = {}

-- Manage snapshots in a ring buffer
addSnapshot = function(time, snapshot)
	timeBuffer[snapshotCursor + 1] = time
	snapshotBuffer[snapshotCursor + 1] = snapshot

	snapshotCursor = (snapshotCursor + 1) % MAX_SNAPSHOTS
end

findSnapshot = function(time)
	for i = 1, MAX_SNAPSHOTS do
		if timeBuffer[i] == time then
			return snapshotBuffer[i]
		end
	end

	return DUMMY_SNAPSHOT
end

dispatchRPC = function(player, call)
	local entityId = call.entityId

	local entity = actors[call.entityId]
	if entity == nil then
		print("Warning: Player "..player.id.." attempted to make rpc call on non-existent entity "..entityId)
		return
	end

	local owner = entity:getNetOwner()
	if owner ~= player.id then
		print("Warning: Player "..player.id.." attempted to make unauthorized RPC call on entity "..entityId)
		return
	end

	local rpcSpec = Entity.getPreset(entity).rpcSpecs
	local msgSpec = rpcSpec[call.msgId]
	if msgSpec == nil then
		print("Warning: Player "..player.id.." attempted to make rpc call with an invalid msgId on entity "..entityId)
		return
	end

	local msgName = msgSpec.msgName
	local msgType = msgSpec.msgType
	local valid, paramsOrError = pcall(ProtoPack.decode, call.params, msgType)
	if not valid then
		print("Warning: Player "..player.id.." attempted to make rpc call with invalid paramters on entity "..entityId)
		print("Error: "..paramsOrError)
		return
	end

	local timestamp = call.timestamp
	entity:_updateUntil(timestamp)
	entity[msgName](entity, paramsOrError, timestamp)
end

sendCmd = function(peer, msg, reliability)
	peer:send(ProtoPack.encode(msg, ServerCmd), 0, reliability)
end

return m
