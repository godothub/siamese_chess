extends Level


func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))

func _physics_process(_delta:float) -> void:
	var cheshire_by:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var cheshire_instance:Actor = chessboard.chessboard_piece[cheshire_by]
	$spot_light_follow_cheshire.look_at(cheshire_instance.global_position)
