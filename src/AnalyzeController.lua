local Entity = require "glider.Entity"
local Director = require "glider.Director"
local MessagePack = require "glider.MessagePack"

return component(..., function()
	depends "glider.Actor"

	local analyze
	msg("onCreate", function(self, ent)
		local filePath = "assets/sfx/8282.mp3"
		ent:spawnCoroutine(analyze, self, ent, filePath)
	end)

	local reportProgress
	local movingAvg, expMovingAvg, doubleExp, centeredMovingAvg
	local normalize

	analyze = function(self, ent, path)
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
			if success
				and type(cacheContent) == "table"
				and cacheContent.beats ~= nil
				and cacheContent.onsets ~= nil
				and cacheContent.energies ~= nil then

				self.cacheContent = cacheContent
				cache = cacheContent
				aubio:skipAnalysis()
				print("Cache validated. Analysis skipped")
			end
			cacheFile:close()
		end

		aubio:load(absPath)

		-- Wait until audio is loaded and analyzed (if needed)
		local txtProgress = Entity.getByName("txtProgress")
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

		-- Preprocess data
		local beats, onsets, energies

		-- Try to obtain information from cache
		if cache then
			beats = cache.beats
			onsets = cache.onsets
			energies = cache.energies
		else
			beats = aubio:getBeats()
			onsets = aubio:getOnsets()
			energies = aubio:getSpectralDescription("energy")
			cache = {
				beats = beats,
				onsets = onsets,
				energies = energies
			}
			local cacheFile = io.open(cacheFilePath, "w+b")
			print("Writing cache to", cacheFilePath)
			cacheFile:write(MessagePack.pack(cache))
			cacheFile:close()
		end

		-- Normalize energy
		local energies = normalize(energies)
		local smooth1 = doubleExp(energies, 0.3, 0.3)
		local smoothedEnergies = centeredMovingAvg(smooth1, 10)
		local sceneData = {
			aubio = aubio,
			beats = beats,
			onsets = onsets,
			energies = smoothedEnergies
		}
		Director.changeScene("scenes.Ride", sceneData)
	end

	local statusTemplate = "%s %d%%"
	reportProgress = function(currentAction, currentIndex, total, batchSize)
		local txtProgress = Entity.getByName("txtProgress")
		if currentIndex % batchSize == 0 then
			txtProgress:setText(statusTemplate:format(currentAction, currentIndex / total * 100))
			coroutine.yield()
		end
	end

	movingAvg = function(data, windowSize)
		local sum = 0
		for i = 1, windowSize do
			sum = sum + data[i]
		end
		for i = windowSize + 1, #data do
			sum = sum - data[i - windowSize] + data[i]
			data[i] = sum / windowSize
		end
	end

	expMovingAvg = function(data, smoothingFactor)
		local lastSmooth = 0
		local lastData = 0
		for i, rawSample in ipairs(data) do
			local smoothedSample = smoothingFactor * lastData + (1 - smoothingFactor) * lastSmooth
			data[i] = smoothedSample
			lastSmooth = smoothedSample
			lastData = rawSample
		end
	end

	doubleExp = function(data, dataSmoothingFactor, trendSmoothingFactor)
		local result = {}
		local lastSmooth = data[2]
		local lastTrend = data[2] - data[1]
		result[1] = data[1]
		result[2] = lastSmooth
		local numData = #data
		for i = 3, numData do
			local smooth = dataSmoothingFactor * data[i] + (1 - dataSmoothingFactor) * (lastSmooth + lastTrend)
			local trend = trendSmoothingFactor * (smooth - lastSmooth) + (1 - trendSmoothingFactor) * lastTrend

			result[i] = smooth

			lastSmooth = smooth
			lastTrend = trend
			reportProgress("Smoothing", i, numData, 1000)
		end
		return result
	end

	centeredMovingAvg = function(data, radius)
		local result = {}
		for i = 1, radius do
			result[i] = data[i]
		end
		local numData = #data
		local sum = 0
		for i = 1, radius * 2 + 1 do
			sum = sum + data[i]
		end
		result[radius + 1] = sum / (radius * 2 + 1)
		for i = radius + 2, numData - radius do
			sum = sum - data[i - radius - 1] + data[i + radius]
			result[i] = sum / (radius * 2 + 1)
			reportProgress("Averaging", i, numData, 500)
		end
		for i = numData - radius + 1, numData do
			result[i] = data[i]
		end
		return result
	end

	normalize = function(data)
		local min, max = data[1], data[1]
		local numPoints = #data
		for i, num in ipairs(data) do
			min = math.min(num, min)
			max = math.max(num, max)
			reportProgress("Finding bounds", i, numPoints, 1000)
		end

		local result = {}
		local range = max - min
		for i, num in ipairs(data) do
			local normalized = (num - min) / range * 300
			result[i] = normalized
			reportProgress("Normalizing", i, numPoints, 1000)
		end

		return result
	end
end)
