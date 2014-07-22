return component(..., function()
	depends "glider.CustomDraw"
	depends "glider.Actor"

	property "NumRows"
	property "HorizontalGap"
	property "VerticalGap"
	property "LineWidth"

	msg("onCreate", function(self, ent)
		self.columns = {}
		self.countDown = 1
		for columnIndex = 1, 3 do
			self.columns[columnIndex] = {}
		end
	end)

	msg("update", function(self, ent)
		if self.countDown > 0 then
			self.countDown = math.max(0, self.countDown - 1/60/2)

			if self.countDown == 0 then
				flushGrid(self, ent)
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

				local tile = columns[col + 1][row + 1]
				if tile then
					if tile.colored then
						if tile.matched then
							local countDown = self.countDown
							local r = math.lerp(1, 0.2, countDown)
							local g = math.lerp(1, 0.8, countDown)
							local b = math.lerp(1, 0.6, countDown)
							MOAIGfxDevice.setPenColor(r, g, b)
						else
							MOAIGfxDevice.setPenColor(0.2, 0.8, 0.6)
						end
					else
						MOAIGfxDevice.setPenColor(0.2, 0.2, 0.2)
					end

					MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
				end

				MOAIGfxDevice.setPenColor(1, 1, 1)
				MOAIDraw.drawRect(xMin, yMin, xMax, yMax)
			end
		end
	end)

	msg("addNote", function(self, ent, lane, colored)
		local tile = {
			colored = colored
		}

		local column = self.columns[lane]
		local columnHeight = #column
		local numRows = ent:getNumRows()

		if columnHeight >= numRows then
			flushGrid(self, ent)
		end

		if #column >= numRows then -- overfill
			table.clear(column)
		else
			table.insert(column, tile)
			local matchFound = findMatches(self, ent)
			if matchFound and colored then
				self.countDown = 1
			end
		end
	end)

	function findMatches(self, ent)
		local visited = {}
		local columns = self.columns
		local matchFound = false

		forEachTile(self, ent, clearMatch)

		forEachTile(self, ent, function(tile, column, rowIndex, columnIndex)
			if tile and not visited[tile] then
				local cluster = findAdjacentColoredTiles(columns, tile, rowIndex, columnIndex, nil, visited)
				if cluster and #cluster >= 3 then
					for _, tile in ipairs(cluster) do
						tile.matched = true
					end
					matchFound = true
				end

				visited[tile] = true
			end
		end)

		return matchFound
	end

	function clearMatch(tile)
		if tile then
			tile.matched = false
		end
	end

	function findAdjacentColoredTiles(columns, centerTile, rowIndex, columnIndex, cluster, visited)
		if isColored(centerTile) and not visited[centerTile] then
			cluster = cluster or {}
			table.insert(cluster, centerTile)
			visited[centerTile] = true

			local leftTile = getTile(columns, rowIndex, columnIndex - 1)
			local rightTile = getTile(columns, rowIndex, columnIndex + 1)
			local topTile = getTile(columns, rowIndex + 1, columnIndex)
			local bottomTile = getTile(columns, rowIndex - 1, columnIndex)

			findAdjacentColoredTiles(columns, leftTile, rowIndex, columnIndex - 1, cluster, visited)
			findAdjacentColoredTiles(columns, rightTile, rowIndex, columnIndex + 1, cluster, visited)
			findAdjacentColoredTiles(columns, topTile, rowIndex + 1, columnIndex, cluster, visited)
			findAdjacentColoredTiles(columns, bottomTile, rowIndex - 1, columnIndex, cluster, visited)
		end

		return cluster
	end

	function getTile(columns, row, col)
		local column = columns[col]
		if column then return column[row] end
	end

	function isColored(tile)
		return tile and tile.colored
	end

	function flushGrid(self, ent)
		forEachTile(self, ent, removeIfMatched)
		forEachTile(self, ent, fillGap)
	end

	function removeIfMatched(tile, column, rowIndex, columnIndex)
		if tile and tile.matched then
			column[rowIndex] = nil
		end
	end

	function fillGap(tile, column, rowIndex, columnIndex, numRows)
		if tile == nil then
			-- Look for a non-empty row above
			for nextRowIndex = rowIndex + 1, numRows do
				if column[nextRowIndex] ~= nil then
					column[rowIndex] = column[nextRowIndex]
					column[nextRowIndex] = nil
					break
				end
			end
		end
	end

	function forEachTile(self, ent, func)
		local numRows = ent:getNumRows()
		for columnIndex, column in ipairs(self.columns) do
			for rowIndex = 1, numRows do
				func(column[rowIndex], column, rowIndex, columnIndex, numRows)
			end
		end
	end
end)
