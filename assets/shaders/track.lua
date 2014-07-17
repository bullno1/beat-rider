return {
	uniforms = {
		{"uTransform", "WORLD_VIEW_PROJ"},
		{"uProjStart", "FLOAT", 0},
		{"uProjLength", "FLOAT", 400},
		{"uBaseSampler", "SAMPLER", 1},
		{"uProjSampler", "SAMPLER", 2}
	},
	attributes = {
		"aPosition",
		"aUV",
		"aDistance"
	}
}
