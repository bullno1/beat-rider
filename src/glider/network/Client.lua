local Action = require "glider.Action"
local ProtoPack = require "glider.ProtoPack"
local Protocol = require "glider.network.Protocol"
local Entity = require "glider.Entity"
local ClientCmd = Protocol.ClientCmd
local ClientCmdType = Protocol.ClientCmdType
local ServerCmdType = Protocol.ServerCmdType

local m = {}

local playerId
local networkGroup
local events
local config
local serverPeer
-- Clock sync
local syncTimer
local timeOffset
-- World update
local lastSnapshotTimestamp = 0
local shadows = {}
local idToPreset = {}

local rpcCalls = {}
local numOutstandingRpcs = 0
local rpcTimer

function m.init(networkGroup_, events_, config_)
	networkGroup = networkGroup_
	events = events_
	config = config_

	for index, presetName in ipairs(config.presets or {}) do
		local preset = require(presetName)
		local shadowPreset = assert(
			preset.shadowPreset,
			"Networked preset '"..presetName.."' does not define a shadow preset"
		)
		idToPreset[index] = shadowPreset
	end
end

local sendCmd
function m.onConnect(peer)
	serverPeer = peer
	sendCmd(
		{
			type = ClientCmdType.AUTH,
			auth = {method='trust'}
		},
		"reliable"
	)
end

function m.onDisconnect()
	rpcTimer:stop()
end

local sendClockSyncCmd, applySnapshot, netTick
function m.onCmd(cmd, channel)
	if cmd.type == ServerCmdType.AUTH_RESPONSE then
		playerId = cmd.authResponse.boostrapData.playerId
		sendClockSyncCmd()
		syncTimer = Action.spawnTimer(networkGroup, sendClockSyncCmd, 1 / 2, true)
	elseif cmd.type == ServerCmdType.CLOCK_SYNC then
		local sync = cmd.clockSync
		local now = MOAISim.getElapsedFrames()
		local RTT = now - sync.sendTime
		timeOffset = sync.recvTime + math.floor(RTT / 2) - now
		syncTimer:stop()
		sendCmd({type = ClientCmdType.READY}, "reliable")

		-- Start sending rpc
		local tickRate = config.clientRpcRate or 20
		rpcTimer = Action.spawnTimer(networkGroup, netTick, 1 / tickRate, true)
	elseif cmd.type == ServerCmdType.WORLD_SNAPSHOT then
		local snapshot = cmd.snapshot
		local timestamp = snapshot.timestamp
		lastSnapshotTimestamp = timestamp

		-- Destroy entities
		for _, destroyedEntityId in ipairs(snapshot.destroyedEntities) do
			local entity = shadows[destroyedEntityId]
			if entity then
				Entity.destroy(entity)
				shadows[destroyedEntityId] = nil
				print("Destroyed entity "..destroyedEntityId)
			end
		end

		-- Modify/create entities
		for _, entitySnapshot in ipairs(snapshot.changedEntities) do
			local entityId = entitySnapshot.id
			local entity = shadows[entityId]
			if entity == nil then
				local preset = idToPreset[entitySnapshot.presetId]
				entity = Entity.create(preset)
				entity:_setNetId(entityId)
				entity:_setLastUpdate(entitySnapshot.timestamp)
				shadows[entityId] = entity
				print("Created entity '"..preset.."'("..entityId..")")
			end

			local ownerType = entity:getNetOwnerType()
			if ownerType == 'local' then
				applySnapshot(entity, entitySnapshot)
				-- Replay unacked RPC
				entity:_replayRPC()
			elseif ownerType == 'remote' then
				entity:_setLastUpdate(entitySnapshot.timestamp)
				local syncSpecs = Entity.getPreset(entity).syncSpecs
				for propId, propValue in ipairs(entitySnapshot.properties) do
					if syncSpecs[propId].syncParams == 'snap' then
						syncSpecs[propId].setter(entity, propValue)
					end
				end
				entity:_setSyncTargets(entitySnapshot.properties)
			elseif ownerType == 'server' then
				applySnapshot(entity, entitySnapshot)
			end
		end
	end
end

function m.getTimestamp()
	return MOAISim.getElapsedFrames() + timeOffset
end

function m.sendRPC(entity, msgName, params)
	local preset = Entity.getPreset(entity)
	local rpcId = assert(preset.rpcIds[msgName], "Message '"..msgName.."' is not an RPC message")
	local msgSpec = preset.rpcSpecs[rpcId]
	local params = ProtoPack.encode(params, msgSpec.msgType)
	numOutstandingRpcs = numOutstandingRpcs + 1
	rpcCalls[numOutstandingRpcs] = {
		timestamp = m.getTimestamp(),
		entityId = entity:getNetId(),
		msgId = rpcId,
		params = params
	}
end

function m.getId()
	return playerId
end

-- Private

applySnapshot = function(entity, snapshot)
	-- Move entity to the past and update it according to server
	entity:_setLastUpdate(snapshot.timestamp)
	local syncSpecs = Entity.getPreset(entity).syncSpecs
	for propId, propValue in ipairs(snapshot.properties) do
		syncSpecs[propId].setter(entity, propValue)
	end
end

sendClockSyncCmd = function()
	sendCmd(
		{
			type = ClientCmdType.CLOCK_SYNC,
			clockSync = {
				sendTime = MOAISim.getElapsedFrames(),
				recvTime = 0
			}
		},
		"unreliable"
	)
end

netTick = function()
	sendCmd(
		{
			type = ClientCmdType.RPC,
			rpc = {
				lastSnapshotTimestamp = lastSnapshotTimestamp,
				rpcCalls = rpcCalls
			}
		},
		"unreliable"
	)
	table.clear(rpcCalls)
	numOutstandingRpcs = 0
end

sendCmd = function(msg, reliability)
	serverPeer:send(ProtoPack.encode(msg, ClientCmd), 0, reliability)
end

return m
