local glider = require "glider"

glider.start{
	Director = {
		updatePhases = {
			"GameLogic",
			"Visual"
		},
		firstScene = os.getenv("FIRST_SCENE") or "scenes.Analyze"
	},
	DebugLines = {
		PARTITION_CELLS        = false,
		PARTITION_PADDED_CELLS = false,
		PROP_MODEL_BOUNDS      = false,
		PROP_WORLD_BOUNDS      = false,
		TEXT_BOX               = true,
		TEXT_BOX_BASELINES     = false,
		TEXT_BOX_LAYOUT        = false
	}
}
