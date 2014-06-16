return class(..., function(i)
	function i:__constructor()
		self.listeners = {}
	end

	function i:addListener(listener)
		assert(type(listener) == "function", "Listener must be a function")

		self.listeners[listener] = true
		return listener
	end

	function i:removeListener(listener)
		self.listeners[listener] = nil
	end

	function i:fire(...)
		for listener in pairs(self.listeners) do
			listener(...)
		end
	end
end)
