local Xml = require "glider.Xml"
local childElementsOf = Xml.childElementsOf
local Preset = require "glider.Preset"
local Asset = require "glider.Asset"

return module(function()
	exports {
		"parse"
	}

	function parse(sceneXml, context)
		local context = context or ""

		local partitions, entities, viewports, renderTables, frameBuffers

		for _, elem in childElementsOf(sceneXml) do
			if elem.name == "partitions" then
				partitions = parsePartitions(elem, context.."/partitions")
			elseif elem.name == "entities" then
				entities = parseEntities(elem, context.."/entities")
			elseif elem.name == "viewports" then
				viewports = parseViewports(elem, context.."/viewports")
			elseif elem.name == "render-tables" then
				renderTables = parseRenderTables(elem, context.."/renderTables")
			elseif elem.name == "frame-buffers" then
				frameBuffers = parseFrameBuffers(elem, context.."/frameBuffers")
			end
		end

		assert(partitions, "Scene does not define partitions\nCotnext: "..context)
		assert(entities, "Scene does not define entities\nContext: "..context)
		assert(viewports, "Scene does not define viewports\nContext: "..context)
		assert(renderTables, "Scene does not define render tables\nContext: "..context)

		return {
			partitions = partitions,
			entities = entities,
			viewports = viewports,
			renderTables = renderTables,
			frameBuffers = frameBuffers
		}
	end

	-- Private

	function parsePartitions(partitionsXml, context)
		local partitions = {}

		for elemIndex, elem in childElementsOf(partitionsXml) do
			if elem.name == "partition" then
				local partitionName = assert(elem.attr.name, "Partition does not have a name\nContext:"..context.."["..elemIndex.."]")
				partitions[partitionName] = parsePartition(elem, context.."/"..partitionName)
			end
		end

		return partitions
	end

	function parsePartition(partitionXml, context)
		local attrs = partitionXml.attr
		local plane = attrs.plane or "xy"

		return {
			plane = MOAIPartition["PLANE_"..plane:upper()],
			levels = parseLevels(partitionXml, context.."/levels")
		}
	end

	function parseLevels(partitionXml)
		return nil
	end

	function parseEntities(entitiesXml, context)
		local entities = {}

		for elemIndex, elem in childElementsOf(entitiesXml) do
			local context = context.."["..elemIndex.."]"

			if elem.name == "entity" then
				local anonPreset = Preset.parsePreset(elem, context)
				table.insert(entities, {anonPreset, {}})
			elseif elem.name == "preset" then
				local presetName = elem.attr.name
				local success, presetOrError = pcall(Asset.get, "preset", presetName)
				assert(
					success,
					tostring(presetOrError).."\nContext: "..context
				)
				local properties = Preset.parseProperties(elem, context.."/properties")
				local prototype = presetOrError.prototype
				for propertyIndex, propertyKV in ipairs(properties) do
					local name, value = unpack(propertyKV)
					assert(
						type(prototype["set"..name]) == "function",
						"Non-existent or invalid property '"..name.."'\nContext: "..context
					)
				end
				table.insert(entities, {presetOrError, properties})
			end
		end

		return entities
	end

	function parseViewports(viewportsXml)
		local viewports = {}

		for elemIndex, elem in childElementsOf(viewportsXml) do
			if elem.name == "viewport" then
				viewports[elem.attr.name] = parseViewport(elem)
			end
		end

		return viewports
	end

	function parseViewport(viewportXml)
		-- TODO: validate
		local attrs = viewportXml.attr
		return {
			width = tonumber(attrs.width) or 1,
			height = tonumber(attrs.height) or 1,
			xScale = tonumber(attrs["x-scale"]) or 1,
			yScale = tonumber(attrs["y-scale"]) or 1,
			xOffset = tonumber(attrs["x-offset"]) or 0,
			yOffset = tonumber(attrs["y-offset"]) or 0,
			mode = attrs["mode"] or "relative",
			unit = attrs.unit or "dp"
		}
	end

	function parseRenderTables(renderTablesXml, context)
		local renderTables = {}

		for elemIndex, renderTableXml in childElementsOf(renderTablesXml) do
			if renderTableXml.name == "render-table" then
				local renderTable = parseRenderTable(renderTableXml, context.."["..elemIndex.."]")
				renderTables[renderTableXml.attr.name] = renderTable
			end
		end

		assert(renderTables.main ~= nil, "A main render table must be defined\nContext: "..context)

		return renderTables
	end

	function parseRenderTable(renderTableXml)
		local renderTable = {}

		for elemIndex, elem in childElementsOf(renderTableXml) do
			if elem.name == "layer" then
				table.insert(renderTable, parseLayer(elem))
			end
		end

		return renderTable
	end

	function parseLayer(layerXml)
		local attrs = layerXml.attr

		local sort = attrs.sort or "none"
		return {
			type = "layer",
			partition = attrs.partition,
			viewport = attrs.viewport,
			camera = attrs.camera,
			name = attrs.name,
			sort = MOAILayer["SORT_"..sort:upper()]
		}
	end

	function parseFrameBuffers(frameBuffersXml, context)
		local frameBuffers = {}

		for elemIndex, elem in childElementsOf(frameBuffersXml) do
			if elem.name == "frame-buffer" then
				table.insert(frameBuffers, parseFrameBuffer(elem, context.."["..elemIndex.."]"))
			end
		end

		return frameBuffers
	end

	function parseFrameBuffer(bufferXml, context)
		local attrs = bufferXml.attr
		return {
			name = attrs.name,
			width = assert(tonumber(attrs.width), "Invalid width\nContext:"..context),
			height = assert(tonumber(attrs.height), "Invalid height\nContext:"..context),
			renderTable = assert(attrs["render-table"], "Invalid render-table\nContext:"..context)
		}
	end
end)
