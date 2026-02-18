extends CanvasLayer

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
@onready var relax_input:CheckBox = $texture_rect/tab_container/game/v_box_container/margin_container_relax/v_box_container/h_box_container/check_box
@onready var clean_archive_input:Button = $texture_rect/tab_container/files/v_box_container/margin_container_clean_archive/h_box_container/button
@onready var reset_progress_input:Button = $texture_rect/tab_container/files/v_box_container/margin_container_reset_progress/v_box_container/h_box_container/button

func _ready() -> void:
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
	relax_input.connect("toggled", set_relax)
	clean_archive_input.connect("button_down", set_clean_archive)
	reset_progress_input.connect("button_down", set_reset_progress)
	$texture_rect/button_close.connect("button_down", close)

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
	set_language(table.get_or_add("language"))
	relax_input.set_pressed(table.get_or_add("relax", false))
	camera_move_speed_input.set_value(table.get_or_add("camera_move_speed", 50))
	camera_move_speed_value.text = "%d%%" % (table.get_or_add("camera_move_speed", 50))
	camera_rotate_sensitive_input.set_value(table.get_or_add("camera_rotate_sensitive", 50))
	camera_rotate_sensitive_value.text = "%d%%" % (table.get_or_add("camera_rotate_sensitive", 50))
	camera_rotate_axis_input.select(table.get_or_add("camera_rotate_axis", 0))
	visible = false

func open() -> void:
	visible = true
	$texture_rect/tab_container.get_tab_bar().grab_focus()

func close() -> void:
	save_file()
	visible = false

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

func set_relax(toggled_on:bool) -> void:
	table.set("relax", toggled_on)

func set_clean_archive() -> void:
	if DirAccess.dir_exists_absolute("user://archive"):
		DirAccess.remove_absolute("user://archive")

func set_reset_progress() -> void:
	if FileAccess.file_exists("user://progress/prototype_2.json"):
		DirAccess.remove_absolute("user://progress/prototype_2.json")
	Loading.change_scene("res://scene/startup.tscn", {})
	close()
