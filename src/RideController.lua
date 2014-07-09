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

		local step = 0
		while true do
			local truePosition = song:getPosition()
			pos = pos + step
			local err = truePosition - pos
			pos = pos + 0.001 * err

			self.songPos = pos
			self.songPosError = err
			step = coroutine.yield()
		end
	end

	function createNotes(self, ent, notesData)
		local trackWidth = Options.getDevOptions().ride.track_width

		for i, noteData in ipairs(notesData) do
			local note = Entity.create("Note")
			local time, column, score = unpack(noteData)

			note:setTrackPosition(time)
			note:setX((column - 2) * trackWidth / 3)
			
			if not score then
				note:getProp():setColor(0, 0, 0)
			end

			note:getProp():setBillboard(true)
		end
	end
end)
