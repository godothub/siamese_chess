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

@onready var resolution_input:SiameseOptionButton = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_resolution/h_box_container/option_button
@onready var content_scale_input:SiameseSpinBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_content_scale/v_box_container/h_box_container/spin_box
@onready var fullscreen_input:CheckBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fullscreen/h_box_container/check_box
@onready var fps_input:SiameseOptionButton = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_fps/h_box_container/option_button
@onready var vsync_input:CheckBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_left/margin_container_vsync/h_box_container/check_box
@onready var master_volume_input:SiameseSpinBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_master_volume/h_box_container/spin_box
@onready var sfx_volume_input:SiameseSpinBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_sfx_volume/h_box_container/spin_box
@onready var env_volume_input:SiameseSpinBox = $texture_rect/tab_container/video_audio/h_box_container/v_box_container_right/margin_container_env_volume/h_box_container/spin_box
@onready var camera_move_speed_input:SiameseSpinBox = $texture_rect/tab_container/control/v_box_container/margin_container_camera_move_speed/h_box_container/spin_box
@onready var camera_rotate_sensitive_input:SiameseSpinBox = $texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_sensitive/h_box_container/spin_box
@onready var camera_rotate_axis_input:SiameseOptionButton = $texture_rect/tab_container/control/v_box_container/margin_container_camera_rotate_axis/h_box_container/option_button
@onready var language_input:SiameseOptionButton = $texture_rect/tab_container/accessibility/v_box_container/margin_container_language/h_box_container/option_button
@onready var dialog_border_input:CheckBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_dialog_border/v_box_container/h_box_container/check_box
@onready var text_to_speech_input:CheckBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/check_box
@onready var text_to_speech_type_input:SiameseOptionButton = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/grid_container/type/option_button
@onready var text_to_speech_voice_input:SiameseOptionButton = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/grid_container/voice/option_button
@onready var text_to_speech_volume_input:SiameseSpinBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/grid_container/volume/spin_box
@onready var text_to_speech_speed_input:SiameseSpinBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/grid_container/speed/spin_box
@onready var text_to_speech_pitch_input:SiameseSpinBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_text_to_speech/v_box_container/h_box_container/grid_container/pitch/spin_box
@onready var touch_gesture_input:CheckBox = $texture_rect/tab_container/accessibility/v_box_container/margin_container_touch_gesture/v_box_container/h_box_container/check_box
@onready var relax_input:CheckBox = $texture_rect/tab_container/game/v_box_container/margin_container_relax/v_box_container/h_box_container/check_box
@onready var clean_archive_input:Button = $texture_rect/tab_container/files/v_box_container/margin_container_clean_archive/h_box_container/button
@onready var reset_progress_input:Button = $texture_rect/tab_container/files/v_box_container/margin_container_reset_progress/v_box_container/h_box_container/button

