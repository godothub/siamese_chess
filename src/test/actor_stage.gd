extends Node3D

func _ready() -> void:
	$area_3d.connect("input_event", input_event)

func input_event(_camera:Camera3D, event:InputEvent, _event_position:Vector3, _normal:Vector3, _shape_idx:int) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		$cheshire.move(_event_position)
