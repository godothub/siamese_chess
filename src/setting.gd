extends CanvasLayer

var resolutions:Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1024, 600),
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

@onready var resolution_input:OptionButton = $texture_rect/h_box_container/v_box_container_left/margin_container_resolution/h_box_container/option_button
@onready var fullscreen_input:CheckBox = $texture_rect/h_box_container/v_box_container_left/margin_container_fullscreen/h_box_container/check_box
@onready var master_volume_input:HSlider = $texture_rect/h_box_container/v_box_container_left/margin_container_master_volume/v_box_container/h_slider
@onready var sfx_volume_input:HSlider = $texture_rect/h_box_container/v_box_container_left/margin_container_sfx_volume/v_box_container/h_slider
@onready var env_volume_input:HSlider = $texture_rect/h_box_container/v_box_container_left/margin_container_env_volume/v_box_container/h_slider
@onready var language_input:OptionButton = $texture_rect/h_box_container/v_box_container_right/margin_container_language/h_box_container/option_button
@onready var relax_input:CheckBox = $texture_rect/h_box_container/v_box_container_right/margin_container_relax/v_box_container/h_box_container/check_box
@onready var clean_archive_input:Button = $texture_rect/h_box_container/v_box_container_right/margin_container_clean_archive/h_box_container/button

func _ready() -> void:
	for iter:Vector2i in resolutions:
		resolution_input.add_item("%d * %d" % [iter.x, iter.y])
	resolution_input.connect("item_selected", resolution_emitted)
	fullscreen_input.connect("toggled", fullscreen_emitted)
	master_volume_input.connect("value_changed", master_volume_emitted)
	sfx_volume_input.connect("value_changed", sfx_volume_emitted)
	env_volume_input.connect("value_changed", env_volume_emitted)
	language_input.connect("item_selected", language_emitted)
	relax_input.connect("toggled", relax_emitted)
	clean_archive_input.connect("pressed", clean_archive_emitted)

func resolution_emitted(index:int) -> void:
	pass
func fullscreen_emitted(toggled_on:bool) -> void:
	pass
func master_volume_emitted(value:float) -> void:
	pass
func sfx_volume_emitted(value:float) -> void:
	pass
func env_volume_emitted(value:float) -> void:
	pass
func language_emitted(index:int) -> void:
	pass
func relax_emitted(toggled_on:bool) -> void:
	pass
func clean_archive_emitted() -> void:
	pass