@onready var regex_list:RegEx = RegEx.create_from_string("(?i:^\\s*setting\\s*$)")
@onready var regex_set_value:RegEx = RegEx.create_from_string("(?i:^\\s*(?:(set|\\/)\\s+)?(?P<key>\\S+)\\s+(?P<value>\\S+)\\s*$)")
@onready var regex_clean_archive:RegEx = RegEx.create_from_string("(?i:^\\s*(?:clean|reset)\\s+(?:archive|document|documents)\\s*$)")
@onready var regex_reset_progress:RegEx = RegEx.create_from_string("(?i:^\\s*(?:clean|reset)\\s+(?:progress|save)\\s*$)")

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
	content_scale_input.connect("value_changed", set_content_scale)
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
	text_to_speech_type_input.connect("item_selected", set_text_to_speech_type)
	text_to_speech_voice_input.connect("item_selected", set_text_to_speech_voice)
	text_to_speech_volume_input.connect("value_changed", set_text_to_speech_volume)
	text_to_speech_speed_input.connect("value_changed", set_text_to_speech_speed)
	text_to_speech_pitch_input.connect("value_changed", set_text_to_speech_pitch)
	touch_gesture_input.connect("toggled", set_touch_gesture)
	relax_input.connect("toggled", set_relax)
	clean_archive_input.connect("pressed", set_clean_archive)
	reset_progress_input.connect("pressed", set_reset_progress)
	$texture_rect/button_close.connect("pressed", close)

	set_resolution(table.get_or_add("resolution", 0))
	set_content_scale(table.get_or_add("content_scale", 120))
	set_fps(table.get_or_add("fps", 2))
	set_fullscreen(table.get_or_add("fullscreen", false))
	set_vsync(table.get_or_add("vsync", true))
	set_dialog_border(table.get_or_add("dialog_border", false))
	set_text_to_speech(table.get_or_add("text_to_speech", false))
	set_touch_gesture(table.get_or_add("touch_gesture", false))
	set_relax(table.get_or_add("relax", false))

	set_master_volume(table.get_or_add("master_volume", 80))
	set_sfx_volume(table.get_or_add("sfx_volume", 80))
	set_env_volume(table.get_or_add("env_volume", 80))
	table.get_or_add("language", languages.keys().find(TranslationServer.get_locale()))
	TranslationServer.set_locale(languages.keys()[table.get("language")])
	language_changed.emit()
	table.get_or_add("text_to_speech_type", 0)
	set_text_to_speech_volume(table.get_or_add("text_to_speech_volume", 80))
	set_text_to_speech_speed(table.get_or_add("text_to_speech_speed", 100))
	set_text_to_speech_pitch(table.get_or_add("text_to_speech_pitch", 100))
	set_camera_move_speed(table.get_or_add("camera_move_speed", 50))
	set_camera_rotate_sensitive(table.get_or_add("camera_rotate_sensitive", 50))
	visible = false

	$texture_rect/tab_container.connect("tab_hovered", hover_tab)
	$texture_rect/tab_container.get_tab_bar().connect("focus_entered", focus_tab)
	$texture_rect/tab_container.connect("tab_selected", selected_tab)
	$texture_rect/button_close.connect("mouse_entered", read_close)
	$texture_rect/button_close.connect("focus_entered", read_close)

	# 堆栈DFS找全部节点
	var dfs_stack:Array = [self]
	while dfs_stack.size():
		var iter:Node = dfs_stack.pop_back()
		dfs_stack.append_array(iter.get_children())
		if iter == $texture_rect/button_close:
			continue
		if iter is Label:
			iter.connect("mouse_entered", hover_label.bind(iter))
			iter.focus_mode = Control.FOCUS_ALL
			iter.connect("focus_entered", focus_label.bind(iter))
		if iter is Button:
			iter.connect("mouse_entered", hover_label.bind(iter))
			iter.connect("focus_entered", focus_label.bind(iter))
		if iter is CheckBox:
			iter.connect("mouse_entered", hover_check_box.bind(iter))
			iter.connect("focus_entered", focus_check_box.bind(iter))
			iter.connect("toggled", change_check_box)
		if iter is SiameseOptionButton:
			iter.connect("mouse_entered", hover_option_button.bind(iter))
			iter.connect("focus_entered", focus_option_button.bind(iter))
			iter.connect("item_selected", selected_option_button.bind(iter))
		if iter is SiameseSpinBox:
			iter.connect("mouse_entered", hover_spinbox.bind(iter))
			iter.connect("focus_entered", focus_spinbox.bind(iter))
			iter.connect("value_changed", change_spinbox)
	Terminal.connect("command_received", on_command_received)

