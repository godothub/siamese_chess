@tool
extends Control
class_name SiameseSpinBox

signal value_changed(value:float)

@export var range_min:float = 0
@export var range_max:float = 100
@export var step:float = 1
@export var value:float = 0
@export var suffex:String = " "

@export var font:Font = load("res://assets/fonts/FangZhengShuSongJianTi-1.ttf")
@export var font_size:int = 28
@export var font_color:Color = Color(1, 1, 1, 1)
@export var texture_left:Texture2D = load("res://assets/texture/spinbox_left.svg")
@export var texture_right:Texture2D = load("res://assets/texture/spinbox_right.svg")
@export var stylebox_normal:StyleBox = StyleBoxFlat.new()
@export var stylebox_focus:StyleBox = StyleBoxFlat.new()
@export var stylebox_button:StyleBox = StyleBoxFlat.new()

func _draw() -> void:
	var button_left_rect:Rect2 = Rect2(Vector2.ZERO, Vector2(size.y, size.y))
	var button_right_rect:Rect2 = Rect2(Vector2(size.x - size.y, 0), Vector2(size.y, size.y))
	stylebox_normal.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	stylebox_button.draw(get_canvas_item(), button_left_rect)
	stylebox_button.draw(get_canvas_item(), button_right_rect)
	if has_focus():
		stylebox_focus.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	var text:String = String.num(value) + suffex
	var text_lenght:float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER | VERTICAL_ALIGNMENT_CENTER, -1, font_size).x
	var text_baseline:float = font.get_ascent(font_size)
	draw_string(
		font,
		size / 2 - Vector2(text_lenght / 2, -text_baseline / 2),
		text,
		HORIZONTAL_ALIGNMENT_CENTER | VERTICAL_ALIGNMENT_CENTER,
		-1, font_size,
		font_color
	)
	draw_texture_rect(texture_left, button_left_rect.grow(-10), false)
	draw_texture_rect(texture_right, button_right_rect.grow(-10), false)
	

func _gui_input(event:InputEvent) -> void:
	var button_left_rect:Rect2 = Rect2(Vector2.ZERO, Vector2(size.y, size.y))
	var button_right_rect:Rect2 = Rect2(Vector2(size.x - size.y, 0), Vector2(size.y, size.y))
	if has_focus():
		if event.is_action_pressed("ui_left", true):
			value -= step
			value = clamp(value, range_min, range_max)
			change_value(value)
		if event.is_action_pressed("ui_right", true):
			value += step
			value = clamp(value, range_min, range_max)
			change_value(value)
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		if button_left_rect.has_point(event.position):
			value -= step
			value = clamp(value, range_min, range_max)
			change_value(value)
		if button_right_rect.has_point(event.position):
			value += step
			value = clamp(value, range_min, range_max)
			change_value(value)

func change_value(value:float) -> void:
	value_changed.emit(value)
	queue_redraw()

func _notification(what):
	match what:
		NOTIFICATION_MOUSE_ENTER:
			pass # Mouse entered the area of this control.
		NOTIFICATION_MOUSE_EXIT:
			pass # Mouse exited the area of this control.
		NOTIFICATION_FOCUS_ENTER:
			queue_redraw()
		NOTIFICATION_FOCUS_EXIT:
			queue_redraw()
		NOTIFICATION_RESIZED:
			queue_redraw()
