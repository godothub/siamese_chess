extends Node3D

var stranger_queue:Array = []

func _ready() -> void:
	$area_3d.connect("input_event", input_event)
	$timer.connect("timeout", create_stranger)

func input_event(_camera:Camera3D, event:InputEvent, _event_position:Vector3, _normal:Vector3, _shape_idx:int) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		$cheshire.move(_event_position)

func create_stranger() -> void:
	var instance:Actor = load("res://scene/actor/stranger.tscn").instantiate()
	add_child(instance)
	instance.global_position = Vector3(randf_range(-10, 10), 0, -20)
	instance.direction = Vector3(0, 0, 1)
	stranger_queue.push_back(instance)
	while stranger_queue.size() > 50:
		var remove_instance:Actor = stranger_queue.front()
		stranger_queue.pop_front()
		remove_instance.queue_free()
