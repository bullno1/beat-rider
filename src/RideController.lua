local Entity = require "glider.Entity"
local Action = require "glider.Action"
local Director = require "glider.Director"

return component(..., function()
	depends "glider.Actor"

	local updateProgress
	msg("onCreate", function(self, ent)
		local aubio = Aubio.new()
		aubio:setHopSize(1024)
		aubio:addSpectralDescriptor("energy")
		aubio:load("assets/sfx/8282.mp3")
		ent:spawnCoroutine(updateProgress, self, aubio)
		self.aubio = aubio
	end)

	updateProgress = function(self, aubio)
		local txtProgress = Entity.getByName "txtProgress"
		local timeScale = 300
		repeat
			local status = aubio:getStatus()
			local progress = aubio:getProgress()
			txtProgress:setText("Loading "..tostring(math.floor(progress * 100)) .. "%")

			if status == Aubio.STATUS_LOADED then
				for i, time in ipairs(aubio:getBeats()) do
					local marker = Entity.create("presets.Marker")
					marker:setX(time * 300)
					marker:setY(-200)
				end

				for i, time in ipairs(aubio:getOnsets()) do
					local marker = Entity.create("presets.Marker")
					marker:setX(time * 300)
					marker:setY(-150)
				end

				aubio:play()
			end
			coroutine.yield()
		until status ~= Aubio.STATUS_LOADING

		if aubio:getStatus() ~= Aubio.STATUS_LOADED then
			return
		end

		local fmt = "Playing %.1f\nFPS: %.1f\nError: %.3f\nStep: %.3f"
		local camera = Director.getCamera("Visualizer")
		local pos = aubio:getPosition()
		local ship = Entity.getByName("Ship")
		local step = 0
		while true do
			local position = aubio:getPosition()
			pos = pos + step
			local err = aubio:getPosition() - pos
			txtProgress:setText(fmt:format(position, MOAISim.getPerformance(), math.abs(err), step))
			camera:setX(pos * 300)
			ship:setZRotation(pos * 10)
			--pos = pos + 0.1 * err
			step = coroutine.yield()
		end
	end
end)
