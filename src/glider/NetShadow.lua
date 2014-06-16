local Entity = require "glider.Entity"
local Network = require "glider.Network"
local RingBuffer = require "glider.RingBuffer"

return component(..., function()
	depends "glider.NetBase"
	depends "glider.Actor"

	local ensureInterpolationBuffer
	msg("update", function(self, ent)
		local ownerType = ent:getNetOwnerType()
		-- Update
		if ownerType == 'local' then
			-- Local controlled entities must be up-to-date
			ent:_updateUntil(Network.getClientTimestamp())
			ent:prepareRPC()
		elseif ownerType == 'remote' then
			local targets = self.syncTargets
			if targets == nil then return end

			local syncSpecs = Entity.getPreset(ent).syncSpecs
			-- Interpolate towards 'correct' values
			for propId, propSpec in pairs(syncSpecs) do
				local target = targets[propId]
				local syncParams = propSpec.syncParams

				if syncParams ~= "snap" then
					local oldValue = propSpec.getter(ent)
					local diff = target - oldValue

					local absDiff = math.abs(diff)
					if absDiff > syncParams.snapThreshold then
						propSpec.setter(ent, target)
					elseif absDiff > syncParams.smoothThreshold then
						propSpec.setter(ent, oldValue + diff * syncParams.smoothFactor)
					end
				end
			end
			--ent:_updateOnce()
		end
	end)

	local ensurePredictionBuffers
	msg("sendRPC", function(self, ent, msgName, params)
		assertp(ent:getNetOwnerType() == 'local', "Cannot make rpc call on someone else's entity", 3)
		ensurePredictionBuffers(self)

		Network._sendRPC(ent, msgName, params)

		-- Client-side prediction
		local now = Network.getClientTimestamp()
		self.unackedTimestamps:add(now)
		self.unackedMessages:add(msgName)
		self.unackedParams:add(params)

		return ent[msgName](ent, params, now)
	end)

	query("_replayRPC", function(self, ent)
		local unackedTimestamps = self.unackedTimestamps
		local unackedMessages = self.unackedMessages
		local unackedParams = self.unackedParams

		if unackedTimestamps == nil then return end

		local lastUpdate = ent:getLastUpdate()
		local numReplayedCmds = 0
		for index, unackedTime in unackedTimestamps:iterator() do
			if unackedTime ~= nil and unackedTime > lastUpdate then
				numReplayedCmds = numReplayedCmds + 1
				ent:_updateUntil(unackedTime)
				ent[unackedMessages:get(index)](ent, unackedParams:get(index), unackedTime)
			end
		end
		ent:_updateUntil(Network.getClientTimestamp())
	end)

	query("_setSyncTargets", function(self, ent, targets)
		self.syncTargets = targets
	end)

	ensurePredictionBuffers = function(self)
		if self.unackedTimestamps == nil then
			self.unackedTimestamps = RingBuffer.new(60)
			self.unackedMessages = RingBuffer.new(60)
			self.unackedParams = RingBuffer.new(60)
		end
	end
end)
