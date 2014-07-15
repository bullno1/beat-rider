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
		local notesData = sceneData.notes
		local notes = createNotes(self, ent, sceneData.notes)

		song:play()
		local pos = song:getPosition()

		local txt = Entity.getByName("txtProgress")
		local template = "Play position: %.2f\nError: %.2f\nFPS:%.2f\nActive notes:%d"
		local step = 0
		local currentNoteIndex = 1
		local opts = Options.getDevOptions().ride
		local noteSpeed = opts.note_speed
		local updateDistance = opts.update_distance
		local numNotes = #notes
		local setTrackPosition = notes[1].setTrackPosition
		while true do
			local truePosition = song:getPosition()
			pos = pos + step
			local err = truePosition - pos
			pos = pos + 0.1 * err

			-- Advance note index
			while currentNoteIndex <= numNotes and notesData[currentNoteIndex][1] < pos do
				currentNoteIndex = currentNoteIndex + 1
			end

			local movedNoteIndex = currentNoteIndex
			while movedNoteIndex <= numNotes and notesData[movedNoteIndex][1] <= pos + updateDistance do
				local note = notes[movedNoteIndex]
				local target = notesData[movedNoteIndex][1]
				setTrackPosition(note, target - (target - pos) * noteSpeed)
				movedNoteIndex = movedNoteIndex + 1
			end

			local numActiveNotes = movedNoteIndex - currentNoteIndex

			txt:setText(template:format(pos, err, MOAISim.getPerformance(), numActiveNotes))

			self.songPos = pos
			self.songPosError = err
			step = coroutine.yield()
		end
	end

	function createNotes(self, ent, notesData)
		local opts = Options.getDevOptions().ride
		local trackWidth = opts.track_width
		local noteSpeed = opts.note_speed
		local updateDistance = opts.update_distance
		local posOffset = -updateDistance * noteSpeed
		local notes = {}

		for i, noteData in ipairs(notesData) do
			local note = Entity.create("Note")
			local time, column, score = unpack(noteData)

			note:setTrackPosition(time + posOffset)
			note:setX((column - 2) * trackWidth / 3)

			if score then
				note:getProp():setColor(0.2, 0.8, 0.6)
			else
				note:getProp():setColor(0.2, 0.2, 0.2)
			end

			notes[i] = note
		end

		return notes
	end
end)
