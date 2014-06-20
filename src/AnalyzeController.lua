local Entity = require "glider.Entity"
local Director = require "glider.Director"
local MessagePack = require "glider.MessagePack"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		local filePath = "assets/sfx/IllShowYou.mp3"
		ent:spawnCoroutine(analyze, self, ent, filePath)
	end)

	function analyze(self, ent, path)
		local aubio = Aubio.new()
		aubio:setHopSize(512)
		aubio:addSpectralDescriptor("energy")

		-- Check if analysis result was cached
		local cachedResult = getFromCache(path)
		if cachedResult then
			aubio:skipAnalysis()
			print("Cache validated. Analysis skipped")
		end

		aubio:load(path)

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

		-- Try to obtain information from cache
		local beats, onsets, energies

		if cachedResult then
			beats = cachedResult.beats
			onsets = cachedResult.onsets
			energies = cachedResult.energies
		else
			beats = aubio:getBeats()
			onsets = aubio:getOnsets()
			energies = aubio:getSpectralDescription("energy")
			local cache = {
				beats = beats,
				onsets = onsets,
				energies = energies,
				hopSize = 512
			}
			local cacheFilePath = getCacheFilePath(path)
			local cacheFile = io.open(cacheFilePath, "w+b")
			print("Writing cache to", cacheFilePath)
			cacheFile:write(MessagePack.pack(cache))
			cacheFile:close()
		end

		-- Generate level from data
		local smoothedEnergies = normalize(centeredMovingAvg(doubleExp(energies, 0.5, 0.5), 20))

		local notes = {}
		local maxDistance = 0.15
		local beatIndex = 1
		local numBeats = #beats
		local numOnsets = #onsets

		for index, onsetTime in ipairs(onsets) do
			-- If the note is near to a beat, it is a score note
			-- otherwise, it is a penalty note
			
			-- Adjust beatIndex so that it is the closest beat before this note
			local nextBeat = beats[math.min(beatIndex + 1, numBeats)]
			while nextBeat < onsetTime do
				nextBeat = beats[math.min(beatIndex + 1, numBeats)]
				beatIndex = beatIndex + 1
			end

			local currentBeat = beats[beatIndex]
			local distanceNextBeat = math.abs(nextBeat - onsetTime)
			local distanceToCurrentBeat = math.abs(currentBeat - onsetTime)
			local distanceToNearestBeat = math.min(distanceNextBeat, distanceToCurrentBeat)
			print(distanceToNearestBeat, distanceToNearestBeat < maxDistance)

			notes[index] = {
				time = onsetTime,
				score = distanceToNearestBeat < maxDistance
			}

			reportProgress("Finding notes", index, numOnsets)
		end

		local sceneData = {
			aubio = aubio,
			notes = notes,
			track = smoothedEnergies
		}
		Director.changeScene("scenes.Ride", sceneData)
	end

	function getFromCache(path)
		local cacheFilePath = getCacheFilePath(path)
		local result

		if MOAIFileSystem.checkFileExists(cacheFilePath) then
			-- TODO: timestamp check
			print("Found cache at", cacheFilePath)
			local cacheFile = io.open(cacheFilePath, "rb")
			local success, cacheContent = pcall(MessagePack.unpack, cacheFile:read("*a"))
			if success
				and type(cacheContent) == "table"
				and cacheContent.hopSize == 512
				and cacheContent.beats ~= nil
				and cacheContent.onsets ~= nil
				and cacheContent.energies ~= nil then

				result = cacheContent
			end
			cacheFile:close()
		end

		return result
	end

	function getCacheFilePath(path)
		local absPath = MOAIFileSystem.getAbsoluteFilePath(path)
		return MOAIEnvironment.cacheDirectory.."/"..absPath:gsub("/","-")..".cache"
	end

	local statusTemplate = "%s %d%%"
	function reportProgress(currentAction, currentIndex, total, batchSize)
		local txtProgress = Entity.getByName("txtProgress")
		if currentIndex % math.floor(total / 100 * 5) == 0 then
			txtProgress:setText(statusTemplate:format(currentAction, currentIndex / total * 100))
			coroutine.yield()
		end
	end

	function movingAvg(data, windowSize)
		local sum = 0
		for i = 1, windowSize do
			sum = sum + data[i]
		end
		for i = windowSize + 1, #data do
			sum = sum - data[i - windowSize] + data[i]
			data[i] = sum / windowSize
		end
	end

	function expMovingAvg(data, smoothingFactor)
		local lastSmooth = 0
		local lastData = 0
		for i, rawSample in ipairs(data) do
			local smoothedSample = smoothingFactor * lastData + (1 - smoothingFactor) * lastSmooth
			data[i] = smoothedSample
			lastSmooth = smoothedSample
			lastData = rawSample
		end
	end

	function doubleExp(data, dataSmoothingFactor, trendSmoothingFactor)
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

	function centeredMovingAvg(data, radius)
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

	function normalize(data)
		local numPoints = #data

		local min, max = data[1], data[1]
		for i, num in ipairs(data) do
			min = math.min(num, min)
			max = math.max(num, max)
			reportProgress("Finding bounds", i, numPoints)
		end

		local result = {}
		local range = max - min
		for i, num in ipairs(data) do
			result[i] = (num - min) / range
			reportProgress("Normalizing", i, numPoints)
		end

		return result
	end

	function integrate(data)
		local result = {}
		local current = 0

		local numPoints = #data
		for i, num in ipairs(data) do
			current = current + num
			result[i] = current
			reportProgress("Integrating", i, numPoints, 1000)
		end

		return result
	end

	function quantize(data, numLevels)
		local result = {}

		local numPoints = #data
		for i, num in ipairs(data) do
			result[i] = math.floor(num * numLevels + 0.5) / numLevels
			reportProgress("Quantizing", i, numPoints)
		end

		return result
	end
end)
