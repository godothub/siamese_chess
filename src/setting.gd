extends CanvasLayer

signal language_changed()
signal dialog_border_changed()
signal touch_gesture_changed()

var resolutions:Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1024, 600),
	Vector2i(1152, 648),
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var languages:Dictionary[String, String] = {
	"en": "English",
	"zh_CN": "简体中文"
}

var axis:Array[Vector2i] = [
	Vector2(1, 1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(-1, -1)
]

var table:Dictionary = {}

@onready var resolution_input:OptionButton = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_resolution/h_box_container/option_button
@onready var fullscreen_input:CheckBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fullscreen/h_box_container/check_box
@onready var fps_input:OptionButton = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fps/h_box_container/option_button
@onready var vsync_input:CheckBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_vsync/h_box_container/check_box
@onready var master_volume_input:HSlider = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_master_volume/v_box_container/h_slider
@onready var master_volume_value:Label = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_master_volume/v_box_container/h_box_container/label_value
@onready var sfx_volume_input:HSlider = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_sfx_volume/v_box_container/h_slider
@onready var sfx_volume_value:Label = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_sfx_volume/v_box_container/h_box_container/label_value
@onready var env_volume_input:HSlider = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_env_volume/v_box_container/h_slider
@onready var env_volume_value:Label = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_env_volume/v_box_container/h_box_container/label_value
@onready var camera_move_speed_input:HSlider = $texture_rect/tab_container/control/v_box_container/margin_container_camera_move_speed/v_box_container/h_slider
@onready var camera_move_speed_value:Label = $texture_rect/tab_container/control/v_box_container/margin_container_camera_move_speed/v_box_container/h_box_container/label_value
@onready var camera_rotate_sensitive_input:HSlider = $texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_sensitive/v_box_container/h_slider
@onready var camera_rotate_sensitive_value:Label = $texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_sensitive/v_box_container/h_box_container/label_value
@onready var camera_rotate_axis_input:OptionButton = $texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_axis/h_box_container/option_button
@onready var language_input:OptionButton = $texture_rect/tab_container/accessibility/v_box_container/margin_container_language/h_box_container/option_button
@onready var dialog_border_input:CheckBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_dialog_border/v_box_container/h_box_container/check_box
@onready var text_to_speech_input:CheckBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/check_box
@onready var touch_gesture_input:CheckBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_touch_gesture/v_box_container/h_box_container/check_box
@onready var relax_input:CheckBox = $texture_rect/tab_container/game/v_box_container/margin_container_relax/v_box_container/h_box_container/check_box
@onready var clean_archive_input:Button = $texture_rect/tab_container/files/v_box_container/margin_container_clean_archive/h_box_container/button
@onready var reset_progress_input:Button = $texture_rect/tab_container/files/v_box_container/margin_container_reset_progress/v_box_container/h_box_container/button

func _ready() -> void:
	set_physics_process(false)
	if !resolutions.has(get_viewport().size):
		resolutions.push_front(get_viewport().size)
	
	for iter:Vector2i in resolutions:
		resolution_input.add_item("%d * %d" % [iter.x, iter.y])
	for key:String in languages:
		language_input.add_item(languages[key])
	load_file()

	resolution_input.connect("item_selected", set_resolution)
	fullscreen_input.connect("toggled", set_fullscreen)
	fps_input.connect("item_selected", set_fps)
	vsync_input.connect("toggled", set_vsync)
	master_volume_input.connect("value_changed", set_master_volume)
	sfx_volume_input.connect("value_changed", set_sfx_volume)
	env_volume_input.connect("value_changed", set_env_volume)
	camera_move_speed_input.connect("value_changed", set_camera_move_speed)
	camera_rotate_sensitive_input.connect("value_changed", set_camera_rotate_sensitive)
	camera_rotate_axis_input.connect("item_selected", set_camera_rotate_axis)
	language_input.connect("item_selected", set_language)
	dialog_border_input.connect("toggled", set_dialog_border)
	text_to_speech_input.connect("toggled", set_text_to_speech)
	touch_gesture_input.connect("toggled", set_touch_gesture)
	relax_input.connect("toggled", set_relax)
	clean_archive_input.connect("pressed", set_clean_archive)
	reset_progress_input.connect("pressed", set_reset_progress)
	$texture_rect/button_close.connect("pressed", close)

	resolution_input.select(table.get_or_add("resolution", 0))
	set_resolution(table.get_or_add("resolution"))
	fullscreen_input.set_pressed(table.get_or_add("fullscreen", false))
	fps_input.select(table.get_or_add("fps", 6))
	set_fps(table.get_or_add("fps"))
	vsync_input.set_pressed(table.get_or_add("vsync", true))
	master_volume_input.set_value(table.get_or_add("master_volume", 80))
	master_volume_value.text = "%d%%" % table.get_or_add("master_volume", 80)
	sfx_volume_input.set_value(table.get_or_add("sfx_volume", 80))
	sfx_volume_value.text = "%d%%" % table.get_or_add("sfx_volume", 80)
	env_volume_input.set_value(table.get_or_add("env_volume", 80))
	env_volume_value.text = "%d%%" % (table.get_or_add("env_volume", 80))
	language_input.select(table.get_or_add("language", languages.keys().find(TranslationServer.get_locale())))
	dialog_border_input.set_pressed(table.get_or_add("dialog_border", false))
	text_to_speech_input.set_pressed(table.get_or_add("text_to_speech", false))
	update_voice()
	touch_gesture_input.set_pressed(table.get_or_add("touch_gesture", false))
	relax_input.set_pressed(table.get_or_add("relax", false))
	camera_move_speed_input.set_value(table.get_or_add("camera_move_speed", 50))
	camera_move_speed_value.text = "%d%%" % (table.get_or_add("camera_move_speed", 50))
	camera_rotate_sensitive_input.set_value(table.get_or_add("camera_rotate_sensitive", 50))
	camera_rotate_sensitive_value.text = "%d%%" % (table.get_or_add("camera_rotate_sensitive", 50))
	camera_rotate_axis_input.select(table.get_or_add("camera_rotate_axis", 0))
	visible = false
	set_language(table.get_or_add("language"))

	$texture_rect/tab_container.connect("tab_hovered", hover_tab)
	$texture_rect/tab_container.get_tab_bar().connect("focus_entered", focus_tab)
	$texture_rect/tab_container.connect("tab_selected", selected_tab)
	$texture_rect/button_close.connect("mouse_entered", read_close)
	$texture_rect/button_close.connect("focus_entered", read_close)
	var labels:Array = [
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_sfx_volume/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_env_volume/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_master_volume/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fullscreen/h_box_container/label_name,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fps/h_box_container/label_name,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_vsync/h_box_container/label_name,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_resolution/h_box_container/label_name,
		$texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_sensitive/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_axis/h_box_container/label_name,
		$texture_rect/tab_container/control/v_box_container/margin_container_camera_move_speed/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_dialog_border/v_box_container/label_explain,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_dialog_border/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/label_explain,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_touch_gesture/v_box_container/label_explain,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_touch_gesture/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_language/h_box_container/label_name,
		$texture_rect/tab_container/files/v_box_container/margin_container_reset_progress/v_box_container/label_explain,
		$texture_rect/tab_container/files/v_box_container/margin_container_reset_progress/v_box_container/h_box_container/label_name,
		$texture_rect/tab_container/files/v_box_container/margin_container_clean_archive/h_box_container/label_name,
		$texture_rect/tab_container/game/v_box_container/margin_container_relax/v_box_container/label_explain,
		$texture_rect/tab_container/game/v_box_container/margin_container_relax/v_box_container/h_box_container/label_name
	]
	var buttons:Array = [
		$texture_rect/tab_container/files/v_box_container/margin_container_reset_progress/v_box_container/h_box_container/button,
		$texture_rect/tab_container/files/v_box_container/margin_container_clean_archive/h_box_container/button
	]
	var check_boxes:Array = [
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fullscreen/h_box_container/check_box,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_vsync/h_box_container/check_box,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_dialog_border/v_box_container/h_box_container/check_box,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/check_box,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_touch_gesture/v_box_container/h_box_container/check_box,
		$texture_rect/tab_container/game/v_box_container/margin_container_relax/v_box_container/h_box_container/check_box
	]
	var option_buttons:Array = [
		$texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_axis/h_box_container/option_button,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fps/h_box_container/option_button,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_resolution/h_box_container/option_button,
		$texture_rect/tab_container/accessibility/v_box_container/margin_container_language/h_box_container/option_button
	]
	var sliders:Array = [
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_sfx_volume/v_box_container/h_slider,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_env_volume/v_box_container/h_slider,
		$texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_master_volume/v_box_container/h_slider,
		$texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_sensitive/v_box_container/h_slider,
		$texture_rect/tab_container/control/v_box_container/margin_container_camera_move_speed/v_box_container/h_slider
	]
	
	for iter:Label in labels:
		iter.connect("mouse_entered", hover_label.bind(iter))
		iter.focus_mode = Control.FOCUS_ALL
		iter.connect("focus_entered", hover_label.bind(iter))
	for iter:Button in buttons:
		iter.connect("mouse_entered", hover_label.bind(iter))
		iter.connect("focus_entered", hover_label.bind(iter))
	for iter:CheckBox in check_boxes:
		iter.connect("mouse_entered", hover_check_box.bind(iter))
		iter.connect("focus_entered", hover_check_box.bind(iter))
		iter.connect("toggled", change_check_box)
	for iter:OptionButton in option_buttons:
		iter.connect("mouse_entered", hover_option_button.bind(iter))
		iter.connect("focus_entered", hover_option_button.bind(iter))
		iter.connect("toggled", show_option_button)
		iter.connect("item_focused", hover_option_button_selection.bind(iter))
		iter.connect("item_selected", selected_option_button.bind(iter))
	for iter:Slider in sliders:
		iter.connect("mouse_entered", hover_slider.bind(iter))
		iter.connect("focus_entered", hover_slider.bind(iter))
		iter.connect("value_changed", change_slider)

func _physics_process(_delta:float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()

func open() -> void:
	show()
	set_physics_process(true)
	$audio_stream_player_open.play()
	$texture_rect/tab_container.get_tab_bar().grab_focus()

func close() -> void:
	$audio_stream_player_confirm.play()
	$audio_stream_player_close.play()
	save_file()
	set_physics_process(false)
	hide()

func load_file() -> void:
	var file:FileAccess = FileAccess.open("user://settings.json", FileAccess.READ)
	if !is_instance_valid(file):
		return
	table = JSON.parse_string(file.get_as_text())
	file.close()

func save_file() -> void:
	var file:FileAccess = FileAccess.open("user://settings.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(table))
	file.close()

func get_value(key:String) -> Variant:
	return table[key]

func read_close() -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("ICON_CLOSE"), get_value("voice"), 50, 1, 1, 0, true)

func focus_tab() -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr($texture_rect/tab_container.get_tab_bar().get_tab_title($texture_rect/tab_container.current_tab)), get_value("voice"), 50, 1, 1, 0, true)

func hover_tab(tab:int) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr($texture_rect/tab_container.get_tab_bar().get_tab_title(tab)), get_value("voice"), 50, 1, 1, 0, true)

