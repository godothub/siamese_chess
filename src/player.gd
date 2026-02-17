extends Node3D
@onready var ray_cast:RayCast3D = $ray_cast

var mouse_moved:bool = false
var can_move:bool = true
var inspectable_item_list:Array[InspectableItem] = []
var current_area:Area3D = null
var using_dialog:bool = false

func _ready() -> void:
	pass

func _physics_process(_delta:float) -> void:
	$head/camera.set_rotation(Vector3(deg_to_rad(sin(Time.get_unix_time_from_system())), 0, 0))
	#$head/camera.set_rotation(Vector3(0, deg_to_rad(sin(Time.get_unix_time_from_system() + 5)) * 0.5, 0))
	#$head/camera.set_rotation(Vector3(0, 0, deg_to_rad(sin(Time.get_unix_time_from_system()) * 0.5)))
	if !can_move:
		return
	var vision_look_at:Vector2 = Input.get_vector("vision_look_up", "vision_look_down", "vision_look_left", "vision_look_right")
	$head.global_rotation.x -= vision_look_at.x / 2000 * Progress.get_value("camera_rotate_sensitive", 50)
	$head.global_rotation.y -= vision_look_at.y / 1000 * Progress.get_value("camera_rotate_sensitive", 50)
	var vision_move:Vector2 = Input.get_vector("vision_move_left", "vision_move_right", "vision_move_forward", "vision_move_back")
	$head.global_position += ($head.global_basis.x * vision_move.x / 20 + $head.global_basis.z * vision_move.y / 20) * Progress.get_value("camera_move_speed", 50) / 20
	$head.global_position += $head.global_basis.y * Input.get_axis("vision_move_down", "vision_move_up") / 20 * Progress.get_value("camera_move_speed", 50) / 20
	if vision_look_at || vision_move:
		return
	if Dialog.block_input() || using_dialog:
		if Input.is_action_just_pressed("ui_left"):
			Dialog.direction(-1)
		if Input.is_action_just_pressed("ui_right"):
			Dialog.direction(1)		
		if Input.is_action_just_released("ui_accept"):
			Dialog.next()
			using_dialog = false
		if Input.is_action_just_pressed("ui_cancel"):
			using_dialog = false
			Dialog.cancel_focus()
		return
	for item:InspectableItem in inspectable_item_list:
		if !item.enabled:
			continue
		if Input.is_action_just_pressed("ui_right"):
			item.button_input("right", true)
		if Input.is_action_just_released("ui_right"):
			item.button_input("right", false)
		if Input.is_action_just_pressed("ui_left"):
			item.button_input("left", true)
		if Input.is_action_just_released("ui_left"):
			item.button_input("left", false)
		if Input.is_action_just_pressed("ui_up"):
			item.button_input("up", true)
		if Input.is_action_just_released("ui_up"):
			item.button_input("up", false)
		if Input.is_action_just_pressed("ui_down"):
			item.button_input("down", true)
		if Input.is_action_just_released("ui_down"):
			item.button_input("down", false)
		if Input.is_action_just_pressed("ui_accept"):
			item.button_input("accept", true)
		if Input.is_action_just_released("ui_accept"):
			item.button_input("accept", false)
		if Input.is_action_just_pressed("ui_cancel") && Dialog.selection.size():
			using_dialog = true
			Dialog.direction(1)
	

func _unhandled_input(event:InputEvent) -> void:
	if !can_move || Dialog.block_input():
		return
	if event is InputEventMouseButton || event is InputEventMouseMotion:
		current_area = click_area(event.position)
		if is_instance_valid(current_area):
			var instant:bool = event is InputEventMouseButton
			var pressed:bool = event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT || event is InputEventMouseMotion && (event.button_mask & MOUSE_BUTTON_MASK_LEFT)
			current_area.emit_signal("input", self, current_area, instant, pressed, $ray_cast.get_collision_point(), $ray_cast.get_collision_normal())
	elif event is InputEventMultiScreenDrag:
		if event.fingers == 2:
			$head.global_rotation.y -= event.relative.x / 20000 * Progress.get_value("camera_rotate_sensitive", 50)
			$head.global_rotation.x -= event.relative.y / 10000 * Progress.get_value("camera_rotate_sensitive", 50)
		else:
			$head.global_position += (-$head.global_basis.x * event.relative.x / 100 + $head.global_basis.y * event.relative.y / 100) * Progress.get_value("camera_move_speed", 50) / 50
	elif event is InputEventScreenPinch:
		$head.global_position += -$head.global_basis.z * event.relative / 5000 * Progress.get_value("camera_move_speed", 50)
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

func find_area(direction:Vector2) -> Area3D:
	var best_area:Area3D = null
	var best_weight:float
	var current_area_position_2d:Vector2 = Vector2(0, 0)
	if current_area:
		current_area_position_2d = $head/camera.unproject_position(current_area.global_transform.origin)
	for item:InspectableItem in inspectable_item_list:
		if !item.enabled:
			continue
		for area:Area3D in item.button_list:
			if current_area == area:
				continue
			var area_position_2d:Vector2 = $head/camera.unproject_position(area.global_transform.origin)
			var angle_diff:float = angle_difference(direction.angle(), current_area_position_2d.angle_to(area_position_2d))
			if angle_diff > PI / 6:
				continue
			var distance:float = current_area_position_2d.distance_to(area_position_2d)
			if !best_area || distance < best_weight:
				best_area = area
				best_weight = distance
	return best_area

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

func add_inspectable_item(_inspectable_item:InspectableItem) -> void:
	inspectable_item_list.push_back(_inspectable_item)
