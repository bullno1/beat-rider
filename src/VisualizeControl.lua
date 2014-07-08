local Entity = require "glider.Entity"
local Options = require "glider.Options"
local Asset = require "glider.Asset"
local Screen = require "glider.Screen"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		local path = "assets/sfx/GalaxySupernova.mp3"
		ent:spawnCoroutine(visualize, self, ent, path)
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
		end

		local colors = {
			bpm = { 1, 0, 0},
			energy = { 0, 1, 0 },
			energyBase = { 0, 1, 0, 0.2 },
			slope = { 0, 0, 1 }
		}

		for graphName, color in pairs(colors) do
			local graphData = buffers[graphName]:getAsTable(true)
			print(graphName, #graphData)
			local graphMesh = generateGraph(graphData, sampRate, hopSize, timeScale, color)
			showGraph(graphMesh)
		end

		local colors = {
			onset = { 1, 1, 0, 0.5 }
		}
		local bpm = buffers.bpm:getAsTable()

		local rawEnergy = buffers.rawEnergy:getAsTable(true)
		for markerName, color in pairs(colors) do
			local graphData = buffers[markerName]:getAsTable()
			local graphMesh = generateMarker(graphData, sampRate, hopSize, timeScale, color, rawEnergy)
			showGraph(graphMesh)
		end

		song:play()

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

	function generateMarker(data, sampRate, hopSize, timeScale, color, alphas)
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 2)
		format:declareColor(2, MOAIVertexFormat.GL_UNSIGNED_BYTE)

		local vbo = MOAIVertexBuffer.new()
		vbo:setFormat(format)

		vbo:reserveVerts(#data * 2)
		for index, time in ipairs(data) do
			local x = time * timeScale
			local alphaIndex = math.floor(time * sampRate / hopSize) + 1
			local energy = alphas[alphaIndex]
			local alpha
			if energy > 0.05 then
				alpha = 1
			elseif energy < 0.002 then
				alpha = 0.0
			else
				alpha = 0.2
			end
			local r, g, b = unpack(color)
			vbo:writeFloat(x, 1)
			vbo:writeColor32(r, g, b, alpha)
			vbo:writeFloat(x, 0)
			vbo:writeColor32(r, g, b, alpha)
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
		onsetDetector:setMethod("kl")
		onsetDetector:setChunkSize(hopSize)
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
		doubleExp:setSmoothingFactors(0.03, 0.03)
		energyFunc:connect(doubleExp)

		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(10)
		doubleExp:connect(centeredMovingAvg)

		local energyBuff = BufferSink.new()
		centeredMovingAvg:connect(energyBuff)

		-- Energy base
		local doubleExp = DoubleExp.new()
		doubleExp:setSmoothingFactors(0.03, 0.03)
		energyFunc:connect(doubleExp)

		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(20)
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
		doubleExp:setSmoothingFactors(0.01, 0.1)
		specflux:connect(doubleExp)

		local centeredMovingAvg = CenteredMovingAvg.new()
		centeredMovingAvg:setWindowRadius(10)
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
