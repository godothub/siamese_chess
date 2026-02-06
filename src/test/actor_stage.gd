extends Node3D

func _ready() -> void:
	$area_3d.connect("input_event", input_event)

func input_event(_camera:Camera3D, instant:bool, pressed:bool, _event_position:Vector3, _normal:Vector3, _shape_idx:int) -> void:
	if instant && pressed:
		$cheshire.move(_event_position)