func _physics_process(_delta:float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()

func open() -> void:
	show()
	set_physics_process(true)
	$audio_stream_player_open.play()
	$texture_rect/tab_container.get_tab_bar().grab_focus()
	update_voice_list()
	resolution_input.select(table.get_or_add("resolution", 0))
	content_scale_input.set_value_no_signal(table.get_or_add("content_scale", 100))
	fullscreen_input.set_pressed_no_signal(table.get_or_add("fullscreen", false))
	fps_input.select(table.get_or_add("fps", 6))
	vsync_input.set_pressed_no_signal(table.get_or_add("vsync", true))
	master_volume_input.set_value_no_signal(table.get_or_add("master_volume", 80))
	sfx_volume_input.set_value_no_signal(table.get_or_add("sfx_volume", 80))
	env_volume_input.set_value_no_signal(table.get_or_add("env_volume", 80))
	language_input.select(table.get_or_add("language", languages.keys().find(TranslationServer.get_locale())))
	dialog_border_input.set_pressed_no_signal(table.get_or_add("dialog_border", false))
	text_to_speech_input.set_pressed_no_signal(table.get_or_add("text_to_speech", false))
	text_to_speech_type_input.select(table.get_or_add("text_to_speech_type", 0))
	text_to_speech_voice_input.select(table.get_or_add("text_to_speech_voice", -1))
	text_to_speech_volume_input.set_value_no_signal(table.get_or_add("text_to_speech_volume", 80))
	text_to_speech_speed_input.set_value_no_signal(table.get_or_add("text_to_speech_speed", 100))
	text_to_speech_pitch_input.set_value_no_signal(table.get_or_add("text_to_speech_pitch", 100))
	touch_gesture_input.set_pressed_no_signal(table.get_or_add("touch_gesture", false))
	relax_input.set_pressed_no_signal(table.get_or_add("relax", false))
	camera_move_speed_input.set_value_no_signal(table.get_or_add("camera_move_speed", 50))
	camera_rotate_sensitive_input.set_value_no_signal(table.get_or_add("camera_rotate_sensitive", 50))
	camera_rotate_axis_input.select(table.get_or_add("camera_rotate_axis", 0))

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

func set_value(key:String, value:Variant) -> void:
	table[key] = value

func read_close() -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("ICON_CLOSE"), true)

func focus_tab() -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr($texture_rect/tab_container.get_tab_bar().get_tab_title($texture_rect/tab_container.current_tab)), true)

func hover_tab(tab:int) -> void:
	$audio_stream_player_select.play()
	$texture_rect/tab_container.current_tab = tab
	Narrative.speak(tr($texture_rect/tab_container.get_tab_bar().get_tab_title(tab)), true)

func selected_tab(tab:int) -> void:
	$audio_stream_player_confirm.play()
	Narrative.speak(tr("SETTINGS_TAB_SELECTED").format({"selection": tr($texture_rect/tab_container.get_tab_bar().get_tab_title(tab))}), true)

func hover_label(label:Control) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr(label.text), true)

func focus_label(label:Control) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr(label.text), true)

func hover_check_box(check_box:CheckBox) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("ICON_TURN_ON") if check_box.button_pressed else tr("ICON_TURN_OFF"), true)

func focus_check_box(check_box:CheckBox) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("ICON_TURN_ON") if check_box.button_pressed else tr("ICON_TURN_OFF"), true)

func change_check_box(toggled:bool) -> void:
	$audio_stream_player_confirm.play()
	Narrative.speak(tr("SETTINGS_CHECKBOX_ON") if toggled else tr("SETTINGS_CHECKBOX_OFF"), true)

func hover_option_button(option_button:SiameseOptionButton) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("SETTINGS_OPTION_BUTTON_HOVERED").format({"selection": tr(option_button.get_item_text(option_button.index))}), true)

func focus_option_button(option_button:SiameseOptionButton) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("SETTINGS_OPTION_BUTTON_HOVERED").format({"selection": tr(option_button.get_item_text(option_button.index))}), true)

func show_option_button(toggled:bool) -> void:
	$audio_stream_player_confirm.play()
	if !toggled:
		return
	Narrative.speak(tr("SETTINGS_OPTION_BUTTON_SHOW"), true)

