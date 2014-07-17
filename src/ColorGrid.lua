return component(..., function()
	depends "glider.CustomDraw"

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
				if tileState == true then
					MOAIGfxDevice.setPenColor(0.2, 0.8, 0.6)
					MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
				elseif tileState == false then
					MOAIGfxDevice.setPenColor(0.2, 0.2, 0.2)
					MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
				else
					MOAIGfxDevice.setPenColor(1, 1, 1)
					MOAIDraw.drawRect(xMin, yMin, xMax, yMax)
				end
			end
		end
	end)

	msg("addNote", function(self, ent, lane, colored)
		local column = self.columns[lane]
		if #column == ent:getNumRows() then
			table.clear(column)
		end
		table.insert(column, colored)
	end)
end)
