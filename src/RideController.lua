local Entity = require "glider.Entity"
local Director = require "glider.Director"

return component(..., function()
	depends "glider.Actor"

	local ride
	msg("onCreate", function(self, ent)
		ent:spawnCoroutine(ride, self, ent)
	end)

	local TIME_SCALE = 400
	local createMarkers
	ride = function(self, ent, path)
		local sceneData = Director.getSceneData()
		-- Create event markers
		for i, time in ipairs(sceneData.beats) do
			local marker = Entity.create("presets.Marker")
			marker:setX(time * TIME_SCALE)
			marker:setY(-200)
		end

		for i, time in ipairs(sceneData.onsets) do
			local marker = Entity.create("presets.Marker")
			marker:setX(time * TIME_SCALE)
			marker:setY(-150)
		end
		local mesh = MOAIMesh.new()
		local vbo = MOAIVertexBuffer.new()
		local format = MOAIVertexFormat.new()
		format:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
		vbo:setFormat(format)

		local aubio = sceneData.aubio
		local sampRate, numFrames = aubio:getAudioInfo()
		vbo:reserveVerts(#sceneData.energies)
		for index, y in ipairs(sceneData.energies) do
			vbo:writeFloat(index * 1024 / sampRate * TIME_SCALE, y, 0)
		end
		vbo:bless()
		mesh:setVertexBuffer(vbo)
		mesh:setPrimType(MOAIMesh.GL_LINE_STRIP)
		local vsh = [[
			attribute vec4 position;

			uniform mat4 transform;

			void main()
			{
				gl_Position = position * transform;
			}
		]]
		local fsh = [[
			void main()
			{
				gl_FragColor = vec4(1, 1, 1, 1);
			}
		]]
		local shader = MOAIShader.new()
		shader:load(vsh, fsh)
		shader:reserveUniforms(1)
		shader:declareUniform(1, "transform", MOAIShader.UNIFORM_WORLD_VIEW_PROJ)
		shader:setVertexAttribute(1, "position")
		mesh:setShader(shader)

		local meshInstance = Entity.create("glider.presets.Mesh")
		meshInstance:getProp():setDeck(mesh)
		meshInstance:setLayerName("Visualizer")

		-- Move visualizations with music
		aubio:play()
		local fmt = "Playing %.1f\nFPS: %.1f\nError: %.3f\nStep: %.3f"
		local camera = Director.getCamera("Visualizer")
		local pos = aubio:getPosition()
		local ship = Entity.getByName("Ship")
		local step = 0
		local halfWidth = MOAIGfxDevice.getViewSize() / 2
		local txtProgress = Entity.getByName("txtProgress")
		while true do
			local position = aubio:getPosition()
			pos = pos + step
			local err = aubio:getPosition() - pos
			txtProgress:setText(fmt:format(position, MOAISim.getPerformance(), math.abs(err), step))
			camera:setX(pos * TIME_SCALE + halfWidth)
			pos = pos + 0.001 * err
			step = coroutine.yield()
		end
	end
end)
