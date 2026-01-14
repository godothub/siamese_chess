extends Barrier

func captured(_capturing:Actor = null) -> void:
	$"0".visible = false
	$gpu_particles_died.restart()
	$audio_stream_player_3d.play()
