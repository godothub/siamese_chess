extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.convert_name_to_position(Chess.to_position_name(cheshire_by))
	$chessboard.state.add_piece(cheshire_by, ord("k"))
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	$player.force_set_camera($camera)
