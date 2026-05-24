extends CanvasLayer

@onready var chessboard:Chessboard = $texture_rect/sub_viewport_container/sub_viewport/chessboard
@onready var camera:Camera3D = $texture_rect/sub_viewport_container/sub_viewport/camera
@onready var button_close:Button = $texture_rect_top/margin_container_close/button_close
var tween:Tween
var target_camera:Camera3D = null
var last_audio_stream:AudioStream = null
var audio_stream:AudioStream = load("res://assets/audio/546047__grcekh__analog-crt-tv-electronic-static-noise.wav")

func _ready() -> void:
	button_close.connect("pressed", close)
	button_close.connect("mouse_entered", read_close)
	button_close.connect("focus_entered", read_close)
	visible = false

func _physics_process(_delta:float) -> void:
	if target_camera:
		camera.global_transform = target_camera.global_transform

func set_state(_state:State) -> void:
	chessboard.state = _state

func read_close() -> void:
	$audio_stream_player_select.play()
	if Setting.get_value("text_to_speech"):
		Narrative.speak(tr("ICON_CLOSE"), true)

func open() -> void:
	last_audio_stream = Ambient.get_current_audio_stream()
	Ambient.change_environment_sound(audio_stream)
	set_physics_process(true)
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()
	visible = true
	if tween:
		tween.kill()
	tween = create_tween()
	$texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tween.tween_property($texture_rect, "modulate", Color(1, 1, 1, 1), 0.1)
	#if Setting.get_value("text_to_speech"):
	#	Narrative.speak("", true)

func close() -> void:
	Ambient.change_environment_sound(last_audio_stream)
	$audio_stream_player_confirm.play()
	set_physics_process(false)
	visible = false
