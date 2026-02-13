extends Node3D

var state_machine:StateMachine = null

func _ready() -> void:
	state_machine = StateMachine.new()
	$cheshire.play_animation("thinking")
	$chessboard.state = Chess.create_initial_state()
	$chessboard.add_default_piece_set()
	$player.force_set_camera($camera_3d)
	state_machine.add_state("idle", state_ready_idle)
	state_machine.change_state("idle")

func state_ready_idle(_arg:Dictionary) -> void:
	pass
