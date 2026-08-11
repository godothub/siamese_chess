extends Level

var signal_container:SignalContainer = SignalContainer.new()
var who:String = ""

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	who = ["CHAR_YULAN", "CHAR_CARNATION"][randi() % 2]
	if who == "CHAR_CARNATION":
		$event_actor_carnation.enabled = true
		$event_actor_yulan.enabled = false
		$event_actor_carnation/carnation.visible = true
		$event_actor_yulan/pastor.visible = false
		$event_actor_carnation/carnation.play_animation("sit_and_play")
	else:
		$event_actor_yulan.enabled = true
		$event_actor_carnation.enabled = false
		$event_actor_yulan/pastor.visible = true
		$event_actor_carnation/carnation.visible = false
		$event_actor_yulan/pastor.play_animation("battle_idle")

func interact() -> void:
	if who == "CHAR_CARNATION":
		interact_carnation()
	else:
		interact_yulan()

func interact_carnation() -> void:
	change_state("dialog")
	var carnation_pos:Vector3 = $event_actor_carnation.global_position
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(carnation_pos.x, carnation_pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	var instance:Actor = $event_explore.instance
	instance.rotation.y = target_angle
	signal_container.add_connection($procedure_dialog_carnation.procedure_end, func (_result:String) -> void:
		signal_container.disconnect_all()
		Player.force_set_camera($camera)
		change_state("")
	)
	$procedure_dialog_carnation.start()

func interact_yulan() -> void:
	change_state("dialog")
	var yulan_pos:Vector3 = $event_actor_yulan.global_position
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(yulan_pos.x, yulan_pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	var instance:Actor = $event_explore.instance
	instance.rotation.y = target_angle
	signal_container.add_connection($procedure_dialog_yulan.procedure_end, func (_result:String) -> void:
		signal_container.disconnect_all()
		Player.force_set_camera($camera)
		change_state("")
	)
	$procedure_dialog_yulan.start()
