local m = {}

function m.spawnActionGroup(parent)
	local group = MOAIAction.new()
	group:setAutoStop(false)
	group:start(parent)
	return group
end

local yield = coroutine.yield
function m.spawnLoopCoroutine(parent, func, ...)
	local coro = MOAICoroutine.new()
	coro:run(function(...)
		while true do
			func(...)
			yield()
		end
	end, ...)
	coro:attach(parent)
	return coro
end

function m.spawnCoroutine(parent, func, ...)
	local coro = MOAICoroutine.new()
	coro:run(func, ...)
	coro:attach(parent)
	return coro
end

function m.spawnTimer(parent, func, span, repeated)
	local timer = MOAITimer.new()
	timer:setSpan(span)
	timer:setMode(repeated and MOAITimer.LOOP or MOAITimer.NORMAL)
	timer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, func)
	timer:start(parent)
	return timer
end

return m
