local Entity = require "glider.Entity"
local ColorTile = require "ColorTile"

return component(..., function()
	depends "glider.CustomDraw"
	depends "glider.Actor"

	property "NumRows"
	property "HorizontalGap"
	property "VerticalGap"
	property "LineWidth"

	local COUNT_DOWN_TIME = 0.8

	msg("onCreate", function(self, ent)
		self.pulse = 0 -- a value which goes back and forth in [0, 1], used for effects
		self.pulseSpeed = 0.08 -- pulsing speed

		self.numMovingTiles = 0

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
		if self.countDown > 0 and self.numMovingTiles == 0 then
			self.countDown = math.max(0, self.countDown - 1/60/COUNT_DOWN_TIME)

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
					local visualRow = ColorTile.getVisualRow(tile)

					local yMin, yMax =
						yMin + (visualRow - 1 - row) * (tileHeight + vGap),
						yMin + (visualRow - 1 - row) * (tileHeight + vGap) + tileHeight

					ColorTile.draw(tile, xMin, yMin, xMax, yMax, countDown)
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
		local column = self.columns[lane]
		local columnHeight = #column
		local numRows = ent:getNumRows()

		-- Try to clear column if it's filled
		if columnHeight >= numRows then
			flushGrid(self, ent)
		end

		if #column >= numRows then -- overfill
			for row = 1, numRows do
				destroyTile(self, ent, row, lane)
			end

			Entity.getByName("MainCamera"):shake()
		else
			local tile = ColorTile.create(lane, colored, ent:getNumRows(), #column + 1, ent)
			table.insert(column, tile)
			findMatches(self, ent)
		end
	end)

	msg("onTileAnimationStart", function(self, ent, tile)
		if ColorTile.isColored(tile) then
			self.numMovingTiles = self.numMovingTiles + 1
			self.countDown = 1
		end
	end)

	msg("onTileAnimationEnd", function(self, ent, tile)
		if ColorTile.isColored(tile) then
			self.numMovingTiles = self.numMovingTiles - 1
		end
	end)

	-- Private

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
						ColorTile.setMatched(tile, true)
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
			ColorTile.setMatched(tile, false)
		end
	end

	function findAdjacentColoredTiles(columns, centerTile, rowIndex, columnIndex, cluster, visited)
		if ColorTile.isColored(centerTile) and not visited[centerTile] then
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

	function destroyTile(self, ent, row, col)
		local column = self.columns[col]
		if column then
			local tile = column[row]
			if tile then
				local moving = ColorTile.isMoving(tile)
				if moving then
					ent:onTileAnimationEnd(tile)
				end

				ColorTile.destroy(tile)
				column[row] = nil
			end
		end
	end

	function flushGrid(self, ent)
		local columns = self.columns
		local numRows = ent:getNumRows()

		-- Clear all matched tiles
		local crackList
		forEachTile(self, ent, function(tile, rowIndex, columnIndex)
			if ColorTile.isMatched(tile) then
				destroyTile(self, ent, rowIndex, columnIndex)

				-- Crack adjacent gray tiles
				crackList = tryCrack(columns, rowIndex + 1, columnIndex, crackList)
				crackList = tryCrack(columns, rowIndex - 1, columnIndex, crackList)
				crackList = tryCrack(columns, rowIndex, columnIndex + 1, crackList)
				crackList = tryCrack(columns, rowIndex, columnIndex - 1, crackList)
			end
		end)

		if crackList then
			for tile, coord in pairs(crackList) do
				if ColorTile.isCracked(tile) then--destroy it
					local row, column = unpack(coord)
					destroyTile(self, ent, row, column)
				else--crack it
					ColorTile.crack(tile)
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
						local tile = column[nextRowIndex]
						column[rowIndex] = tile
						ColorTile.setRow(tile, rowIndex)
						column[nextRowIndex] = nil
						break
					end
				end
			end
		end)
	end

	function tryCrack(columns, row, column, crackList)
		local tile = getTile(columns, row, column)
		if tile and not ColorTile.isColored(tile) then
			-- Accumulate them in a list so that a tile is not cracked more than once
			-- in one flush
			crackList = crackList or {}
			crackList[tile] = { row, column }
		end

		return crackList
	end

	function forEachTile(self, ent, func, ...)
		local numRows = ent:getNumRows()
		for columnIndex, column in ipairs(self.columns) do
			for rowIndex = 1, numRows do
				func(column[rowIndex], rowIndex, columnIndex, ...)
			end
		end
	end
end)
