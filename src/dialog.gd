extends CanvasLayer

signal on_next()

const packed_scene:PackedScene = preload("res://scene/dialog.tscn")
var selection:PackedStringArray = []
var selected:String = ""
var waiting:bool = false
var click_anywhere:bool = false
var force_selection:bool = false
var click_cooldown:float = 0
var tween:Tween = null

func _ready() -> void:
	$texture_rect_bottom/label.connect("meta_clicked", clicked_selection)
	
func _unhandled_input(event:InputEvent) -> void:
	if click_anywhere && !waiting:
		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed && Time.get_unix_time_from_system() - click_cooldown >= 0.3:
			next()
			click_cooldown = Time.get_unix_time_from_system()
	if block_input():
		get_viewport().set_input_as_handled()

func push_dialog(text:String, title:String, blackscreen:bool = false, _click_anywhere:bool = false, _waiting:bool = false) -> void:
	if tween && tween.is_running():
		tween.kill()
	if $texture_rect_bottom/label.text != "" || $texture_rect_top/label.text != "":
		clear()
	tween = create_tween()
	force_selection = false
	waiting = _waiting
	click_anywhere = _click_anywhere
	$texture_rect_bottom/label.text = ""
	if blackscreen:
		tween.tween_property($texture_rect_full, "visible", true, 0)
	tween.tween_interval(0.3)
	tween.tween_property($texture_rect_bottom/label, "text", tr(text), 0)
	tween.tween_property($texture_rect_top/label, "text", tr(title), 0)
	tween.tween_property($texture_rect_full, "visible", false, 0)

func push_selection(_selection:PackedStringArray, title:String, _force_selection:bool = true, blackscreen:bool = false) -> void:
	var text:String = ""
	click_anywhere = false
	force_selection = _force_selection
	selection = _selection
	for iter:String in selection:
		text += "[url=\"" + iter + "\"]" + tr(iter) + "[/url]  "
	if tween && tween.is_running():
		tween.kill()
	if $texture_rect_bottom/label.text != "" || $texture_rect_top/label.text != "":
		clear()
	tween = create_tween()
	if blackscreen:
		tween.tween_property($texture_rect_full, "visible", true, 0)
	tween.tween_interval(0.3)
	tween.tween_property($texture_rect_bottom/label, "text", text, 0)
	tween.tween_property($texture_rect_top/label, "text", tr(title), 0)
	tween.tween_property($texture_rect_full, "visible", false, 0)


func clear() -> void:
	if tween && tween.is_running():
		tween.kill()
	$texture_rect_bottom/label.text = ""
	$texture_rect_top/label.text = ""
	click_anywhere = false
	force_selection = false

func next() -> void:
	$texture_rect_bottom/label.text = ""
	$texture_rect_top/label.text = ""
	click_anywhere = false
	waiting = false
	force_selection = false
	on_next.emit.call_deferred()

func clicked_selection(_selected:String) -> void:
	selected = _selected
	next()

func block_input() -> bool:
	return click_anywhere || force_selection || Time.get_unix_time_from_system() - click_cooldown < 0.3
