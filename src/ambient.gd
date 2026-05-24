extends Node

var current_audio_stream_player:AudioStreamPlayer = null

func change_environment_sound(audio_stream:AudioStream) -> void:
	if is_instance_valid(current_audio_stream_player) && audio_stream == current_audio_stream_player.stream:
		return
	var next_audio_stream_player:AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(next_audio_stream_player)
	next_audio_stream_player.volume_linear = 0
	next_audio_stream_player.stream = audio_stream
	next_audio_stream_player.bus = &"Ambient"
	next_audio_stream_player.play()
	var tween:Tween = create_tween()
	tween.tween_property(next_audio_stream_player, "volume_linear", 1, 0.5)
	if is_instance_valid(current_audio_stream_player):
		tween.set_parallel(true)
		tween.tween_property(current_audio_stream_player, "volume_linear", 0, 0.5)
		tween.set_parallel(false)
		tween.tween_callback(current_audio_stream_player.queue_free)
	current_audio_stream_player = next_audio_stream_player

func get_current_audio_stream() -> AudioStream:
	return current_audio_stream_player.stream
