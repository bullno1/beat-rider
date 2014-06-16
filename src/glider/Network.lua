local Protocol = require "glider.network.Protocol"
local ServerCmd = Protocol.ServerCmd
local ClientCmd = Protocol.ClientCmd
local Client = require "glider.network.Client"
local Server = require "glider.network.Server"
local ProtoPack = require "glider.ProtoPack"
local Action = require "glider.Action"
local Event = require "glider.Event"
local Entity = require "glider.Entity"

local m = {}

local host
local networkGroup
local serverPeer
local authorative = false
local timeOffset = 0

m.serverEvents = {
	playerJoin = Event.new(),
	playerLeave = Event.new()
}

m.clientEvents = {
	connect = Event.new(),
	disconnect = Event.new()
}

function m.init(config)
	networkGroup = Action.spawnActionGroup()
	Client.init(networkGroup, m.clientEvents, config)
	Server.init(networkGroup, m.serverEvents, config)

	local glider = require "glider"
	glider.appFinalize:addListener(function()
		if serverPeer then
			serverPeer:disconnect()
			host:flush()
		end
	end)
end

local serviceHost
function m.start(params)
	params = params or {}

	host = assert(enet.host_create(
		'*:'..(params.port or '*'),
		params.peerCount,
		params.channelCount,
		params.inBandwidth,
		params.outBandwidth
	))

	Action.spawnCoroutine(networkGroup, serviceHost)
end

local serverSendSnapshot
function m.startAuthorativeServer()
	authorative = true
	Server.start(host)
	local _, port = host:socket_get_address()
	m.connect('localhost', port)
end

function m.stopAuthorativeServer()
	Server.stop()
	authorative = false
end

function m.connect(address, port, channelCount)
	serverPeer = host:connect(address..':'..port, channelCount)
end

function m.isAuthorative()
	return authorative
end

m.getPlayerId = Client.getId
m.getServerTimestamp = Server.getTimestamp
m.getClientTimestamp = Client.getTimestamp

-- Private

m._registerNetActor = Server.registerNetActor
m._deregisterNetActor = Server.deregisterNetActor
m._sendRPC = Client.sendRPC

local handleConnect, handleDisconnect, handleData
serviceHost = function()
	local yield = coroutine.yield
	while true do
		local event, peer, data, channel = host:service()
		if event == "connect" then
			handleConnect(peer, data)
		elseif event == "disconnect" then
			handleDisconnect(peer, data)
		elseif event == "receive" then
			handleData(peer, data, channel)
		else
			yield()
		end
	end
end

handleConnect = function(peer, data)
	if peer == serverPeer then
		Client.onConnect(peer)
	elseif authorative then
		Server.onConnect(peer, data)
	else
		peer:disconnect_now()
	end
end

handleDisconnect = function(peer, data)
	if peer == serverPeer then
		serverPeer = nil
		Client.onDisconnect()
	elseif authorative then
		Server.onDisconnect(peer)
	end
end

handleData = function(peer, data, channel)
	if peer == serverPeer then
		local success, cmdOrError = pcall(ProtoPack.decode, data, ServerCmd)
		if success then
			return Client.onCmd(cmdOrError, channel)
		else
			print("Warning: Invalid packet from server:", cmdOrError)
		end
	elseif authorative then
		local success, cmdOrError = pcall(ProtoPack.decode, data, ClientCmd)
		if success then
			return Server.onCmd(cmdOrError, peer, channel)
		else
			print("Warning: Invalid packet from client", peer, cmdOrError)
		end
	end
end

return m
