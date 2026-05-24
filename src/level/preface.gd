extends Level

var tutor_state_machine:StateMachine = StateMachine.new()

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/546047__grcekh__analog-crt-tv-electronic-static-noise.wav"))
	$pastor.play_animation("thinking")
	$camera_pastor.make_current()
	tutor_state_machine.name = "tutor"
	tutor_state_machine.add_state("introduction", state_ready_introduction)
	tutor_state_machine.change_state("introduction")

# 开篇
func state_ready_introduction(_arg:Dictionary) -> void:
	$chessboard.state = Chess.create_initial_state()
	$chessboard.add_default_piece_set()
	$camera_pastor.make_current()
	var tween:Tween = create_tween()
	$spot_light_3d.light_energy = 0
	tween.tween_property($spot_light_3d, "light_energy", 1, 5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# 介绍棋子的移动，以及简单的挑战
func state_ready_move_piece(_arg:Dictionary) -> void:
	$camera_chessboard.make_current()

# 下方选项
func state_ready_select(_arg:Dictionary) -> void:
	pass

# 介绍文档
func state_ready_document(_arg:Dictionary) -> void:
	pass

# 介绍设置
func state_ready_settings(_arg:Dictionary) -> void:
	pass
