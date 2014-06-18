local Entity = require "glider.Entity"
local Action = require "glider.Action"
local Director = require "glider.Director"
local MessagePack = require "glider.MessagePack"

return component(..., function()
	depends "glider.Actor"

	local process
	msg("onCreate", function(self, ent)
		local filePath = "assets/sfx/8282.mp3"
		ent:spawnCoroutine(process, self, ent, filePath)
	end)

	local TIME_SCALE = 300
	local createMarkers
	process = function(self, ent, path)
		local aubio = Aubio.new()
		aubio:setHopSize(1024)
		aubio:addSpectralDescriptor("energy")

		-- Check if analysis result was cached
		local absPath = MOAIFileSystem.getAbsoluteFilePath(path)
		local cacheFilePath = MOAIEnvironment.cacheDirectory.."/"..absPath:gsub("/","-")..".cache"
		local cache
		if MOAIFileSystem.checkFileExists(cacheFilePath) then
			-- TODO: timestamp check
			print("Found cache at", cacheFilePath)
			local cacheFile = io.open(cacheFilePath, "rb")
			local success, cacheContent = pcall(MessagePack.unpack, cacheFile:read("*a"))
			if success and type(cacheContent) == "table" and cacheContent.beats ~= nil and cacheContent.onsets ~= nil then
				self.cacheContent = cacheContent
				cache = cacheContent
				aubio:skipAnalysis()
				print("Cache validated. Analysis skipped")
			end
			cacheFile:close()
		end

		aubio:load("assets/sfx/8282.mp3")

		-- Wait until audio is loaded and analyzed (if needed)
		local txtProgress = Entity.getByName "txtProgress"
		local status
		repeat
			status = aubio:getStatus()
			local progress = aubio:getProgress()
			txtProgress:setText("Loading "..tostring(math.floor(progress * 100)) .. "%")

			coroutine.yield()
		until status ~= Aubio.STATUS_LOADING

		if status ~= Aubio.STATUS_LOADED then
			return
		end

		-- Create visualizations
		local beats, onsets

		if cache then
			beats = cache.beats
			onsets = cache.onsets
		else
			beats = aubio:getBeats()
			onsets = aubio:getOnsets()
			cache = {
				beats = beats,
				onsets = onsets
			}
			local cacheFile = io.open(cacheFilePath, "w+b")
			print("Writing cache")
			cacheFile:write(MessagePack.pack(cache))
			cacheFile:close()
		end

		for i, time in ipairs(beats) do
			local marker = Entity.create("presets.Marker")
			marker:setX(time * 300)
			marker:setY(-200)
		end

		for i, time in ipairs(onsets) do
			local marker = Entity.create("presets.Marker")
			marker:setX(time * 300)
			marker:setY(-150)
		end

		-- Move visualizations with music
		aubio:play()
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
			camera:setX(pos * TIME_SCALE)
			ship:setZRotation(pos * 10)
			--pos = pos + 0.1 * err
			step = coroutine.yield()
		end
	end
end)
