extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))

func interact_carnation() -> void:
	change_state("dialog")
	var carnation_pos:Vector3 = $marker_actor_carnation.global_position
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(carnation_pos.x, carnation_pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	var cheshire_by:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var cheshire_instance:Actor = chessboard.chessboard_piece[cheshire_by]
	cheshire_instance.rotation.y = target_angle
	Dialog.set_border_position(false)
	Dialog.push_dialog("CARNATION_TALK_1_0", "", true, true)
	$player.force_set_camera($camera_carnation_dialog)
	await Dialog.on_next
	Dialog.push_dialog("CARNATION_TALK_1_1", "", false, true)
	await Dialog.on_next
	$player.force_set_camera($camera)
	Dialog.set_border_position(Setting.get_value("dialog_border"))
	change_state("")
