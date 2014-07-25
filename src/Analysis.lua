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
			local pipeline, buffers = buildAnalysisPipeline(path)
			if pipeline == nil then return end

			-- Pump until finish or terminated
			while pipeline:pump() do
				if not progressCallback(pipeline:getProgress()) then return end
			end

			-- Generate notes
			local onsets = buffers.onsets:getAsTable()
			local rawEnergy = buffers.rawEnergy:getAsTable(true)
			local sampRate = pipeline:getInfo()
			local notes = generateNotes(onsets, rawEnergy, sampRate, opts.hop_size)

			-- Generate track
			local wave = buffers.wave:getAsTable(true)
			local base = buffers.base:getAsTable(true)
			local track = generateTrack(wave, base)

			local result = {
				notes = notes,
				track = track,
				slope = buffers.slope:getAsTable(true)
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

	function generateTrack(wave, base)
		local result = {}

		for i, baseHeight in ipairs(base) do
			result[i] = baseHeight - wave[i]
		end

		return result
	end

	function generateNotes(onsets, energy, sampRate, hopSize)
		local noteOpts = opts.notes
		local energyThreshold = noteOpts.energy_threshold
		local clusterMaxGap = noteOpts.cluster_max_gap
		local clusterMaxSize = noteOpts.cluster_max_size
		local sameColThreshold = noteOpts.same_column_threshold
		local closeColThreshold = noteOpts.close_column_threshold
		local avoidThreshold = noteOpts.avoid_threshold

		local notes = {}
		local lastTime = 0
		local colored = false
		local cluster = {}

		local previousClusterTime = 0
		local previousClusterColored = false
		local previousClusterColumn = 2

		for index, onsetTime in ipairs(onsets) do
			local energyIndex = math.floor(onsetTime * sampRate / hopSize + 1.5)
			local energy = energy[energyIndex]
			colored = colored or energy >= energyThreshold

			local clusterSize = #cluster
			local noteNotInCluster = onsetTime - lastTime > clusterMaxGap
			local clusterLimitReached = clusterSize >= clusterMaxSize
			local clusterFormed = clusterSize > 0
			if clusterFormed and ( noteNotInCluster or clusterLimitReached ) then -- create a cluster of notes
				local clusterTime = cluster[1]
				local clusterDistance = clusterTime - previousClusterTime

				-- Pick a column based on serveral criteria
				local column
				if colored then
					if previousClusterColored then -- try to stay close
						column = closeRandomColumn(
							previousClusterColumn,
							clusterDistance,
							sameColThreshold,
							closeColThreshold
						)
					else -- try to avoid
						column = differentRandomColumn(previousClusterColumn, clusterDistance, avoidThreshold)
					end
				else
					if previousClusterColored then -- try to avoid
						column = differentRandomColumn(previousClusterColumn, clusterDistance, avoidThreshold)
					else -- try to stay close
						column = closeRandomColumn(
							previousClusterColumn,
							clusterDistance,
							sameColThreshold,
							closeColThreshold
						)
					end
				end

				local gap = clusterSize > 1 and ((cluster[clusterSize] - cluster[1]) / (clusterSize - 1)) or 0
				for i, time in ipairs(cluster) do
					table.insert(notes, { clusterTime + (i - 1) * gap, column, colored, i == 1} )
				end

				table.clear(cluster)
				previousClusterColored = colored
				previousClusterTime = clusterTime
				previousClusterColumn = column
				colored = false
			end

			table.insert(cluster, onsetTime)

			lastTime = onsetTime
		end

		return notes
	end

	function differentRandomColumn(previousColumn, clusterDistance, avoidThreshold)
		local column

		if clusterDistance <= avoidThreshold then
			repeat
				column = math.random(3)
			until column ~= previousColumn
		else
			column = math.random(3)
		end

		return column
	end

	function closeRandomColumn(previousColumn, clusterDistance, sameColThreshold, closeColThreshold)
		local column

		if clusterDistance <= sameColThreshold then -- use the same column
			column = previousColumn
		elseif clusterDistance <= closeColThreshold then -- one column apart
			repeat
				column = math.random(3)
			until math.abs(column - previousColumn) == 1
		else -- anything
			column = math.random(3)
		end

		return column
	end

	function buildAnalysisPipeline(path)
		local opts = Options.getDevOptions().analysis
		local source = PcmSource.new()
		source:setChunkSize(65536)
		if not source:open(path) then return end
		local sampRate = source:getInfo()
		local hopSize = opts.hop_size

		-- Onset
		local onsetDetector = OnsetDetector.new()
		onsetDetector:setMethod(opts.onset_detection.method)
		onsetDetector:setChunkSize(opts.onset_detection.hop_size)
		onsetDetector:setSampleRate(sampRate)
		source:connect(onsetDetector)

		local onsetBuff = BufferSink.new()
		onsetDetector:connect(onsetBuff)

		-- Phase vocoder
		local phaseVocoder = PhaseVocoder.new()
		phaseVocoder:setChunkSize(hopSize)
		source:connect(phaseVocoder)

		-- Energy
		local energyFunc = SpecDesc.new()
		energyFunc:setFunction("energy")
		energyFunc:setFrameSize(hopSize * 2)
		phaseVocoder:connect(energyFunc)

		local doubleExp = DoubleExp.new()
		doubleExp:setSmoothingFactors(opts.track.data_smoothing_factor, opts.track.trend_smoothing_factor)
		energyFunc:connect(doubleExp)

		-- Track
		local waveAvg = CenteredMovingAvg.new()
		waveAvg:setWindowRadius(opts.track.wave_window_radius)
		doubleExp:connect(waveAvg)

		local waveBuff = BufferSink.new()
		waveAvg:connect(waveBuff)

		local baseAvg = CenteredMovingAvg.new()
		baseAvg:setWindowRadius(opts.track.base_window_radius)
		doubleExp:connect(baseAvg)

		local baseBuff = BufferSink.new()
		baseAvg:connect(baseBuff)

		-- Slope
		local specflux = SpecDesc.new()
		specflux:setFunction("specflux")
		phaseVocoder:connect(specflux)

		local doubleExp = DoubleExp.new()
		doubleExp:setSmoothingFactors(opts.slope.data_smoothing_factor, opts.slope.trend_smoothing_factor)
		specflux:connect(doubleExp)

		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(opts.slope.window_radius)
		doubleExp:connect(centeredMovingAvg)

		local slopeBuff = BufferSink.new()
		centeredMovingAvg:connect(slopeBuff)

		local rawEnergyBuff = BufferSink.new()
		energyFunc:connect(rawEnergyBuff)

		local buffers = {
			onsets = onsetBuff,
			rawEnergy = rawEnergyBuff,
			base = baseBuff,
			wave = waveBuff,
			slope = slopeBuff
		}

		return source, buffers
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
