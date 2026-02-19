extends MarkerEvent
class_name MarkerCamera

@export var camera:Camera3D = null

func event() -> void:
	if camera:
		level.get_node("player").force_set_camera(camera)
	level.state_machine.change_state("explore_idle")
