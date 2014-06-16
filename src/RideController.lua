local Entity = require "glider.Entity"
local Action = require "glider.Action"

return component(..., function()
	depends "glider.Actor"

	local updateProgress
	msg("onCreate", function(self, ent)
		local aubio = Aubio.new()
		aubio:setHopSize(1024)
		aubio:addSpectralDescriptor("energy")
		aubio:load("assets/sfx/DontSayGoodbye.mp3")
		ent:spawnCoroutine(updateProgress, aubio)
		self.aubio = aubio
	end)

	updateProgress = function(aubio)
		local txtProgress = Entity.getByName "txtProgress"
		repeat
			local status = aubio:getStatus()
			local progress = aubio:getProgress()
			txtProgress:setText(tostring(math.floor(progress * 100)) .. "%")

			if status == Aubio.STATUS_LOADED then
				aubio:play()
			end
			coroutine.yield()
		until status ~= Aubio.STATUS_LOADING
	end
end)
