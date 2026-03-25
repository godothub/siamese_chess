extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.x88_to_vector3(cheshire_by)
	title[0x10] = "电梯"
	$chessboard.state.add_piece(cheshire_by, player_king)
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	chessboard.button_input_pointer = cheshire_by

func elevator_minus_1f() -> void:
	Loading.change_scene("res://scene/level/hallway_minus_1f.tscn", {"by": 0x10})

func elevator_2f() -> void:
	Loading.change_scene("res://scene/level/hallway_2f.tscn", {"by": 0x10})

func elevator_3f() -> void:
	Loading.change_scene("res://scene/level/hallway_3f.tscn", {"by": 0x10})
