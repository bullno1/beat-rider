local Options = require "glider.Options"
local MessagePack = require "glider.MessagePack"

return module(function()
	exports {
		"analyze"
	}

	local opts = Options.getDevOptions().analysis

	function analyze(path, progressCallback)
		local cachedContent = getFromCache(path)
		if cachedContent then
			return cachedContent
		else
			local pipeline, bpmBuff, beatBuff, onsetBuff, energyBuff = buildAnalysisPipeline(path)
			if pipeline == nil then return end

			-- Pump until finish or terminated
			while pipeline:pump() do
				if not progressCallback(pipeline:getProgress()) then return end
			end

			-- Generate notes
			local onsets = onsetBuff:getAsTable()
			local beats = beatBuff:getAsTable()
			local notes = generateNotes(onsets, beats)
			local result = {
				notes = notes,
				track = energyBuff:getAsTable(true)
			}
			writeCache(path, result)
			return result
		end
	end

	function getFromCache(path)
		local cacheFilePath = getCacheFilePath(path)

		local fileStream = MOAIFileStream.new()
		if not fileStream:open(cacheFilePath, MOAIFileStream.READ) then return end

		local streamReader = MOAIStreamReader.new()
		if not streamReader:openDeflate(fileStream) then return end

		local readBuff = {}
		local chunkIndex = 1
		repeat
			local blob, bytesRead = streamReader:read(65536)
			if bytesRead > 0 then
				readBuff[chunkIndex] = blob
				chunkIndex = chunkIndex + 1
			end
		until bytesRead == 0

		streamReader:close()
		fileStream:close()

		local success, cacheContent = pcall(MessagePack.unpack, table.concat(readBuff))
		if success then
			print("Found cache at", cacheFilePath)
			return cacheContent
		else
			print("Cache corrupted:", cacheContent)
		end
	end

	function writeCache(path, content)
		local cacheFilePath = getCacheFilePath(path)

		local fileStream = MOAIFileStream.new()
		if not fileStream:open(cacheFilePath, MOAIFileStream.READ_WRITE_NEW) then return end

		local streamWriter = MOAIStreamWriter.new()
		if not streamWriter:openDeflate(fileStream) then return end

		print("Writing cache to", cacheFilePath)
		streamWriter:write(MessagePack.pack(content))
		streamWriter:close()
		fileStream:close()
	end

	function getCacheFilePath(path)
		local absPath = MOAIFileSystem.getAbsoluteFilePath(path)
		return MOAIEnvironment.cacheDirectory.."/"..absPath:gsub("/","-").."-"..getAlgoHash()..".cache"
	end

	function generateNotes(onsets, beats)
		local notes = {}
		local beatIndex = 1
		local numBeats = #beats
		local numOnsets = #onsets
		local lastTime = 0
		local lastCol = 1
		local noteOpts = opts.notes
		local maxDistanceToBeat = noteOpts.max_distance_to_beat
		local clusterMaxLength = noteOpts.cluster_max_length
		local clusterMaxSize = noteOpts.cluster_max_size
		local currentClusterSize = 0

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

			local isScore = distanceToNearestBeat <= maxDistanceToBeat

			-- Column is random with forced clustering
			local col
			if onsetTime - lastTime <= clusterMaxLength and currentClusterSize < clusterMaxSize then
				col = lastCol
				currentClusterSize = currentClusterSize + 1
			else
				col = math.random(3)
				currentClusterSize = 0
			end
			lastTime = onsetTime

			table.insert(notes, { onsetTime, col, isScore })
		end

		return notes
	end

	function buildAnalysisPipeline(path)
		local opts = Options.getDevOptions().analysis
		local source = PcmSource.new()
		source:setChunkSize(65536)
		if not source:open(path) then return end
		local sampRate = source:getSampleRate()
		local hopSize = opts.hop_size

		local tempoDetector = TempoDetector.new()
		tempoDetector:setChunkSize(hopSize)
		tempoDetector:setSampleRate(sampRate)
		source:connect(tempoDetector)

		local bpmBuff = BufferSink.new()
		tempoDetector:getBpmStream():connect(bpmBuff)

		local beatBuff = BufferSink.new()
		tempoDetector:getBeatStream():connect(beatBuff)

		local onsetDetector = OnsetDetector.new()
		onsetDetector:setMethod(opts.onset_detection.method)
		onsetDetector:setChunkSize(hopSize)
		onsetDetector:setSampleRate(sampRate)
		source:connect(onsetDetector)

		local onsetBuff = BufferSink.new()
		onsetDetector:connect(onsetBuff)

		local phaseVocoder = PhaseVocoder.new()
		phaseVocoder:setChunkSize(hopSize)
		source:connect(phaseVocoder)

		local energyFunc = SpecDesc.new()
		energyFunc:setFunction("energy")
		energyFunc:setFrameSize(hopSize * 2)
		phaseVocoder:connect(energyFunc)

		local doubleExp = DoubleExp.new()
		doubleExp:setSmoothingFactors(opts.track.data_smoothing_factor, opts.track.trend_smoothing_factor)
		energyFunc:connect(doubleExp)

		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(opts.track.window_radius)
		doubleExp:connect(centeredMovingAvg)

		local energyBuff = BufferSink.new()
		centeredMovingAvg:connect(energyBuff)

		return source, bpmBuff, beatBuff, onsetBuff, energyBuff
	end

	-- A hash of the analysis parameters and this module's bytecode
	local algoHash = nil
	function getAlgoHash()
		if algoHash == nil then
			local hashWriter = MOAIHashWriter.new()
			assert(hashWriter:openMD5())
			hashWriter:write(tostring(opts))
			local modulePath = assert(package.searchpath("Analysis", package.path))
			local moduleCode = assert(loadfile(modulePath))
			hashWriter:write(string.dump(moduleCode, true))
			hashWriter:close()
			algoHash = hashWriter:getHashHex()
		end

		return algoHash
	end
end)
