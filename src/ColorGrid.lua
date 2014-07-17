return component(..., function()
	depends "glider.CustomDraw"
	depends "glider.Actor"

	property "NumRows"
	property "HorizontalGap"
	property "VerticalGap"
	property "LineWidth"

	msg("onCreate", function(self, ent)
		self.columns = {}
		for columnIndex = 1, 3 do
			self.columns[columnIndex] = {}
		end
	end)

	msg("update", function(self, ent)
		for columnIndex, column in ipairs(self.columns) do
			for rowIndex, tile in ipairs(column) do
				if tile then
					tile.posScale = math.min(tile.posScale + 0.06, 1)
				end
			end
		end
	end)

	msg("onDraw", function(self, ent)
		MOAIGfxDevice.setPenWidth(ent:getLineWidth())

		local xMin, yMin, xMax, yMax = unpack(ent:getRect())
		local totalWidth = xMax - xMin
		local hGap = ent:getHorizontalGap()
		local tileWidth = (totalWidth - hGap * 2) / 3
		local totalHeight = yMax - yMin
		local numRows = ent:getNumRows()
		local vGap = ent:getVerticalGap()
		local tileHeight = (totalHeight - vGap * (numRows - 1)) / numRows
		local columns = self.columns

		for col = 0, 2 do
			for row = 0, numRows - 1 do
				local xMin, yMin, xMax, yMax =
					xMin + col * (tileWidth + hGap),
					yMin + row * (tileHeight + vGap),
					xMin + col * (tileWidth + hGap) + tileWidth,
					yMin + row * (tileHeight + vGap) + tileHeight

				local tileState = columns[col + 1][row + 1]
				if tileState then
					if tileState.colored then
						MOAIGfxDevice.setPenColor(0.2, 0.8, 0.6)
					else
						MOAIGfxDevice.setPenColor(0.2, 0.2, 0.2)
					end

					local posScale = tileState.posScale
					MOAIDraw.fillRect(xMin, yMin * posScale, xMax, yMin * posScale + tileHeight )
				end

				MOAIGfxDevice.setPenColor(1, 1, 1)
				MOAIDraw.drawRect(xMin, yMin, xMax, yMax)
			end
		end
	end)

	msg("addNote", function(self, ent, lane, colored)
		local column = self.columns[lane]
		if #column == ent:getNumRows() then
			table.clear(column)
		end
		local tileData = {
			colored = colored,
			posScale = -0.2
		}
		table.insert(column, tileData)
	end)
end)
