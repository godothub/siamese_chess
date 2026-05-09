extends Node

signal move_mouse(position:Vector2)

var swipe_distance:float = 100
var double_click_threshold:float = 0.3
var hold_threshold:float = 0.3

var start_position:Vector2 = Vector2(0, 0)
var current_position:Vector2 = Vector2(0, 0)
var is_hold:bool = false
var mouse_moved:bool = true
var hold_timer:Timer = Timer.new()	# 超时计时用Timer对象会更好
var double_click_timer:float = -1	# 限时计时用时间戳
var is_multi_finger:bool = false
var finger_index:Dictionary[int, bool] = {}
var up:bool = false
var down:bool = false
var left:bool = false
var right:bool = false

var confirm:bool = false
var cancel:bool = false
var select:bool = false
var menu:bool = false

func _ready() -> void:
	add_child(hold_timer)
	hold_timer.connect("timeout", func () -> void:
		is_hold = true
		if is_multi_finger:
			press_cancel()
		else:
			move_mouse.emit(start_position)
	)

func _input(event:InputEvent) -> void:
	if !Setting.get_value("touch_gesture"):
		return
	if event is InputEventMouseButton || event is InputEventMouseMotion || event is InputEventScreenTouch || event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed && event.index != 0:
			finger_index[event.index] = true
			if finger_index.size() > 1:
				double_click_timer = -1
				is_multi_finger = true
		elif event.index != 0:
			finger_index.erase(event.index)
			if finger_index.size() == 0:
				is_multi_finger = false
				release_menu()
				release_select()
				release_cancel()
				release_tab()
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			current_position = event.position
			is_hold = false
			mouse_moved = false
			var current_time:float = Time.get_unix_time_from_system()
			hold_timer.start(hold_threshold)
			if start_position.distance_to(current_position) < 25 && current_time <= double_click_timer + double_click_threshold:
				press_confirm()
				hold_timer.stop()
				is_hold = false
			start_position = event.position
			double_click_timer = current_time
		else:
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
		if !is_hold && !is_multi_finger && start_position.distance_to(current_position) >= swipe_distance:
			press_direction(current_position - start_position)
		if !is_multi_finger && is_hold:
			move_mouse.emit(event.position)
		if is_multi_finger:
			var angle:float = event.relative.angle()
			if angle > -PI * 3 / 4 && angle < -PI / 4:
				press_select()
			elif angle > PI / 4 && angle < PI * 3 / 4:
				press_menu()
			elif angle > -PI / 4 && angle < PI / 4:
				press_tab(1)
			else:
				press_tab(-1)
				

func press_confirm() -> void:
	confirm = true
	push_action("ui_accept", true)

func release_confirm() -> void:
	confirm = false
	push_action("ui_accept", false)

func press_cancel() -> void:
	push_action("ui_cancel", true)

func release_cancel() -> void:
	push_action("ui_cancel", false)

func press_menu() -> void:
	push_action("menu", true)

func release_menu() -> void:
	push_action("menu", false)

func press_select() -> void:
	push_action("select", true)

func release_select() -> void:
	push_action("select", false)

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

func press_tab(dir:int) -> void:
	if dir == 1:
		push_action("tab_right", true)
	else:
		push_action("tab_left", true)

func release_tab() -> void:
	push_action("tab_right", false)
	push_action("tab_left", false)

func push_action(action:String, pressed:bool) -> void:
	var event:InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
