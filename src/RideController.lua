local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Options = require "glider.Options"

return component(..., function()
	depends "glider.Actor"

	property("SongPos",
		function(self, ent)
			return self.songPos
		end)

	property("SongPosError",
		function(self, ent)
			return self.songPosError
		end)

	msg("onCreate", function(self, ent)
		self.songPos = 0
		self.songPosError = 0

		ent:spawnCoroutine(ride, self, ent)
	end)

	function ride(self, ent)
		local sceneData = Director.getSceneData()
		local song = sceneData.song
		createNotes(self, ent, sceneData.notes)

		song:play()
		local pos = song:getPosition()

		local txt = Entity.getByName("txtProgress")
		local template = "Play position: %.2f\nError: %.2f\nFPS:%.2f"
		local step = 0
		while true do
			local truePosition = song:getPosition()
			pos = pos + step
			local err = truePosition - pos
			pos = pos + 0.1 * err
			txt:setText(template:format(pos, err, MOAISim.getPerformance()))

			self.songPos = pos
			self.songPosError = err
			step = coroutine.yield()
		end
	end

	function createNotes(self, ent, notesData)
		local opts = Options.getDevOptions().ride
		local trackWidth = opts.track_width

		for i, noteData in ipairs(notesData) do
			local note = Entity.create("Note")
			local time, column, score = unpack(noteData)

			note:setTargetTrackPosition(time)
			note:setX((column - 2) * trackWidth / 3)
			note:setSpeed(opts.note_speed)
			
			if score then
				note:getProp():setColor(0.2, 0.8, 0.6)
			else
				note:getProp():setColor(0.2, 0.2, 0.2)
			end
		end
	end
end)
