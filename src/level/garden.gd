extends Level

var cheshire_instance:Actor = null

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/405135__mjeno__autumn-forest-leaves-falling-close-to-pond-iii-loopable.wav"))
	$player.force_set_camera($camera)

func interact_carnation() -> void:
	state_machine.change_state("stop")
	var carnation_pos:Vector3 = $marker_actor_carnation.global_position
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(carnation_pos.x, carnation_pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	cheshire_instance.rotation.y = target_angle
	Dialog.set_border_position(false)
	Dialog.push_dialog("CARNATION_TALK_0_0", "", true, true)
	$player.force_set_camera($camera_carnation_dialog)
	await Dialog.on_next
	Dialog.push_dialog("CARNATION_TALK_0_1", "", false, true)
	await Dialog.on_next
	$player.force_set_camera($camera)
	Dialog.set_border_position(Setting.get_value("dialog_border"))
	state_machine.change_state("resume")
