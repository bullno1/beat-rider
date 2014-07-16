local glider = require "glider"

glider.start{
	Director = {
		updatePhases = {
			"Controller",
			"GameLogic",
			"Visual"
		},
		firstScene = "analyze",
		sceneData = "assets/sfx/TinhThoiXotXa.mp3"
	},
	DebugLines = {
		PARTITION_CELLS        = false,
		PARTITION_PADDED_CELLS = false,
		PROP_MODEL_BOUNDS      = false,
		PROP_WORLD_BOUNDS      = false,
		TEXT_BOX               = false,
		TEXT_BOX_BASELINES     = false,
		TEXT_BOX_LAYOUT        = false
	},
	Options = {
		user = "UserOptions",
		developer = "DeveloperOptions"
	}
}
