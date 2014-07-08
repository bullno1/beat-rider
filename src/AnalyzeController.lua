local Entity = require "glider.Entity"
local Director = require "glider.Director"
local Analysis = require "Analysis"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(analyze, self, ent, Director.getSceneData())
	end)

	function analyze(self, ent, path)
		local result = Analysis.analyze(path, reportProgress)
		if result then
			result.path = path
			Director.changeScene("ride", result)
		else
			Entity.getByName("txtProgress"):setText("Failed")
		end
	end

	local statusTemplate = "Loading %d%%"
	function reportProgress(progress)
		local txtProgress = Entity.getByName("txtProgress")
		txtProgress:setText(statusTemplate:format(math.floor(progress * 100)))
		coroutine.yield()
		return true
	end
end)
