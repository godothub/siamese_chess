extends Node

var double_click_threshold:float = 0.3
var double_click_range:float = 50
var hold_threshold:float = 0.1

var start_position:Vector2 = Vector2(0, 0)
var current_position:Vector2 = Vector2(0, 0)
var mouse_moved:bool = true
var double_click_timer:float = -1	# 限时计时用时间戳

func _input(_event:InputEvent) -> void:
	if !Setting.get_value("touch_gesture"):
		return
	if _event is InputEventMouseButton || _event is InputEventMouseMotion || _event is InputEventScreenTouch || _event is InputEventScreenDrag:
		if _event.device != -1:
			get_viewport().set_input_as_handled()
		else:
			return
	if _event is InputEventMouseButton || _event is InputEventScreenTouch:
		if _event is InputEventMouseButton && _event.button_index != MOUSE_BUTTON_LEFT:
			return
		if _event.pressed:
			push_motion_event(_event.position)
			current_position = _event.position
			mouse_moved = false
			var current_time:float = Time.get_unix_time_from_system()
			if start_position.distance_to(current_position) < double_click_range && current_time <= double_click_timer + double_click_threshold:
				push_press_event(_event.position)
			start_position = _event.position
			double_click_timer = current_time
	if _event is InputEventMouseMotion || _event is InputEventScreenDrag:
		if _event is InputEventMouseMotion && !(_event.button_mask & MOUSE_BUTTON_LEFT):
			return
		current_position = _event.position
		if start_position.distance_squared_to(current_position) >= 25:
			mouse_moved = true
			double_click_timer = -1
		push_motion_event(_event.position)

func push_press_event(_position:Vector2) -> void:
	var press_event:InputEventMouseButton = InputEventMouseButton.new()
	press_event.position = _position
	press_event.global_position = _position
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	press_event.pressed = true
	press_event.device = -1
	Input.parse_input_event(press_event)
	await get_tree().create_timer(0.05).timeout
	var release_event:InputEventMouseButton = InputEventMouseButton.new()
	release_event.position = _position
	release_event.global_position = _position
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	release_event.pressed = false
	release_event.device = -1
	Input.parse_input_event(release_event)

func push_motion_event(_position:Vector2) -> void:
	var event:InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _position
	event.global_position = _position
	event.button_mask = 0
	event.device = -1
	Input.parse_input_event(event)
