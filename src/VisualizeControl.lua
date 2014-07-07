local Entity = require "glider.Entity"
local Options = require "glider.Options"
local Asset = require "glider.Asset"
local Screen = require "glider.Screen"

return component(..., function()
	depends "glider.Actor"

	msg("onCreate", function(self, ent)
		local path = "assets/sfx/Radioactive.mp3"
		ent:spawnCoroutine(visualize, self, ent, path)
	end)

	function visualize(self, ent, path)
		local txtProgress = Entity.getByName("txtProgress")

		local pipeline, bpmBuff, energyBuff = buildAnalysisPipeline(path)
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

		local graphs = {}

		local timeScale = 200
		local hopSize = Options.getDevOptions().analysis.hop_size
		local bpmGraph = generateGraph(bpmBuff:getAsTable(), sampRate, hopSize, timeScale, {1, 0, 0})
		local mesh = Entity.create("glider/Mesh")
		mesh:getProp():setDeck(bpmGraph)
		mesh:setPartitionName("Visualization")
		table.insert(graphs, mesh)

		local energyGraph = generateGraph(energyBuff:getAsTable(true), sampRate, hopSize, timeScale, {0, 1, 0})
		local mesh = Entity.create("glider/Mesh")
		mesh:getProp():setDeck(energyGraph)
		mesh:setPartitionName("Visualization")
		table.insert(graphs, mesh)

		local screenWidth, screenHeight = Screen.getSize "dp"
		for i, graph in ipairs(graphs) do
			local xMin, yMin, zMin, xMax, yMax, zMax = graph:getProp():getBounds()
			local height = yMax - yMin
			local yScale = screenHeight / height
			graph:setYScale(yScale)
		end

		song:play()

		local fmt = "Playing %.1f\nFPS: %.1f\nError: %.3f\nStep: %.3f"
		local pos = song:getPosition()
		local step = 0
		local graphCam = Entity.getByName("GraphCam")
		while true do
			local position = song:getPosition()
			pos = pos + step
			local err = song:getPosition() - pos
			txtProgress:setText(fmt:format(position, MOAISim.getPerformance(), math.abs(err), step))
			graphCam:setX(pos * 200)
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

		--local beatBuff = BufferSink.new()
		--tempoDetector:getBeatStream():connect(beatBuff)

		--local onsetDetector = OnsetDetector.new()
		--onsetDetector:setMethod(opts.onset_detection.method)
		--onsetDetector:setChunkSize(hopSize)
		--onsetDetector:setSampleRate(sampRate)
		--source:connect(onsetDetector)

		--local onsetBuff = BufferSink.new()
		--onsetDetector:connect(onsetBuff)

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

		return source, bpmBuff, energyBuff
	end
end)
