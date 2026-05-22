extends CanvasLayer

@onready var button_close:Button = $texture_rect/h_box_container/v_box_container/margin_container_close/button_close
@onready var zoom_plus:Button = $texture_rect/h_box_container/v_box_container_2/margin_container_plus/button_plus
@onready var slider:VSlider = $texture_rect/h_box_container/v_box_container_2/margin_container_slider/v_slider
@onready var zoom_minus:Button = $texture_rect/h_box_container/v_box_container_2/margin_container_minus/button_minus
@onready var button_shot:Button = $texture_rect/h_box_container/v_box_container_2/margin_container_shot/button_shot
@onready var head:Node3D = $texture_rect/h_box_container/margin_container/sub_viewport_container/sub_viewport/head
@onready var camera:Camera3D = $texture_rect/h_box_container/margin_container/sub_viewport_container/sub_viewport/head/camera_3d
@onready var sub_viewport_container:SubViewportContainer = $texture_rect/h_box_container/margin_container/sub_viewport_container
@onready var sub_viewport:SubViewport = $texture_rect/h_box_container/margin_container/sub_viewport_container/sub_viewport

@onready var photo_document:Document = load("res://src/doc/photo_paper.gd").new()

var zoom:float = 0

func _ready() -> void:
	visible = false
	button_close.connect("pressed", close)
	button_shot.connect("pressed", capture)
	sub_viewport_container.connect("gui_input", sub_viewport_container_gui_input)
	slider.connect("value_changed", zoom_camera)
	set_physics_process(false)

func _physics_process(_delta:float) -> void:
	var vision_look_at:Vector2 = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	head.global_rotation.y -= vision_look_at.x / 1000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].x
	var yaw:float = head.global_rotation.x - vision_look_at.y / 2000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].y
	yaw = clamp(yaw, -PI / 2, PI * 2 / 6)
	head.global_rotation.x = yaw
	if zoom_plus.button_pressed || Input.is_action_pressed("tab_right"):
		zoom_camera(slider.value + _delta * Setting.get_value("camera_move_speed"))
	if zoom_minus.button_pressed || Input.is_action_pressed("tab_left"):
		zoom_camera(slider.value - _delta * Setting.get_value("camera_move_speed"))
	if Input.is_action_just_pressed("ui_cancel"):
		close()
	if Input.is_action_just_pressed("ui_accept"):
		capture()

func sub_viewport_container_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		if !(event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		head.global_rotation.y -= event.relative.x / 20000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].x
		var yaw:float = head.global_rotation.x + event.relative.y / 10000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].y
		yaw = clamp(yaw, -PI / 2, PI * 2 / 6)
		head.global_rotation.x = yaw
	elif event is InputEventScreenPinch:
		zoom_camera(slider.value + event.relative / 1000 * Setting.get_value("camera_move_speed"))

func open() -> void:
	$audio_stream_player_open.play()
	photo_document.set_filename("photo.camera.json")
	photo_document.load_file()
	zoom_camera(0)
	set_physics_process(true)
	visible = true

func close() -> void:
	$audio_stream_player_close.play()
	set_physics_process(false)
	visible = false

func move_camera(_position:Vector3, _rotation:Vector3) -> void:
	head.global_position = _position
	head.global_rotation = _rotation

func zoom_camera(_value:float) -> void:
	slider.set_value_no_signal(_value)
	if floor(zoom / 10) != floor(_value / 10):
		$audio_stream_player_zooming.play(0)
	zoom = _value
	_value = 100 - _value
	_value = _value * 0.8 + 30
	_value = clamp(_value, 30, 110)
	camera.fov = _value

func capture() -> void:
	$audio_stream_player_shutter.play()
	var tween:Tween = create_tween()
	tween.tween_property(sub_viewport_container, "visible", false, 0)
	tween.tween_interval(0.1)
	tween.tween_property(sub_viewport_container, "visible", true, 0)
	tween.tween_callback(save_photo)

func save_photo() -> void:
	var texture:ViewportTexture = sub_viewport.get_texture()
	var image:Image = texture.get_image()
	photo_document.new_page()
	photo_document.set_image(-1, image)
	photo_document.save_file()
