extends Node3D
@onready var ray_cast:RayCast3D = $ray_cast

var mouse_moved:bool = false
var can_move:bool = true

func _ready() -> void:
	pass

func _physics_process(_delta:float) -> void:
	$head/camera.set_rotation(Vector3(deg_to_rad(sin(Time.get_unix_time_from_system())), 0, 0))
	#$head/camera.set_rotation(Vector3(0, deg_to_rad(sin(Time.get_unix_time_from_system() + 5)) * 0.5, 0))
	#$head/camera.set_rotation(Vector3(0, 0, deg_to_rad(sin(Time.get_unix_time_from_system()) * 0.5)))

func _unhandled_input(event:InputEvent) -> void:
	if !can_move || Dialog.block_input():
		return
	if event is InputEventMouseButton || event is InputEventMouseMotion:
		var area:Area3D = click_area(event.position)
		if is_instance_valid(area):
			var instant:bool = event is InputEventMouseButton
			var pressed:bool = event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT || event is InputEventMouseMotion && (event.button_mask & MOUSE_BUTTON_MASK_LEFT)
			area.emit_signal("input", self, area, instant, pressed, $ray_cast.get_collision_point(), $ray_cast.get_collision_normal())
		get_viewport().set_input_as_handled()

func click_area(screen_position:Vector2) -> Area3D:
	var from:Vector3 = $head/camera.project_ray_origin(screen_position)
	var to:Vector3 = $head/camera.project_ray_normal(screen_position) * 200
	ray_cast.global_position = from
	ray_cast.target_position = to
	ray_cast.collision_mask = 3
	ray_cast.force_raycast_update()
	if ray_cast.is_colliding():
		return ray_cast.get_collider()
	return null

func move_camera(other:Camera3D) -> void:
	if !is_instance_valid(other):
		return
	var tween:Tween = create_tween()
	#tween.tween_callback($audio_stream_player.play)
	tween.tween_property($head, "global_transform", other.global_transform, 1).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	tween.tween_property($head/camera, "fov", other.fov, 1).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(false)

func force_set_camera(other:Camera3D) -> void:
	$head.global_transform = other.global_transform
	$head/camera.fov = other.fov
