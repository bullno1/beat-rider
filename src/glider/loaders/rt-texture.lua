local Director = require "glider.Director"

return function(name)
	return Director.getFrameBuffer(name), "Could not find frame buffer"
end
