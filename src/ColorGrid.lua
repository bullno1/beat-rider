local Entity = require "glider.Entity"

return component(..., function()
	depends "glider.CustomDraw"
	depends "glider.Actor"

	property "NumRows"
	property "HorizontalGap"
	property "VerticalGap"
	property "LineWidth"

	msg("onCreate", function(self, ent)
		self.pulse = 0 -- a value which goes back and forth in [0, 1], used for effects
		self.pulseSpeed = 0.08 -- pulsing speed

		self.countDown = 0 -- count down value until matched tiles are flushed from the grid
		self.hasMatch = {} -- arrays of boolean which indicates whether a column has any matched tiles
		self.columns = {} -- storage for tiles
		for columnIndex = 1, 3 do
			self.columns[columnIndex] = {}
			self.hasMatch[columnIndex] = false
		end
	end)

	msg("update", function(self, ent)
		-- Count down to flushing grids
		if self.countDown > 0 then
			self.countDown = math.max(0, self.countDown - 1/60/2)

			if self.countDown == 0 then
				flushGrid(self, ent)
			end
		end

		-- Update a pulsing value for effects
		local pulseSpeed = self.pulseSpeed
		local pulse = self.pulse + pulseSpeed
		if pulse >= 1 then
			pulse = 1
			self.pulseSpeed = -pulseSpeed
		elseif pulse <= 0 then
			pulse = 0
			self.pulseSpeed = -pulseSpeed
		end

		self.pulse = pulse

		-- Move notes to their correct visual position
		forEachTile(self, ent, moveTile)
	end)

	msg("onDraw", function(self, ent)
		local xMin, yMin, xMax, yMax = unpack(ent:getRect())
		local totalWidth = xMax - xMin
		local hGap = ent:getHorizontalGap()
		local tileWidth = (totalWidth - hGap * 2) / 3
		local totalHeight = yMax - yMin
		local numRows = ent:getNumRows()
		local vGap = ent:getVerticalGap()
		local tileHeight = (totalHeight - vGap * (numRows - 1)) / numRows
		local columns = self.columns
		local countDown = self.countDown
		local columns = self.columns

		for col = 0, 2 do
			local column = columns[col + 1]
			for row = 0, numRows - 1 do
				-- Calculate bounds for tile
				local xMin, yMin, xMax, yMax =
					xMin + col * (tileWidth + hGap),
					yMin + row * (tileHeight + vGap),
					xMin + col * (tileWidth + hGap) + tileWidth,
					yMin + row * (tileHeight + vGap) + tileHeight

				-- Draw tile
				local tile = column[row + 1]
				if tile then
					-- Draw tile using visual rather than logical position
					local visualRow = tile.visualRow

					local yMin, yMax =
						yMin + math.floor(visualRow - 1 - row) * (tileHeight + vGap),
						yMin + math.floor(visualRow - 1 - row) * (tileHeight + vGap) + tileHeight
					if tile.colored then
						if tile.matched then
							drawMatchedColoredTile(xMin, yMin, xMax, yMax, countDown)
						else
							drawNormalColoredTile(xMin, yMin, xMax, yMax)
						end
					else
						if tile.cracked then
							drawCrackedGrayTile(xMin, yMin, xMax, yMax)
						else
							drawNormalGrayTile(xMin, yMin, xMax, yMax)
						end
					end
				end

				-- Draw border
				MOAIGfxDevice.setPenWidth(ent:getLineWidth())
				if #column == numRows and not self.hasMatch[col + 1] then
					MOAIGfxDevice.setPenColor(1, 1, self.pulse)
				else
					MOAIGfxDevice.setPenColor(1, 1, 1)
				end
				MOAIDraw.drawRect(xMin, yMin, xMax, yMax)
			end
		end
	end)

	msg("addNote", function(self, ent, lane, colored)
		local tile = {
			colored = colored,
			visualRow = 0
		}

		if colored then
			tile.matched = false
		else
			tile.cracked = false
		end

		local column = self.columns[lane]
		local columnHeight = #column
		local numRows = ent:getNumRows()

		if columnHeight >= numRows then
			flushGrid(self, ent)
		end

		if #column >= numRows then -- overfill
			table.clear(column)
			Entity.getByName("MainCamera"):shake()
		else
			table.insert(column, tile)
			local matchFound = findMatches(self, ent)
			if matchFound and colored then
				self.countDown = 1
			end
		end
	end)

	-- Private

	function moveTile(tile, targetRow, targetCol)
		if not tile then return end

		local visualRow = tile.visualRow
		local diff = targetRow - visualRow
		local sign = math.sign(diff)
		local speed = sign > 0 and 0.3 or 0.05
		local magnitude = math.min(math.abs(diff), speed)
		visualRow = visualRow + sign * magnitude
		tile.visualRow = visualRow
	end

	function drawNormalColoredTile(xMin, yMin, xMax, yMax)
		MOAIGfxDevice.setPenColor(0.2, 0.8, 0.6)
		MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
	end

	function drawMatchedColoredTile(xMin, yMin, xMax, yMax, countDown)
		drawNormalColoredTile(xMin, yMin, xMax, yMax)

		local centerX = (xMin + xMax) / 2
		local centerY = (yMin + yMax) / 2
		local width = (xMax - xMin) * countDown
		local height = (yMax - yMin) * countDown

		MOAIGfxDevice.setPenWidth(4)
		MOAIGfxDevice.setPenColor(1, 1, 1)
		MOAIDraw.drawRect(centerX - width / 2, centerY - height / 2, centerX + width / 2, centerY + height / 2)
	end

	function drawNormalGrayTile(xMin, yMin, xMax, yMax)
		MOAIGfxDevice.setPenColor(0.2, 0.2, 0.2)
		MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
	end

	function drawCrackedGrayTile(xMin, yMin, xMax, yMax)
		MOAIGfxDevice.setPenColor(0.5, 0.5, 0.5)
		MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
	end

	function findMatches(self, ent)
		local visited = {}
		local columns = self.columns
		local matchFound = false

		-- Reset old states
		forEachTile(self, ent, clearMatch)
		local hasMatch = self.hasMatch
		for i = 1, 3 do
			hasMatch[i] = false
		end

		-- Find matches
		forEachTile(self, ent, function(tile, rowIndex, columnIndex)
			if tile and not visited[tile] then
				local cluster = findAdjacentColoredTiles(columns, tile, rowIndex, columnIndex, nil, visited)
				if cluster and #cluster >= 3 then
					for _, tile in ipairs(cluster) do
						tile.matched = true
						local column = cluster[tile][2]
						hasMatch[column] = true
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
			cluster[centerTile] = { rowIndex, columnIndex }
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
		local columns = self.columns
		local numRows = ent:getNumRows()

		-- Clear all matched tiles
		local crackList
		forEachTile(self, ent, function(tile, rowIndex, columnIndex)
			if tile and tile.matched then
				columns[columnIndex][rowIndex] = nil

				-- Crack adjacent gray tiles
				crackList = tryCrack(columns, rowIndex + 1, columnIndex, crackList)
				crackList = tryCrack(columns, rowIndex - 1, columnIndex, crackList)
				crackList = tryCrack(columns, rowIndex, columnIndex + 1, crackList)
				crackList = tryCrack(columns, rowIndex, columnIndex - 1, crackList)
			end
		end)

		if crackList then
			for tile, coord in pairs(crackList) do
				if tile.cracked then--destroy it
					local row, column = unpack(coord)
					columns[column][row] = nil
				else--crack it
					tile.cracked = true
				end
			end
		end

		-- Fill the gaps
		forEachTile(self, ent, function(tile, rowIndex, columnIndex)
			if tile == nil then
				local column = columns[columnIndex]
				-- Look for a non-empty row above
				for nextRowIndex = rowIndex + 1, numRows do
					if column[nextRowIndex] ~= nil then
						column[rowIndex] = column[nextRowIndex]
						column[nextRowIndex] = nil
						break
					end
				end
			end
		end)
	end

	function tryCrack(columns, row, column, crackList)
		local tile = getTile(columns, row, column)
		if tile and not tile.colored then
			-- Accumulate them in a list so that a tile is not cracked more than once
			-- in one flush
			crackList = crackList or {}
			crackList[tile] = { row, column }
		end

		return crackList
	end

	function forEachTile(self, ent, func)
		local numRows = ent:getNumRows()
		for columnIndex, column in ipairs(self.columns) do
			for rowIndex = 1, numRows do
				func(column[rowIndex], rowIndex, columnIndex)
			end
		end
	end
end)
