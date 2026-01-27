extends StateMachine

func _ready() -> void:
	$cheshire.play_animation("thinking")
	$chessboard.state = Chess.create_initial_state()
	$chessboard.add_default_piece_set()
	change_state("idle")

func state_ready_idle(_arg:Dictionary) -> void:
	pass
