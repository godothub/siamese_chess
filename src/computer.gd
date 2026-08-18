extends InspectableItem

var region:Vector2 = Vector2(0, 0)
var scene_instance:Node = null
var uv_mapping = UVMapping.new()
var last_event_position_2d:Vector2 = Vector2(-1, -1)

func _ready() -> void:
	super._ready()
	region = $sub_viewport.size
	uv_mapping.set_mesh($console_touch.mesh)
	set_process_unhandled_input(false)
	clear()

func print(text:String) -> void:
	$sub_viewport/color_rect_black/margin_container/rich_text_label.add_text(text)

func clear() -> void:
	$sub_viewport/color_rect_black/margin_container/rich_text_label.clear()

func run_scene(path:String) -> void:
	var instance:Node = load(path).instantiate()
	scene_instance = instance
	$sub_viewport.add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	$sub_viewport/color_rect_black.hide()
	set_process_unhandled_input(true)

func close_scene() -> void:
	scene_instance.queue_free()
	scene_instance = null
	$sub_viewport/color_rect_black.show()
	set_process_unhandled_input(false)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey:
		$sub_viewport.push_input(event)

func area_input(_from:Node3D, _to:Area3D, _instant:bool, _pressed:bool, _event_position:Vector3, _normal:Vector3) -> void:
	var event_position_3d:Vector3 = $console_touch.global_transform.affine_inverse() * _event_position
	var event_normal_3d:Vector3 = $console_touch.global_transform.orthonormalized().basis.inverse() * _normal
	var event_position_2d:Vector2 = Vector2()
	event_position_2d = uv_mapping.get_uv_coords(event_position_3d, event_normal_3d)
	if event_position_2d == Vector2(-1, -1):
		if last_event_position_2d != Vector2(-1, -1):
			event_position_2d = last_event_position_2d
	else:
		event_position_2d.x *= region.x
		event_position_2d.y *= region.y
	last_event_position_2d = event_position_2d
	
	if _pressed:
		if _instant:
			var event:InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			event.pressed = true
			event.position = event_position_2d
			event.device = -1
			$sub_viewport.push_input(event, true)
		else:
			var event:InputEventMouseMotion = InputEventMouseMotion.new()
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			event.position = event_position_2d
			event.device = -1
			$sub_viewport.push_input(event, true)
	else:
		if _instant:
			var event:InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			event.pressed = false
			event.position = event_position_2d
			event.device = -1
			$sub_viewport.push_input(event, true)
