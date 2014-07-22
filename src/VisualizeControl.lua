local Entity = require "glider.Entity"
local Options = require "glider.Options"
local Asset = require "glider.Asset"
local Screen = require "glider.Screen"
local Director = require "glider.Director"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(visualize, self, ent, Director.getSceneData())
	end)

	function visualize(self, ent, path)
		local txtProgress = Entity.getByName("txtProgress")

		local pipeline, buffers = buildAnalysisPipeline(path)
		local progressFmt = "Analyzing %d%%"
		while pipeline:pump() do
			local progress = pipeline:getProgress()
			txtProgress:setText(progressFmt:format(math.floor(progress * 100)))
			coroutine.yield()
		end

		local progressFmt = "Loading song %d%%"
		local song = UntzSoundEx.new()
		song:open(path)
		repeat
			local status, progress = song:loadChunk(65536)
			if status == UntzSoundEx.STATUS_MORE then
				txtProgress:setText(progressFmt:format(math.floor(progress * 100)))
			end
			coroutine.yield()
		until status ~= UntzSoundEx.STATUS_MORE

		local sampRate = song:getInfo()
		local timeScale = 250
		local hopSize = Options.getDevOptions().analysis.hop_size
		local screenWidth, screenHeight = Screen.getSize "dp"

		local function showGraph(graphMesh)
			local graph = Entity.create("glider/Mesh")
			graph:getProp():setDeck(graphMesh)
			graph:setPartitionName("Visualization")
			local xMin, yMin, zMin, xMax, yMax, zMax = graph:getProp():getBounds()
			local height = yMax - yMin
			local yScale = screenHeight / height
			graph:setYScale(yScale)
			return graph
		end

		local colors = {
			bpm = { 1, 0, 0},
			energy = { 0, 1, 0 },
			energyBase = { 0, 1, 0, 0.2 },
			slope = { 0, 0, 1 }
		}

		for graphName, color in pairs(colors) do
			local graphData = buffers[graphName]:getAsTable(true)
			local graphMesh = generateGraph(graphData, sampRate, hopSize, timeScale, color)
			showGraph(graphMesh)
		end

		local energyData = buffers.energy:getAsTable(true)
		local energyBaseData = buffers.energyBase:getAsTable(true)
		for i, y in ipairs(energyData) do
			energyData[i] = energyBaseData[i] - energyData[i]
		end

		local wave = showGraph(generateGraph(energyData, sampRate, hopSize, timeScale, {1, 1, 1, 1}))
		wave:setYScale(300)
		wave:setY(screenHeight / 2)

		local onsets = buffers.onset:getAsTable()
		local rawEnergy = buffers.rawEnergy:getAsTable(true)
		local threshold = Options.getDevOptions().analysis.notes.energy_threshold
 
		local onsetAlphas = {}
		for i, onsetTime in ipairs(onsets) do
			local energyIndex = math.floor(onsetTime * sampRate / hopSize) + 1
			local energy = rawEnergy[energyIndex]
			onsetAlphas[i] = energy >= threshold and 1 or 0.2
		end

		local onsetMarkers = generateMarker(onsets, sampRate, hopSize, timeScale, 1, 1, 0, onsetAlphas)
		showGraph(onsetMarkers)

		local slope = buffers.slope:getAsTable(true)
		local lastSlope = slope[1]
		local count = 0
		local turnStart = 0
		local start = 0
		local markers = {}
		local alphas = {}
		for i, slope in ipairs(slope) do
			if slope < lastSlope then
				if count == 0 then
					turnStart = i
					start = slope
				end
				count = count + 1
			else
				if count > 150 and start - slope > 0.16 then
					print("Turn:", turnStart * hopSize / sampRate, count, start - slope)
					table.insert(markers, turnStart * hopSize / sampRate)
					table.insert(markers, i * hopSize / sampRate)
					table.insert(alphas, 1)
					table.insert(alphas, 0.2)
				end
				count = 0
			end

			lastSlope = slope
		end
		local markers = generateMarker(markers, sampRate, hopSize, timeScale, 1, 0, 1, alphas)
		showGraph(markers)

		song:play()

		local bpm = buffers.bpm:getAsTable()
		local fmt = "Playing %.1f\nFPS: %.1f\nError: %.3f\nBpm: %.3f"
		local pos = song:getPosition()
		local step = 0
		local graphCam = Entity.getByName("GraphCam")
		while true do
			local position = song:getPosition()
			local bpm = bpm[math.floor(position * sampRate / hopSize) + 1]
			pos = pos + step
			local err = position - pos
			txtProgress:setText(fmt:format(position, MOAISim.getPerformance(), math.abs(err), bpm))
			graphCam:setX(pos * timeScale)
			pos = pos + 0.001 * err
			step = coroutine.yield()
		end
	end

	function generateGraph(data, sampRate, hopSize, timeScale, color)
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 2)
		format:declareColor(2, MOAIVertexFormat.GL_UNSIGNED_BYTE)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		vbo:reserveVerts(#data)
		for index, y in ipairs(data) do
			local x = (index - 1) * hopSize / sampRate * timeScale
			vbo:writeFloat(x, y)
			vbo:writeColor32(unpack(color))
		end
		vbo:bless()

		local track = MOAIMesh.new()
		track:setVertexBuffer(vbo)
		track:setPrimType(MOAIMesh.GL_LINE_STRIP)
		local graphShader = Asset.get("shader", "graph")
		track:setShader(graphShader)

		return track
	end

	function generateMarker(data, sampRate, hopSize, timeScale, r, g, b, as)
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 2)
		format:declareColor(2, MOAIVertexFormat.GL_UNSIGNED_BYTE)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		vbo:reserveVerts(#data * 2)
		for index, time in ipairs(data) do
			local x = time * timeScale
			vbo:writeFloat(x, 1)
			vbo:writeColor32(r, g, b, as[index])
			vbo:writeFloat(x, 0)
			vbo:writeColor32(r, g, b, as[index])
		end
		vbo:bless()

		local track = MOAIMesh.new()
		track:setVertexBuffer(vbo)
		track:setPrimType(MOAIMesh.GL_LINES)
		local graphShader = Asset.get("shader", "graph")
		track:setShader(graphShader)

		return track
	end

	function buildAnalysisPipeline(path)
		local opts = Options.getDevOptions().analysis
		local source = PcmSource.new()
		source:setChunkSize(65536)
		if not source:open(path) then return end
		local sampRate = source:getInfo()
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
		onsetDetector:setChunkSize(opts.onset_detection.hop_size)
		onsetDetector:setSampleRate(sampRate)
		source:connect(onsetDetector)

		local onsetBuff = BufferSink.new()
		onsetDetector:connect(onsetBuff)

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

		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(opts.track.wave_window_radius)
		doubleExp:connect(centeredMovingAvg)

		local energyBuff = BufferSink.new()
		centeredMovingAvg:connect(energyBuff)

		-- Energy base
		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(opts.track.base_window_radius)
		doubleExp:connect(centeredMovingAvg)

		local energyBuff2 = BufferSink.new()
		centeredMovingAvg:connect(energyBuff2)

		local rawEnergyBuff = BufferSink.new()
		energyFunc:connect(rawEnergyBuff)

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

		local buffers = {
			bpm = bpmBuff,
			energy = energyBuff,
			energyBase = energyBuff2,
			onset = onsetBuff,
			slope = slopeBuff,
			rawEnergy = rawEnergyBuff
		}

		return source, buffers
	end
end)
