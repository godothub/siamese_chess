extends Node3D

func _ready() -> void:
	$cheshire.play_animation("thinking")
	$chessboard.state = Chess.create_initial_state()
	$chessboard.add_default_piece_set()
