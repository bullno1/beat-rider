local socket = require "socket"

return module(function()
	exports{
		"init"
	}

	local infoSocket
	local cmdSocket
	local environments = {}
	local cmdSockAddr
	local cmdSockPort

	function init()
		cmdSocket = assert(socket.udp())
		assert(cmdSocket:setsockname('*', 0))
		cmdSockAddr, cmdSockPort = cmdSocket:getsockname()
		assert(cmdSocket:settimeout(0))
		print("Opened console socket at ", cmdSockAddr, cmdSockPort)

		infoSocket = assert(socket.udp())
		assert(infoSocket:setoption("reuseaddr", true))
		assert(infoSocket:setsockname('*', 9008))
		assert(infoSocket:setoption('broadcast', true))
		assert(infoSocket:settimeout(0))
		print("Opened info socket ", cmdSockAddr, 9008)

		MOAICoroutine.new():run(updateConsole)
		MOAICoroutine.new():run(advertiseConsole)
	end

	function advertiseConsole()
		local yield = coroutine.yield

		while true do
			local cmd, addr, port = infoSocket:receivefrom()

			if cmd == MOAIEnvironment.appID then
				infoSocket:sendto(MOAIEnvironment.devName.."@"..cmdSockPort, addr, port)
			end
			yield()
		end
	end

	function updateConsole()
		local yield = coroutine.yield

		while true do
			local cmd, addr, port = cmdSocket:receivefrom()

			if cmd then
				if cmd:beginswith('=') then
					cmd = "return "..cmd:sub(2)
				end

				local clientId = addr..":"..port
				local cmdFunc, errMsg = loadstring(cmd, clientId)
				if cmdFunc then
					setfenv(cmdFunc, getEnv(clientId, addr, port))
					processCmdResult(addr, port, xpcall(cmdFunc, debug.traceback))
				else
					cmdSocket:sendto(errMsg..'\n', addr, port)
				end
			elseif addr ~= "timeout" then
				return error(addr)
			end

			yield()
		end
	end

	function processCmdResult(ip, port, success, ...)
		if success then
			send(ip, port, ...)
		else
			local errMsg = ...
			cmdSocket:sendto(errMsg, ip, port)
		end
		cmdSocket:sendto('\n', ip, port)
	end

	function getEnv(clientId, ip, port)
		return environments[clientId] or newEnv(clientId, ip, port)
	end

	local envMt = { __index = _G }
	function newEnv(clientId, ip, port)
		local env = {
			print = function(...)
				send(ip, port, ...)
				send(ip, port, "\n")
			end,
			Entity = require "glider.Entity",
			Director = require "glider.Director",
			dev = require("glider.Options").getDevOptions()
		}
		setmetatable(env, envMt)
		environments[clientId] = env

		return env
	end

	function send(ip, port, ...)
		local numValues = select('#', ...)
		local values = {...}
		local first = true
		for index = 1, numValues do
			if not first then
				cmdSocket:sendto("\t", ip, port)
			end
			first = false

			cmdSocket:sendto(tostring(values[index]), ip, port)
		end
	end
end)
