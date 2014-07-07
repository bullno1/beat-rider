local Asset = require "glider.Asset"

return function(name)
	local sources = {}
	local sourcesSemantics = {}

	local path = "./assets/meshes/"..name
	local xml = MOAIXmlParser.parseFile(path)
	local importSettings = dofile(path..".lua")
	local transform = MOAITransform.new()
	transform:setLoc(0, 0, 0)
	transform:setRot(unpack(importSettings.rotation or {0, 0, 0}))
	transform:setScl(unpack(importSettings.scale or {1, 1, 1}))
	transform:forceUpdate()
	local xmlMesh = xml.children.library_geometries[1].children.geometry[1].children.mesh[1]	
	local xmlVerticesInputs = xmlMesh.children.vertices[1].children.input

	for index, input in ipairs(xmlVerticesInputs) do
		local semantic = input.attributes.semantic
		sourcesSemantics[input.attributes.source:sub(2)] = semantic
	end

	for index, source in ipairs(xmlMesh.children.source) do
		local sourceId = source.attributes.id
		local semantic = sourcesSemantics[sourceId]
		local strData = source.children.float_array[1].value
		local sourceData = {}
		for str in string.gmatch(strData, "%S+") do
			table.insert(sourceData, assert(tonumber(str)))
		end
		sources[semantic] = sourceData
	end

	local vertexFormat = MOAIVertexFormat.new()
	vertexFormat:declareCoord(1, MOAIVertexFormat.GL_FLOAT, 3)
	vertexFormat:declareUV(2, MOAIVertexFormat.GL_FLOAT, 2)
	vertexFormat:declareColor(3, MOAIVertexFormat.GL_UNSIGNED_BYTE)
	local vbo = MOAIVertexBuffer.new()
	vbo:setFormat(vertexFormat)

	local positions = sources.POSITION
	local texCoords = sources.TEXCOORD
	local numVerts = #positions / 3
	vbo:reserveVerts(numVerts)
	for vertexIndex = 1, numVerts do
		local x = positions[(vertexIndex - 1) * 3 + 1]
		local y = positions[(vertexIndex - 1) * 3 + 2]
		local z = positions[(vertexIndex - 1) * 3 + 3]
		local u = texCoords[(vertexIndex - 1) * 2 + 1]
		local v = texCoords[(vertexIndex - 1) * 2 + 2]

		vbo:writeFloat(transform:modelToWorld(x, y, z))
		--vbo:writeFloat(x, y, z)
		vbo:writeFloat(u, v)
		vbo:writeColor32(1, 1, 1)
	end
	vbo:bless()

	local mesh = MOAIMesh.new()
	mesh:setVertexBuffer(vbo)
	mesh:setPrimType(MOAIMesh.GL_TRIANGLES)
	if importSettings.texture then
		mesh:setTexture(Asset.get("texture", importSettings.texture))
	end
	return mesh
end
