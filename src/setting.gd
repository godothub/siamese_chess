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

@onready var resolution_input:OptionButton = $texture_rect/h_box_container/v_box_container_left/margin_container_resolution/h_box_container/option_button
@onready var fullscreen_input:CheckBox = $texture_rect/h_box_container/v_box_container_left/margin_container_fullscreen/h_box_container/check_box
@onready var master_volume_input:HSlider = $texture_rect/h_box_container/v_box_container_left/margin_container_master_volume/v_box_container/h_slider
@onready var master_volume_value:Label = $texture_rect/h_box_container/v_box_container_left/margin_container_master_volume/v_box_container/h_box_container/label_value
@onready var sfx_volume_input:HSlider = $texture_rect/h_box_container/v_box_container_left/margin_container_sfx_volume/v_box_container/h_slider
@onready var sfx_volume_value:Label = $texture_rect/h_box_container/v_box_container_left/margin_container_sfx_volume/v_box_container/h_box_container/label_value
@onready var env_volume_input:HSlider = $texture_rect/h_box_container/v_box_container_left/margin_container_env_volume/v_box_container/h_slider
@onready var env_volume_value:Label = $texture_rect/h_box_container/v_box_container_left/margin_container_env_volume/v_box_container/h_box_container/label_value
@onready var language_input:OptionButton = $texture_rect/h_box_container/v_box_container_right/margin_container_language/h_box_container/option_button
@onready var relax_input:CheckBox = $texture_rect/h_box_container/v_box_container_right/margin_container_relax/v_box_container/h_box_container/check_box
@onready var clean_archive_input:Button = $texture_rect/h_box_container/v_box_container_right/margin_container_clean_archive/h_box_container/button
@onready var reset_progress_input:Button = $texture_rect/h_box_container/v_box_container_right/margin_container_reset_progress/h_box_container/button

func _ready() -> void:
	for iter:Vector2i in resolutions:
		resolution_input.add_item("%d * %d" % [iter.x, iter.y])
	for key:String in languages:
		language_input.add_item(languages[key])
	
	resolution_input.select(2)
	fullscreen_input.set_pressed_no_signal(false)
	master_volume_input.set_value_no_signal(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Master")) * 100)
	master_volume_value.text = "%d%%" % (AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Master")) * 100)
	sfx_volume_input.set_value_no_signal(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"SFX")) * 100)
	sfx_volume_value.text = "%d%%" % (AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"SFX")) * 100)
	env_volume_input.set_value_no_signal(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Ambient")) * 100)
	env_volume_value.text = "%d%%" % (AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Ambient")) * 100)
	language_input.select(languages.keys().find(TranslationServer.get_locale()))
	relax_input.set_pressed_no_signal(false)
	
	resolution_input.connect("item_selected", set_resolution)
	fullscreen_input.connect("toggled", set_fullscreen)
	master_volume_input.connect("value_changed", set_master_volume)
	sfx_volume_input.connect("value_changed", set_sfx_volume)
	env_volume_input.connect("value_changed", set_env_volume)
	language_input.connect("item_selected", set_language)
	relax_input.connect("toggled", set_relax)
	clean_archive_input.connect("button_down", set_clean_archive)
	reset_progress_input.connect("button_down", set_reset_progress)
	$texture_rect/button_close.connect("button_down", close)
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func set_resolution(index:int) -> void:
	get_viewport().size = resolutions[index]

func set_fullscreen(toggled_on:bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_master_volume(value:float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Master"), value / 100.0)
	master_volume_value.text = "%d%%" % value

func set_sfx_volume(value:float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"SFX"), value / 100.0)
	sfx_volume_value.text = "%d%%" % value

func set_env_volume(value:float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Ambient"), value / 100.0)
	env_volume_value.text = "%d%%" % value

func set_language(index:int) -> void:
	TranslationServer.set_locale(languages.keys()[index])

func set_relax(toggled_on:bool) -> void:
	Progress.set_value("relax", toggled_on)

func set_clean_archive() -> void:
	if DirAccess.dir_exists_absolute("user://archive"):
		DirAccess.remove_absolute("user://archive")

func set_reset_progress() -> void:
	if FileAccess.file_exists("user://progress/prototype_2.json"):
		DirAccess.remove_absolute("user://progress/prototype_2.json")
	Loading.change_scene("res://scene/startup.tscn", {})
	close()
