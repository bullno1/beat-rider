local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Analysis = require "Analysis"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(analyze, self, ent, Director.getSceneData())
	end)

	function analyze(self, ent, path)
		-- Analyze
		local statusTemplate = "Analyzing %d%%"
		local txtProgress = Entity.getByName("txtProgress")
		local function reportProgress(progress)
			txtProgress:setText(statusTemplate:format(math.floor(progress * 100)))
			coroutine.yield()
			return true
		end

		local result = Analysis.analyze(path, reportProgress)
		if not result then
			Entity.getByName("txtProgress"):setText("Failed")
			return
		end

		-- Load song
		statusTemplate = "Loading %d%%"
		local song = UntzSoundEx.new()
		assert(song:open(path), "Failed to load song")
		repeat
			local status, progress = song:loadChunk(65536)
			if status == UntzSoundEx.STATUS_MORE then
				reportProgress(progress)
			end
			coroutine.yield()
		until status ~= UntzSoundEx.STATUS_MORE

		result.song = song
		Director.changeScene("ride", result)
	end
end)