func selected_option_button(index:int, option_button:SiameseOptionButton) -> void:
	$audio_stream_player_confirm.play()
	Narrative.speak(tr("SETTINGS_OPTION_BUTTON_SELECTED").format({"selection": tr(option_button.get_item_text(index))}), true)

func hover_spinbox(spinbox:SiameseSpinBox) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("SETTINGS_SLIDER_HOVERED") % spinbox.value, true)

func focus_spinbox(spinbox:SiameseSpinBox) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("SETTINGS_SLIDER_HOVERED") % spinbox.value, true)

func change_spinbox(value:float) -> void:
	$audio_stream_player_select.play()
	Narrative.speak(tr("SETTINGS_SLIDER_CHANGED") % value, true)

func set_resolution(index:int) -> void:
	table.set("resolution", index)
	get_window().size = resolutions[index]
	get_window().content_scale_size = resolutions[index]

func set_fullscreen(toggled_on:bool) -> void:
	table.set("fullscreen", toggled_on)
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_content_scale(value:float) -> void:
	table.set("content_scale", value)
	get_tree().root.content_scale_factor = value / 100.0

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

func set_sfx_volume(value:float) -> void:
	table.set("sfx_volume", value)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"SFX"), value / 100.0)

func set_env_volume(value:float) -> void:
	table.set("env_volume", value)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Ambient"), value / 100.0)

func set_camera_move_speed(value:float) -> void:
	table.set("camera_move_speed", value)

func set_camera_rotate_sensitive(value:float) -> void:
	table.set("camera_rotate_sensitive", value)

func set_camera_rotate_axis(index:int) -> void:
	table.set("camera_rotate_axis", index)

func set_language(index:int) -> void:
	table.set("language", index)
	TranslationServer.set_locale(languages.keys()[index])
	language_changed.emit()
	update_voice_list()
	set_text_to_speech_voice(0)

func set_dialog_border(toggled_on:bool) -> void:
	table.set("dialog_border", toggled_on)
	dialog_border_changed.emit()

func set_text_to_speech(toggled_on:bool) -> void:
	table.set("text_to_speech", toggled_on)

func set_text_to_speech_type(index:int) -> void:
	table.set("text_to_speech_type", index)
	update_voice_list()
	set_text_to_speech_voice(0)

func set_text_to_speech_voice(index:int) -> void:
	table.set("text_to_speech_voice", index)
	Narrative.set_voice(index)

func set_text_to_speech_volume(value:float) -> void:
	table.set("text_to_speech_volume", value)

func set_text_to_speech_speed(value:float) -> void:
	table.set("text_to_speech_speed", value)

func set_text_to_speech_pitch(value:float) -> void:
	table.set("text_to_speech_pitch", value)

func update_voice_list() -> void:
	var voices:PackedStringArray = Narrative.get_voice_list()
	if voices.size() == 0:
		return
	text_to_speech_voice_input.clear()
	for iter:String in voices:
		text_to_speech_voice_input.add_item(iter)

func set_touch_gesture(toggled_on:bool) -> void:
	Input.emulate_mouse_from_touch = !toggled_on
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
	Loading.change_scene("res://scene/startup.tscn")
	close()

func on_command_received(cmd:String) -> void:
	# /[设置选项] [值]
	if regex_list.search(cmd):
		Terminal.print("\n".join(table.keys()))
		return
	if regex_clean_archive.search(cmd):
		set_clean_archive()
		return
	if regex_reset_progress.search(cmd):
		set_reset_progress()
		return
	var regex_set_value_result:RegExMatch = regex_set_value.search(cmd)
	if !regex_set_value_result:
		return
	var key:String = regex_set_value_result.get_string("key")
	var value:String = regex_set_value_result.get_string("value")
	if !table.has(key) || !value.is_valid_float():
		return
	if has_method("set_" + key):
		call("set_" + key, value.to_float())
