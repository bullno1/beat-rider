local Network = require "glider.Network"
local Listener = require "glider.Listener"

return Listener.makeListener(..., Network.clientEvents, {
	{"ReceiveConnect", "connect", "onConnect"},
	{"ReceiveDisconnect", "disconnect", "onDisconnect"}
})
