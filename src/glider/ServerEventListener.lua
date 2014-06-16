local Network = require "glider.Network"
local Listener = require "glider.Listener"

return Listener.makeListener(..., Network.serverEvents, {
	{"ReceivePlayerJoin", "playerJoin", "onPlayerJoin"},
	{"ReceivePlayerLeave", "playerLeave", "onPlayerLeave"}
})
