extends Level

func _ready() -> void:
	super._ready()
	change_state("decorate")
	$procedure_decorate.start()

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		var from:Vector3 = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var to:Vector3 = get_viewport().get_camera_3d().project_ray_normal(event.position) * 200
		$ray_cast_3d.global_position = from
		$ray_cast_3d.target_position = to
		$ray_cast_3d.collision_mask = 3
		$ray_cast_3d.force_raycast_update()
		if $ray_cast_3d.is_colliding():
			$chessboard.area_input(self, $ray_cast_3d.get_collider(), true, event.pressed, $ray_cast_3d.get_collision_point(), $ray_cast_3d.get_collision_normal())
	if event is InputEventMouseMotion:
		var from:Vector3 = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var to:Vector3 = get_viewport().get_camera_3d().project_ray_normal(event.position) * 200
		$ray_cast_3d.global_position = from
		$ray_cast_3d.target_position = to
		$ray_cast_3d.collision_mask = 3
		$ray_cast_3d.force_raycast_update()
		if $ray_cast_3d.is_colliding():
			$chessboard.area_input(self, $ray_cast_3d.get_collider(), false, event.button_mask & MOUSE_BUTTON_MASK_LEFT, $ray_cast_3d.get_collision_point(), $ray_cast_3d.get_collision_normal())
