local Network = require "glider.Network"

return component(..., function()
	property("NetId",
		function(self, ent)
			return self.netId
		end)

	property("NetOwner",
		function(self, ent)
			return self.netOwner
		end,
		function(self, ent, val)
			self.netOwner = val
		end)

	property("LastUpdate",
		function(self, ent)
			return self.lastUpdate
		end)

	property("NetOwnerType", function(self, ent)
		local owner = ent:getNetOwner()
		if owner == 0 then
			return 'server'
		elseif owner == Network.getPlayerId() then
			return 'local'
		else
			return 'remote'
		end
	end)

	
	msg("onCreate", function(self, ent)
		self.netId = 0
		self.netOwner = 0
		self.lastUpdate = 0
	end)

	query("_updateUntil", function(self, ent, timestamp)
		local lastUpdate = self.lastUpdate
		local netUpdate = ent.netUpdate

		for time = lastUpdate + 1, timestamp do
			netUpdate(ent, time)
		end

		self.lastUpdate = timestamp
		return timestamp - lastUpdate
	end)

	query("_updateOnce", function(self, ent)
		local lastUpdate = self.lastUpdate + 1
		ent:netUpdate(lastUpdate)
		self.lastUpdate = lastUpdate
	end)

	query("_setLastUpdate", function(self, ent, val)
		self.lastUpdate = val
	end)

	query("_setNetId", function(self, ent, val)
		self.netId = val
	end)
end)
