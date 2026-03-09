extends CanvasLayer

@onready var chessboard:Chessboard = $texture_rect/sub_viewport_container/sub_viewport/chessboard
@onready var camera:Camera3D = $texture_rect/sub_viewport_container/sub_viewport/camera
@onready var button_close:Button = $texture_rect/margin_container_close/button_close
var tween:Tween
var target_camera:Camera3D = null

func _ready() -> void:
	button_close.connect("pressed", close)
	visible = false

func _physics_process(_delta:float) -> void:
	if target_camera:
		camera.global_transform = target_camera.global_transform

func set_state(_state:State) -> void:
	chessboard.state = _state
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()

func set_pov(_camera:Camera3D) -> void:
	target_camera = _camera
	camera.global_transform = _camera.global_transform
	camera.fov = _camera.fov

func open() -> void:
	set_physics_process(true)
	visible = true
	if tween:
		tween.kill()
	tween = create_tween()
	$texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tween.tween_property($texture_rect, "modulate", Color(1, 1, 1, 1), 0.1)

func close() -> void:
	set_physics_process(false)
	visible = false