func selected_tab(tab:int) -> void:
	$audio_stream_player_confirm.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_TAB_SELECTED").format({"selection": tr($texture_rect/tab_container.get_tab_bar().get_tab_title(tab))}), get_value("voice"), 50, 1, 1, 0, true)

func hover_label(label:Control) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr(label.text), get_value("voice"), 50, 1, 1, 0, true)

func hover_check_box(check_box:CheckBox) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("ICON_TURN_ON") if check_box.button_pressed else tr("ICON_TURN_OFF"), get_value("voice"), 50, 1, 1, 0, true)

func change_check_box(toggled:bool) -> void:
	$audio_stream_player_confirm.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_CHECKBOX_ON") if toggled else tr("SETTINGS_CHECKBOX_OFF"), get_value("voice"), 50, 1, 1, 0, true)

func hover_option_button(option_button:OptionButton) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_OPTION_BUTTON_HOVERED").format({"selection": tr(option_button.get_item_text(option_button.selected))}), get_value("voice"), 50, 1, 1, 0, true)

func hover_option_button_selection(index:int, option_button:OptionButton) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr(option_button.get_item_text(index)), get_value("voice"), 50, 1, 1, 0, true)

func show_option_button(toggled:bool) -> void:
	$audio_stream_player_confirm.play()
	if !toggled:
		return
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_OPTION_BUTTON_SHOW"), get_value("voice"), 50, 1, 1, 0, true)

