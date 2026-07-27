@tool
extends Control
class_name SiameseOptionButton

signal item_selected(index:int)

@export var index:int = -1
@export var item_list:PackedStringArray = PackedStringArray()
var _internal_item_list:PackedStringArray = PackedStringArray()
@export var longest_text_length:bool = false
@export var clip_text:bool = false
@export var font:Font = load("res://assets/fonts/FangZhengShuSongJianTi-1.ttf")
@export var font_size:int = 22
@export var font_color:Color = Color(1, 1, 1, 1)
@export var font_color_selected:Color = Color(0.7, 0, 0, 1)
@export var texture_left:Texture2D = load("res://assets/texture/spinbox_left.svg")
@export var texture_right:Texture2D = load("res://assets/texture/spinbox_right.svg")
@export var stylebox_normal:StyleBox = StyleBoxFlat.new()
@export var stylebox_focus:StyleBox = StyleBoxFlat.new()
@export var stylebox_button:StyleBox = StyleBoxFlat.new()

var is_editing:bool = false

func _ready() -> void:
	_internal_item_list.append_array(item_list)

func _draw() -> void:
	custom_minimum_size.y = max(texture_left.get_size().y, texture_right.get_size().y)
	if longest_text_length:
		var max_length:float = 40
		for text:String in _internal_item_list:
			var current_text_length:float = font.get_string_size(tr(text), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
			max_length = max(max_length, current_text_length)
		custom_minimum_size.x = size.y * 2 + 20 + max_length
	else:
		custom_minimum_size.x = size.y * 2 + 20 + 40
	size.x = custom_minimum_size.x
	var button_left_rect:Rect2 = Rect2(Vector2.ZERO, Vector2(size.y, size.y))
	var button_right_rect:Rect2 = Rect2(Vector2(size.x - size.y, 0), Vector2(size.y, size.y))
	stylebox_normal.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	stylebox_button.draw(get_canvas_item(), button_left_rect)
	stylebox_button.draw(get_canvas_item(), button_right_rect)
	
	if has_focus():
		stylebox_focus.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	if clip_text:
		var text:String = "-" if index == -1 || _internal_item_list.size() <= index else _internal_item_list[index]
		text = tr(text)
		text = strink_string_in_length(text, 80)
		var text_length:float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		var text_baseline:float = font.get_ascent(font_size)
		draw_string(
			font,
			size / 2 - Vector2(text_length / 2, -text_baseline / 2),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size,
			font_color_selected if is_editing else font_color
		)
	else:
		var text:String = "-" if index == -1 || _internal_item_list.size() <= index else _internal_item_list[index]
		var text_length:float = font.get_string_size(tr(text), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		var text_baseline:float = font.get_ascent(font_size)
		draw_string(
			font,
			size / 2 - Vector2(text_length / 2, -text_baseline / 2),
			tr(text),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size,
			font_color_selected if is_editing else font_color
		)
	draw_texture_rect(texture_left, button_left_rect.grow(-10), false)
	draw_texture_rect(texture_right, button_right_rect.grow(-10), false)

func _gui_input(event:InputEvent) -> void:
	if _internal_item_list.size() == 0:
		return
	var button_left_rect:Rect2 = Rect2(Vector2.ZERO, Vector2(size.y, size.y))
	var button_right_rect:Rect2 = Rect2(Vector2(size.x - size.y, 0), Vector2(size.y, size.y))
	if has_focus():
		if is_editing:
			if event.is_action_pressed("ui_left", true):
				index += _internal_item_list.size() - 1
				index %= _internal_item_list.size()
				select(index)
				get_viewport().set_input_as_handled()
			if event.is_action_pressed("ui_right", true):
				index += 1
				index %= _internal_item_list.size()
				select(index)
				get_viewport().set_input_as_handled()
			if event.is_action_pressed("ui_cancel") || event.is_action_pressed("ui_accept"):
				is_editing = false
				queue_redraw()
				get_viewport().set_input_as_handled()
		else:
			if event.is_action_pressed("ui_accept", true):
				is_editing = true
				queue_redraw()
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		if button_left_rect.has_point(event.position):
			index += _internal_item_list.size() - 1
			index %= _internal_item_list.size()
			select(index)
		if button_right_rect.has_point(event.position):
			index += 1
			index %= _internal_item_list.size()
			select(index)

func add_item(string:String) -> void:
	_internal_item_list.push_back(string)

func get_item_text(_index:int) -> String:
	return _internal_item_list[_index] if _internal_item_list.size() > _index else ""

func clear() -> void:
	_internal_item_list.clear()
	index = -1
	queue_redraw()

func select(value:int) -> void:
	index = value
	item_selected.emit(value)
	queue_redraw()

func set_value_no_signal(value:int) -> void:
	index = value
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

func strink_string_in_length(text:String, length:float) -> String:
	var l:int = 0
	var r:int = text.length() - 1
	while l < r:
		var mid:int = (l + r) / 2
		if font.get_string_size(text.substr(mid), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x > length:
			l = mid + 1
		else:
			r = mid
	return text.substr(l)
