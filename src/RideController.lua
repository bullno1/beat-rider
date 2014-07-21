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
		local template = "Play position: %.2f\nError: %.2f\nFPS:%.2f\nActive notes:%d\nScore: %d"
		local step = 0
		local currentNoteIndex = 1
		local opts = Options.getDevOptions().ride
		local noteSpeed = opts.note_speed
		local updateDistance = opts.update_distance
		local numNotes = #notes
		local setTrackPosition = notes[1].setTrackPosition

		local ship = Entity.getByName("Ship")
		local grid = Entity.getByName("Grid")
		local shipMinX, _minY, _minZ, shipMaxX, _maxY, _maxZ = ship:getProp():getBounds()
		local noteMinX, _minY, _minZ, noteMaxX, _maxY, _maxZ = notes[1]:getProp():getBounds()
		local objectLayer = Director.getRenderTableEntry("main", "Objects")
		local fxLayer = Director.getRenderTableEntry("main", "Effects")
		local score = 0

		while true do
			local truePosition = song:getPosition()
			pos = pos + step
			local err = truePosition - pos
			pos = pos + 0.1 * err

			local shipX, _shipY, _shipZ = ship:getX()
			local shipLeft = shipX + shipMinX
			local shipRight = shipX + shipMaxX

			-- Advance note index
			local lastIndex = currentNoteIndex
			while currentNoteIndex <= numNotes and notesData[currentNoteIndex][1] < pos do
				-- Check for collision with ship
				local note = notes[currentNoteIndex]
				local noteX = note:getX()
				local noteLeft = noteX + noteMinX
				local noteRight = noteX + noteMaxX
				local leftEdgeIn = noteLeft <= shipLeft and shipLeft <= noteRight
				local rightEdgeIn = noteLeft <= shipRight and shipRight <= noteRight
				if leftEdgeIn or rightEdgeIn then
					if note:getColored() then
						score = score + 1
					else
						score = math.max(0, score - 1)
					end

					local noteLane = note:getLane()
					grid:addNote(noteLane, note:getColored())

					Entity.destroy(note)
				else
					local noteScreenX, noteScreenY = objectLayer:worldToWnd(note:getProp():getWorldLoc())
					local noteWorldX, noteWorldY = fxLayer:wndToWorld(noteScreenX, noteScreenY)
					local effect = Entity.create("Spark")
					effect:setX(noteWorldX)
					effect:setY(noteWorldY)
				end

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
			txt:setText(template:format(pos, err, MOAISim.getPerformance(), numActiveNotes, score))

			self.songPos = pos
			self.songPosError = err
			step = coroutine.yield()
		end
	end

	function createNotes(self, ent, notesData)
		local opts = Options.getDevOptions().ride
		local noteSpeed = opts.note_speed
		local updateDistance = opts.update_distance
		local posOffset = -updateDistance * noteSpeed
		local notes = {}

		for i, noteData in ipairs(notesData) do
			local note = Entity.create("Note")
			local time, lane, colored = unpack(noteData)

			note:setTrackPosition(time + posOffset)
			note:setLane(lane)
			note:setColored(colored)

			notes[i] = note
		end

		return notes
	end
end)
