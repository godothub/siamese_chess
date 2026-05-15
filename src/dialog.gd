extends CanvasLayer

signal on_next()
signal on_select(selected:String)
signal on_cancel()
signal on_focus()

const packed_scene:PackedScene = preload("res://scene/dialog.tscn")

const global_selection:Array = ["SELECTION_CAMERA", "SELECTION_THIRD_EYE", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS"]

var border_position:bool = true
var text_label:RichTextLabel = null
var title_label:RichTextLabel = null
var time_label:RichTextLabel = null
var cancel_label:RichTextLabel = null

var text:String = ""
var title:String = ""
var selection:PackedStringArray = []
var selected:String = ""
var select_focus:int = -1
var global_selection_showing:bool = false
var cancel_showing:bool = false
var level_selection:bool = false
var waiting:bool = false
var click_anywhere:bool = false
var force_selection:bool = false
var click_cooldown:float = 0
var tween:Tween = null

func _ready() -> void:
	set_border_position(false)
	$texture_rect_bottom/label.connect("meta_clicked", clicked_selection)
	$texture_rect_right/label.connect("meta_clicked", clicked_selection)
	$texture_rect_top/label.connect("meta_clicked", clicked_global_selection)
	$texture_rect_left/label.connect("meta_clicked", clicked_global_selection)
	$texture_rect_bottom/label.connect("meta_hover_started", hover_selection)
	$texture_rect_right/label.connect("meta_hover_started", hover_selection)
	$texture_rect_top/label.connect("meta_hover_started", hover_selection)
	$texture_rect_left/label.connect("meta_hover_started", hover_selection)
	$texture_rect_top/label.connect("mouse_entered", show_global_selection)
	$texture_rect_top/label.connect("mouse_exited", hide_global_selection)
	$texture_rect_left/label.connect("mouse_entered", show_global_selection.call_deferred)
	$texture_rect_left/label.connect("mouse_exited", hide_global_selection)
	$texture_rect_top/label_hint_left.connect("gui_input", cancel_gui_input)
	$texture_rect_top/label_hint_left.connect("mouse_entered", hover_label.bind($texture_rect_top/label_hint_left))
	$texture_rect_top/label_hint_right.connect("mouse_entered", hover_label.bind($texture_rect_top/label_hint_right))
	$texture_rect_left/label_hint_up.connect("gui_input", cancel_gui_input)
	$texture_rect_left/label_hint_up.connect("mouse_entered", hover_label.bind($texture_rect_left/label_hint_up))
	$texture_rect_left/label_hint_down.connect("mouse_entered", hover_label.bind($texture_rect_left/label_hint_down))
	Setting.connect("language_changed", update_dialog)
	Setting.connect("dialog_border_changed", update_dialog)

func _unhandled_input(event:InputEvent) -> void:
	if click_anywhere && !waiting:
		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed && Time.get_unix_time_from_system() - click_cooldown >= 0.3:
			next()
			click_cooldown = Time.get_unix_time_from_system()
	if block_input():
		get_viewport().set_input_as_handled()

func cancel_gui_input(_event:InputEvent) -> void:
	if _event is InputEventMouseButton && _event.button_index == MOUSE_BUTTON_LEFT && _event.pressed:
		on_cancel.emit()

func push_dialog(_text:String, _title:String, blackscreen:bool = false, _click_anywhere:bool = false, _waiting:bool = false) -> void:
	text = _text
	title = _title
	if tween && tween.is_running():
		tween.kill()
	if text_label.text != "" || title_label.text != "":
		clear()
	if click_anywhere:
		on_focus.emit()
	tween = create_tween()
	force_selection = false	
	waiting = _waiting
	click_anywhere = _click_anywhere
	text_label.text = ""
	if blackscreen:
		tween.tween_property($texture_rect_full, "visible", true, 0)
	tween.tween_interval(0.3)
	tween.tween_property(text_label, "text", tr(text), 0)
	tween.tween_property(title_label, "text", tr(title), 0)
	tween.tween_property($texture_rect_full, "visible", false, 0)

	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(tr(_text), Setting.get_value("voice"), 50, 1, 1, 0, true)

func push_selection(_selection:PackedStringArray, _title:String, _force_selection:bool = true, blackscreen:bool = false) -> void:
	click_anywhere = false
	force_selection = _force_selection
	selection = _selection
	text = selection_to_bbcode(_selection)
	title = _title
	if tween && tween.is_running():
		tween.kill()
	if text_label.text != "" || title_label.text != "":
		clear()
	if force_selection:
		on_focus.emit()
	tween = create_tween()
	if blackscreen:
		tween.tween_property($texture_rect_full, "visible", true, 0)
	tween.tween_interval(0.3)
	tween.tween_property(text_label, "text", text, 0)
	tween.tween_property(title_label, "text", tr(title), 0)
	tween.tween_property($texture_rect_full, "visible", false, 0)

func show_global_selection() -> void:
	click_cooldown = Time.get_unix_time_from_system()
	global_selection_showing = true
	title_label.text = selection_to_bbcode(global_selection)

func hide_global_selection() -> void:
	global_selection_showing = false
	title_label.text = title

func set_hint_left(_text:String) -> void:
	cancel_label.text = _text

func set_hint_right(_text:String) -> void:
	time_label.text = _text

func show_cancel() -> void:
	cancel_showing = true
	cancel_label.text = "SELECTION_CANCEL"

func hide_cancel() -> void:
	cancel_showing = false
	cancel_label.text = ""

func clear() -> void:
	if tween && tween.is_running():
		tween.kill()
	text_label.text = ""
	title_label.text = ""
	click_anywhere = false
	force_selection = false
	waiting = false
	text = ""
	title = ""
	selection.clear()
	select_focus = -1

func next() -> void:
	$audio_stream_player_confirm.play()
	text_label.text = ""
	title_label.text = ""
	click_anywhere = false
	force_selection = false
	waiting = false
	selection.clear()
	select_focus = -1
	on_next.emit()

func direction(axis:int) -> void:
	if !global_selection_showing && !selection.size():
		return
	if select_focus == -1:
		select_focus = 0 if axis == 1 else selection.size() - 1
		on_focus.emit()
	else:
		select_focus += axis
	if global_selection_showing:
		select_focus = (select_focus + global_selection.size()) % global_selection.size()
	else:
		select_focus = (select_focus + selection.size()) % selection.size()
	if global_selection_showing:
		title_label.text = selection_to_bbcode(global_selection, select_focus)
		$audio_stream_player_select.play()
		if Setting.get_value("text_to_speech"):
			DisplayServer.tts_stop()
			DisplayServer.tts_speak(tr(global_selection[select_focus]), Setting.get_value("voice"))
	else:
		selected = selection[select_focus]
		text_label.text = selection_to_bbcode(selection, select_focus)
		$audio_stream_player_select.play()
		if Setting.get_value("text_to_speech"):
			DisplayServer.tts_stop()
			DisplayServer.tts_speak(tr(selection[select_focus]), Setting.get_value("voice"))

func confirm() -> void:
	if global_selection_showing:
		clicked_global_selection(global_selection[select_focus])
		hide_global_selection()
		select_focus = -1
		return
	if select_focus != -1:
		on_select.emit(selected)
	next()

func cancel_focus() -> void:
	select_focus = -1
	text_label.text = selection_to_bbcode(selection)

func clicked_selection(_selected:String) -> void:
	if Time.get_unix_time_from_system() - click_cooldown < 0.3:
		return
	selected = _selected
	on_select.emit(_selected)
	next()

func clicked_global_selection(_selected:String) -> void:
	if Time.get_unix_time_from_system() - click_cooldown < 0.3:
		return
	$audio_stream_player_confirm.play()
	match _selected:
		"SELECTION_DOCUMENTS":
			Archive.open()
		"SELECTION_CAMERA":
			#var from_position:Vector3 = chessboard.chessboard_piece[from].global_position
			#from_position += Vector3(0, 1.6, 0)
			#var from_rotation:Vector3 = chessboard.chessboard_piece[from].global_rotation
			#Photo.move_camera(from_position, from_rotation)
			Photo.open()
		"SELECTION_THIRD_EYE":
			#ThirdEye3D.set_state(chessboard.state)
			ThirdEye3D.open()
		"SELECTION_SETTINGS":
			Setting.open()

func hover_label(label:RichTextLabel) -> void:
	$audio_stream_player_select.play()
	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(tr(label.text), Setting.get_value("voice"), 50, 1, 1, 0, true)

func hover_selection(_selected:String) -> void:
	$audio_stream_player_select.play()
	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(tr(_selected), Setting.get_value("voice"), 50, 1, 1, 0, true)

func selection_to_bbcode(_selection:PackedStringArray, _select_focus:int = -1) -> String:
	var bbcode:String = ""
	for i:int in _selection.size():
		if i == _select_focus:
			bbcode += "[url=\"" + _selection[i] + "\"][color=red]" + tr(_selection[i]) + "[/color][/url]"
		else:
			bbcode += "[url=\"" + _selection[i] + "\"]" + tr(_selection[i]) + "[/url]"
		if i == _selection.size() - 1:
			break
		if !border_position:
			bbcode += "  "
		else:
			bbcode += "\n\n"
	return bbcode

func block_input() -> bool:
	return click_anywhere || force_selection || select_focus != -1 || Time.get_unix_time_from_system() - click_cooldown < 0.3

func update_dialog() -> void:
	set_border_position(Setting.get_value("dialog_border"))
	if selection:
		text = selection_to_bbcode(selection, select_focus)
		text_label.text = text
	else:
		text_label.text = tr(text)
	title_label.text = tr(title)

func set_border_position(_border_position:bool) -> void:
	border_position = _border_position
	if !border_position:
		$texture_rect_left.visible = false
		$texture_rect_right.visible = false
		$texture_rect_top.visible = true
		$texture_rect_bottom.visible = true
		text_label = $texture_rect_bottom/label
		title_label = $texture_rect_top/label
		time_label = $texture_rect_top/label_hint_right
		cancel_label = $texture_rect_top/label_hint_left
	else:
		$texture_rect_left.visible = true
		$texture_rect_right.visible = true
		$texture_rect_top.visible = false
		$texture_rect_bottom.visible = false
		text_label = $texture_rect_right/label
		title_label = $texture_rect_left/label
		time_label = $texture_rect_left/label_hint_down
		cancel_label = $texture_rect_left/label_hint_up