func selected_option_button(index:int, option_button:OptionButton) -> void:
	$audio_stream_player_confirm.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_OPTION_BUTTON_SELECTED").format({"selection": tr(option_button.get_item_text(index))}), get_value("voice"), 50, 1, 1, 0, true)

func hover_slider(slider:Slider) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_SLIDER_HOVERED") % slider.value, get_value("voice"), 50, 1, 1, 0, true)

func change_slider(value:float) -> void:
	$audio_stream_player_select.play()
	if get_value("text_to_speech"):
		DisplayServer.tts_speak(tr("SETTINGS_SLIDER_CHANGED") % value, get_value("voice"), 50, 1, 1, 0, true)

func set_resolution(index:int) -> void:
	table.set("resolution", index)
	get_viewport().size = resolutions[index]

func set_fullscreen(toggled_on:bool) -> void:
	table.set("fullscreen", toggled_on)
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_fps(index:int) -> void:
	table.set("fps", index)
	match index:
		0:
			Engine.max_fps = 10
		1:
			Engine.max_fps = 30
		2:
			Engine.max_fps = 60
		3:
			Engine.max_fps = 90
		4:
			Engine.max_fps = 120
		5:
			Engine.max_fps = 144
		6:
			Engine.max_fps = -1

func set_vsync(toggled_on:bool) -> void:
	table.set("vsync", toggled_on)
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSyncMode.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSyncMode.VSYNC_DISABLED)

