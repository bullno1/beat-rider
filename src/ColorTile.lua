local Entity = require "glider.Entity"
local Animation = require "glider.Animation"

return module(function()
	exports {
		"create",
		"destroy",
		"setRow",
		"getVisualRow",
		"crack",
		"setMatched",
		"draw",
		"isMoving",
		"isColored",
		"isMatched",
		"isCracked"
	}

	local MOVEMENT_TIME = 0.2
	local SHRINK_TIME = 0.2
	local TILE_SPEED = 0.2

	local DISTANCE_CURVE = Animation.createCurve{
		{ 0.0,   0, MOAIEaseType.SOFT_EASE_IN },
		{ 1.0, 276, MOAIEaseType.SOFT_EASE_IN }
	}

	local Y_SCL_CURVE = Animation.createCurve{
		{ 0.0, 1.0, MOAIEaseType.SOFT_EASE_IN },
		{ 1.0, 0.1, MOAIEaseType.SOFT_EASE_IN }
	}

	function create(lane, colored, startRow, targetRow, ent)
		local tile = {
			colored = colored,
			visualRow = startRow,
			logicalRow = targetRow,
			visible = false,
			moving = true
		}

		if colored then
			tile.matched = false
		else
			tile.cracked = false
		end

		local capturedNote = Entity.create("Note")
		capturedNote:setLane(lane)
		capturedNote:setColored(colored)

		tile.note = capturedNote
		tile.coro = ent:spawnCoroutine(update, tile, ent)

		return tile
	end

	function destroy(tile)
		if tile.note then
			Entity.destroy(tile.note)
		end

		tile.coro:stop()
	end

	function setRow(tile, row)
		tile.logicalRow = row
	end

	function getVisualRow(tile)
		return math.floor(tile.visualRow)
	end

	function crack(tile)
		tile.cracked = true
	end

	function setMatched(tile, matched)
		if tile then
			tile.matched = matched
		end
	end

	function isMoving(tile)
		return tile.moving
	end

	function isColored(tile)
		return tile and tile.colored
	end

	function isMatched(tile)
		return tile and tile.matched
	end

	function isCracked(tile)
		return tile and tile.cracked
	end

	function update(tile, ent)
		local yield = coroutine.yield

		local rideController = Entity.getByName("RideController")
		local track = Entity.getByName("Track")
		local note = tile.note

		ent:onTileAnimationStart(tile)

		-- Push the captured note back
		for i = 0, 1, 1/60/MOVEMENT_TIME do
			local songPos = rideController:getSongPos()
			local gridDistance = track:getDistance(songPos)
			local offset = DISTANCE_CURVE:getValueAtTime(i)
			note:setTrackPosition(track:distanceToTime(gridDistance + offset))

			yield()
		end

		-- Move it down
		for i = 0, 1, 1/60/SHRINK_TIME do
			-- Maintain relative position
			local songPos = rideController:getSongPos()
			local gridDistance = track:getDistance(songPos)
			local offset = DISTANCE_CURVE:getValueAtTime(1)
			note:setTrackPosition(track:distanceToTime(gridDistance + offset))

			note:setYScale(Y_SCL_CURVE:getValueAtTime(i))

			yield()
		end

		Entity.destroy(note)
		tile.note = nil
		tile.visible = true

		while true do
			local logicalRow = tile.logicalRow
			local visualRow = tile.visualRow
			local diff = visualRow - logicalRow
			local speed = math.min(diff, TILE_SPEED)
			local visualRow = visualRow - speed

			tile.visualRow = visualRow

			local moving = diff ~= 0
			if not moving and tile.moving then
				ent:onTileAnimationEnd(tile)
			elseif moving and not tile.moving then
				ent:onTileAnimationStart(tile)
			end
			tile.moving = moving

			yield()
		end
	end

	function draw(tile, xMin, yMin, xMax, yMax, countDown)
		if not tile.visible then return end
		
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

	function drawNormalColoredTile(xMin, yMin, xMax, yMax)
		MOAIGfxDevice.setPenColor(0.2, 0.8, 0.6)
		MOAIDraw.fillRect(xMin, yMin, xMax, yMax)
	end

	function drawMatchedColoredTile(xMin, yMin, xMax, yMax, countDown)
		drawNormalColoredTile(xMin, yMin, xMax, yMax)

		local centerX = (xMin + xMax) / 2
		local centerY = (yMin + yMax) / 2
		local width = (xMax - xMin) * (1 - countDown)
		local height = (yMax - yMin) * (1 - countDown)

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
end)
