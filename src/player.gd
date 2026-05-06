extends Node3D
class_name Player
@onready var ray_cast:RayCast3D = $ray_cast

var state_machine:StateMachine = StateMachine.new()
var mouse_moved:bool = false
var can_move:bool = true
var inspectable_item_list:Array[InspectableItem] = []
var current_area:Area3D = null
var target_camera:Camera3D = null

func _ready() -> void:
	Setting.connect("dialog_border_changed", refresh_camera)
	state_machine.name = "player"
	state_machine.add_state("inspect", state_ready_inspect, Callable(), state_process_inspect, state_input_inspect)
	state_machine.add_state("dialog", Callable(), Callable(), state_process_dialog)
	state_machine.add_state("interface", state_ready_interface)
	state_machine.change_state("inspect")

func on_visibility_changed() -> void:
	if (Setting.visible || Photo.visible || ThirdEye3D.visible || Archive.visible) && state_machine.current_state != "interface":
		state_machine.change_state("interface")
	elif state_machine.current_state == "interface":
		state_machine.change_state.call_deferred("inspect")

func state_ready_inspect(_arg:Dictionary) -> void:
	state_machine.state_signal_connect(Setting.touch_gesture_changed, func () -> void:
		state_machine.change_state.call_deferred("inspect")
	)

	state_machine.state_signal_connect(Setting.visibility_changed, on_visibility_changed)
	state_machine.state_signal_connect(Photo.visibility_changed, on_visibility_changed)
	state_machine.state_signal_connect(ThirdEye3D.visibility_changed, on_visibility_changed)
	state_machine.state_signal_connect(Archive.visibility_changed, on_visibility_changed)

func state_process_inspect(_delta:float) -> void:
	if Dialog.block_input():
		state_machine.change_state.call_deferred("dialog")
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
		if Input.is_action_just_pressed("ui_cancel") && Dialog.cancel_showing:
			Dialog.on_cancel.emit()
		elif Input.is_action_just_pressed("select") && Dialog.selection.size():
			Dialog.direction(1)
		elif Input.is_action_just_pressed("menu"):
			Dialog.show_global_selection()
			Dialog.direction(1)

func state_input_inspect(event:InputEvent) -> void:
	if event is InputEventMouseButton || event is InputEventMouseMotion:
		current_area = click_area(event.position)
		if is_instance_valid(current_area):
			var instant:bool = event is InputEventMouseButton
			var pressed:bool = event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT || event is InputEventMouseMotion && (event.button_mask & MOUSE_BUTTON_MASK_LEFT)
			current_area.emit_signal("input", self, current_area, instant, pressed, $ray_cast.get_collision_point(), $ray_cast.get_collision_normal())

func state_process_dialog(_delta:float) -> void:
	if !Dialog.block_input():
		state_machine.change_state.call_deferred("inspect")
	if Input.is_action_just_pressed("ui_left") || Input.is_action_just_pressed("tab_left"):
		Dialog.direction(-1)
	if Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("tab_right"):
		Dialog.direction(1)		
	if Input.is_action_just_pressed("ui_accept"):
		Dialog.confirm()
	if Dialog.force_selection:
		if Input.is_action_just_pressed("ui_cancel"):
			Dialog.on_cancel.emit()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		Dialog.on_cancel.emit()
		Dialog.cancel_focus()
		Dialog.hide_global_selection()
	if Input.is_action_just_pressed("menu"):
		Dialog.cancel_focus()
		Dialog.hide_global_selection()
	if Input.is_action_just_pressed("select"):
		Dialog.cancel_focus()
		Dialog.hide_global_selection()
	return

func state_ready_interface(_args:Dictionary) -> void:
	state_machine.state_signal_connect(Setting.visibility_changed, on_visibility_changed)
	state_machine.state_signal_connect(Photo.visibility_changed, on_visibility_changed)
	state_machine.state_signal_connect(ThirdEye3D.visibility_changed, on_visibility_changed)
	state_machine.state_signal_connect(Archive.visibility_changed, on_visibility_changed)

func _physics_process(_delta:float) -> void:
	$head/camera.set_rotation(Vector3(deg_to_rad(sin(Time.get_unix_time_from_system())), 0, 0))
	state_machine.process(_delta)

func _unhandled_input(event:InputEvent) -> void:
	state_machine.input(event)

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
	target_camera = other
	var tween:Tween = create_tween()
	#tween.tween_callback($audio_stream_player.play)
	tween.tween_property($head, "global_transform", other.global_transform, 1).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	tween.tween_property($head/camera, "fov", other.fov * 0.85 if Setting.get_value("dialog_border") else other.fov, 1).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(false)

func force_set_camera(other:Camera3D) -> void:
	target_camera = other
	$head.global_transform = other.global_transform
	$head/camera.fov = other.fov * 0.85 if Setting.get_value("dialog_border") else other.fov

func refresh_camera() -> void:
	if !is_instance_valid(target_camera):
		return
	$head.global_transform = target_camera.global_transform
	$head/camera.fov = target_camera.fov * 0.85 if Setting.get_value("dialog_border") else target_camera.fov

func get_camera() -> Camera3D:
	return $head/camera

func add_inspectable_item(_inspectable_item:InspectableItem) -> void:
	inspectable_item_list.push_back(_inspectable_item)
