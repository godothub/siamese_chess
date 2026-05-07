extends Node

signal move_mouse(position:Vector2)

var swipe_distance:float = 100
var double_click_threshold:float = 0.3
var hold_threshold:float = 0.3

var start_position:Vector2 = Vector2(0, 0)
var current_position:Vector2 = Vector2(0, 0)
var is_hold:bool = false
var mouse_moved:bool = true
var is_pressed:bool = true
var hold_timer:Timer = Timer.new()	# 超时计时用Timer对象会更好
var double_click_timer:float = -1	# 限时计时用时间戳

var up:bool = false
var down:bool = false
var left:bool = false
var right:bool = false

var confirm:bool = false
var cancel:bool = false

func _ready() -> void:
	add_child(hold_timer)
	hold_timer.connect("timeout", func () -> void:
		is_hold = true
	)

func _input(event:InputEvent) -> void:
	if !Setting.get_value("touch_gesture"):
		return
	if event is InputEventMouseButton || event is InputEventMouseMotion || event is InputEventScreenTouch || event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			start_position = event.position
			current_position = event.position
			is_hold = false
			is_pressed = true
			mouse_moved = false
			var current_time:float = Time.get_unix_time_from_system()
			hold_timer.start(hold_threshold)
			if current_time <= double_click_timer + double_click_threshold:
				press_confirm()
			double_click_timer = current_time
		else:
			is_pressed = false
			is_hold = false
			hold_timer.stop()
			release_direction()
			if confirm:
				release_confirm()
	if event is InputEventMouseMotion:
		if !(event.button_mask & MOUSE_BUTTON_LEFT):
			return
		current_position = event.position
		if start_position.distance_squared_to(current_position) >= 25:
			mouse_moved = true
			double_click_timer = -1
			hold_timer.stop()
		if !is_hold && start_position.distance_to(current_position) >= swipe_distance:
			press_direction(current_position - start_position)
		if is_hold:
			move_mouse.emit(event.position)

func press_confirm() -> void:
	confirm = true
	push_action("ui_accept", true)

func release_confirm() -> void:
	confirm = false
	push_action("ui_accept", false)

func press_direction(direction:Vector2) -> void:
	direction = direction.normalized()
	if direction.angle() > -PI / 4 && direction.angle() < PI / 4:
		if !right:
			right = true
			push_action("ui_right", true)
	elif right:
		right = false
		push_action("ui_right", false)
	if direction.angle() < -PI * 3 / 4 || direction.angle() > PI * 3 / 4:
		if !left:
			left = true
			push_action("ui_left", true)
	elif left:
		left = false
		push_action("ui_left", false)
	if direction.angle() > -PI * 3 / 4 && direction.angle() < -PI / 4:
		if !up:
			up = true
			push_action("ui_up", true)
	elif up:
		up = false
		push_action("ui_up", false)
	if direction.angle() > PI / 4 && direction.angle() < PI * 3 / 4:
		if !down:
			down = true
			push_action("ui_down", true)
	elif down:
		down = false
		push_action("ui_down", false)

func release_direction() -> void:
	if right:
		right = false
		push_action("ui_right", false)
	if left:
		left = false
		push_action("ui_left", false)
	if up:
		up = false
		push_action("ui_up", false)
	if down:
		down = false
		push_action("ui_down", false)

func push_action(action:String, pressed:bool) -> void:
	var event:InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
