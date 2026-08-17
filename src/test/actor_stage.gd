extends Node3D

var stranger_queue:Array = []

func _ready() -> void:
	$timer.connect("timeout", create_stranger)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		var from:Vector3 = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var to:Vector3 = get_viewport().get_camera_3d().project_ray_normal(event.position) * 200
		$ray_cast_3d.global_position = from
		$ray_cast_3d.target_position = to
		$ray_cast_3d.collision_mask = 3
		$ray_cast_3d.force_raycast_update()
		if $ray_cast_3d.is_colliding():
			$cheshire.move($ray_cast_3d.get_collision_point())

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
