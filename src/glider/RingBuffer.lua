return class(..., function(i)
	function i:__constructor(size)
		self.size = size
		self.cursor = 0
		self.data = {}
	end

	function i:add(item)
		local cursor = self.cursor
		self.data[cursor + 1] = item
		cursor = (cursor + 1) % self.size
		self.cursor = cursor
	end

	function i:get(index)
		local slot = (self.cursor + index - 1) % self.size + 1
		return self.data[slot]
	end

	local function advanceIterator(self, index)
		local size = self.size
		if index >= size then
			return nil
		else
			local cursor = self.cursor
			local slot = (cursor + index) % size + 1
			local data = self.data[slot]
			return index + 1, data
		end
	end

	function i:iterator()
		return advanceIterator, self, 0
	end
end)