func set_master_volume(value:float) -> void:
	table.set("master_volume", value)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Master"), value / 100.0)
	master_volume_value.text = "%d%%" % value

func set_sfx_volume(value:float) -> void:
	table.set("sfx_volume", value)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"SFX"), value / 100.0)
	sfx_volume_value.text = "%d%%" % value

func set_env_volume(value:float) -> void:
	table.set("env_volume", value)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Ambient"), value / 100.0)
	env_volume_value.text = "%d%%" % value

func set_camera_move_speed(value:float) -> void:
	table.set("camera_move_speed", value)
	camera_move_speed_value.text = "%d%%" % value

func set_camera_rotate_sensitive(value:float) -> void:
	table.set("camera_rotate_sensitive", value)
	camera_rotate_sensitive_value.text = "%d%%" % value

func set_camera_rotate_axis(index:int) -> void:
	table.set("camera_rotate_axis", index)

func set_language(index:int) -> void:
	table.set("language", index)
	TranslationServer.set_locale(languages.keys()[index])
	language_changed.emit()
	if table.get_or_add("text_to_speech", false):
		update_voice()

func set_dialog_border(toggled_on:bool) -> void:
	table.set("dialog_border", toggled_on)
	dialog_border_changed.emit()

func set_text_to_speech(toggled_on:bool) -> void:
	table.set("text_to_speech", toggled_on)
	if toggled_on:
		update_voice()

func update_voice() -> void:
	var voices:PackedStringArray = DisplayServer.tts_get_voices_for_language(TranslationServer.get_locale())
	if voices.size() == 0:
		return
	var voice:String = voices[0]
	table.set("voice", voice)

func set_touch_gesture(toggled_on:bool) -> void:
	table.set("touch_gesture", toggled_on)
	touch_gesture_changed.emit()

func set_relax(toggled_on:bool) -> void:
	table.set("relax", toggled_on)

func set_clean_archive() -> void:
	if DirAccess.dir_exists_absolute("user://archive"):
		var dir:DirAccess = DirAccess.open("user://archive")
		var remove_list:PackedStringArray = []
		dir.list_dir_begin()
		var file_name:String = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				remove_list.push_back(file_name)
			file_name = dir.get_next()
		for iter:String in remove_list:
			DirAccess.remove_absolute("user://archive/" + iter)
		DirAccess.remove_absolute("user://archive")
	var toast:Toast = Toast.create_instance("SETTINGS_RESET_DOCUMENTS_SUCCESS")
	add_child(toast)

func set_reset_progress() -> void:
	Progress.clear()
	Loading.change_scene("res://scene/startup.tscn", {})
	close()
