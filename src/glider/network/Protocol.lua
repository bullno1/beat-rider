local ProtoPack = require "glider.ProtoPack"

local m = {}

m.ClientCmdType = enum{
	"AUTH",
	"CLOCK_SYNC",
	"READY",
	"RPC"
}

m.ServerCmdType = enum{
	"AUTH_RESPONSE",
	"CLOCK_SYNC",
	"WORLD_SNAPSHOT"
}

ProtoPack.desc(function()
	-- Authentication & boostrapping
	local Authentication = struct(
		required(String, "method"),
		optional(String, "data")
	)

	local BootstrapData = struct(
		required(Number, "playerId"),
		required(array(String), "networkedPresets")
	)

	local AuthenticationResponse = struct(
		required(Boolean, "accepted"),
		optional(BootstrapData, "boostrapData"),
		optional(String, "error"),
		optional(String, "details")
	)

	-- Clock Sync
	local ClockSync = struct(
		required(Number, "sendTime"),
		required(Number, "recvTime")
	)

	-- Game update
	local RpcCall = struct(
		required(Number, "timestamp"),
		required(Number, "entityId"),
		required(Number, "msgId"),
		required(String, "params")
	)

	local RPC = struct(
		required(Number, "lastSnapshotTimestamp"),
		required(array(RpcCall), "rpcCalls")
	)

	local Entity = struct(
		required(Number, "timestamp"),
		required(Number, "id"),
		required(Number, "presetId"),
		required(array(Number), "properties")
	)

	local WorldSnapshot = struct(
		required(Number, "timestamp"),
		required(array(Entity), "changedEntities"),
		required(array(Number), "destroyedEntities")
	)

	-- Top level message
	m.ClientCmd = struct(
		required(Number, "type"),
		optional(Authentication, "auth"),
		optional(ClockSync, "clockSync"),
		optional(RPC, "rpc")
	)

	m.ServerCmd = struct(
		required(Number, "type"),
		optional(AuthenticationResponse, "authResponse"),
		optional(ClockSync, "clockSync"),
		optional(WorldSnapshot, "snapshot")
	)
end)

return m
