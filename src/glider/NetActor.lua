local Network = require "glider.Network"

return component(..., function()
	depends "glider.NetBase"

	msg("onCreate", function(self, ent)
		Network._registerNetActor(ent)
	end)

	msg("onDestroy", function(self, ent)
		Network._deregisterNetActor(ent)
	end)
end)
