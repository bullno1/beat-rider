analysis.hop_size = 512

analysis.onset_detection.method   = "specdiff"
analysis.onset_detection.hop_size = 256

analysis.track.data_smoothing_factor  = 0.03
analysis.track.trend_smoothing_factor = 0.03
analysis.track.wave_window_radius     = 15
analysis.track.base_window_radius     = 30

analysis.slope.data_smoothing_factor  = 0.007
analysis.slope.trend_smoothing_factor = 0.01
analysis.slope.window_radius          = 10

analysis.notes.energy_threshold = 0.15
analysis.notes.cluster_max_gap  = 0.1
analysis.notes.cluster_max_size = 5

analysis.notes.same_column_threshold  = 0.15
analysis.notes.close_column_threshold = 0.4
analysis.notes.avoid_threshold        = 0.4

ride.time_scale          = 2000
ride.track_width         = 130
ride.max_bump_height     = 300
ride.ship_height         = 15
ride.max_elevation       = 40
ride.note_speed          = 0.4
ride.update_distance     = 3
ride.max_speed_variation = 0.8

ride.turn.min_drop_duration = 60
ride.turn.min_drop_slope    = 0.02
ride.turn.speed             = 0.2
