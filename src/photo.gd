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

func _ready() -> void:
	button_close.connect("pressed", close)
	button_shot.connect("pressed", save_photo)
	sub_viewport_container.connect("gui_input", sub_viewport_container_gui_input)
	slider.connect("value_changed", zoom_camera)

func _physics_process(_delta:float) -> void:
	var vision_look_at:Vector2 = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	head.global_rotation.y -= vision_look_at.x / 1000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].x
	var yaw:float = head.global_rotation.x - vision_look_at.y / 2000 * Setting.get_value("camera_rotate_sensitive") * Setting.axis[Setting.get_value("camera_rotate_axis")].y
	yaw = clamp(yaw, -PI / 2, PI * 2 / 6)
	head.global_rotation.x = yaw
	if zoom_plus.button_pressed:
		zoom_camera(slider.value - _delta * Setting.get_value("camera_move_speed"))
	if zoom_minus.button_pressed:
		zoom_camera(slider.value + _delta * Setting.get_value("camera_move_speed"))

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
	zoom_camera(0)
	set_physics_process(true)
	visible = true

func close() -> void:
	set_physics_process(false)
	visible = false

func move_camera(_position:Vector3, _rotation:Vector3) -> void:
	head.global_position = _position
	head.global_rotation = _rotation

func zoom_camera(_value:float) -> void:
	slider.set_value_no_signal(_value)
	_value = 100 - _value
	_value = _value * 0.8 + 30
	_value = clamp(_value, 30, 110)
	camera.fov = _value

func save_photo() -> void:
	DirAccess.make_dir_absolute("user://photo/")
	DirAccess.make_dir_absolute("user://archive/")
	var texture:ViewportTexture = sub_viewport.get_texture()
	var image:Image = texture.get_image()
	var timestamp:String = String.num_int64(Time.get_unix_time_from_system())
	image.save_png("user://photo/" + timestamp + ".png")
	var file:FileAccess = FileAccess.open("user://archive/photo." + timestamp + ".json", FileAccess.WRITE)
	var dict:Dictionary = {
		"lines": [],
		"path": "user://photo/" + timestamp + ".png"
	}
	file.store_string(JSON.stringify(dict))
	file.close()
