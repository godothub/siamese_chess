extends Control
class_name DocumentBrowser

var document:Document = null
var zoom:float = 1
var offset:Vector2 = Vector2()
var current_tool:int = 0

# 线性变化显然不能够很舒服地进行缩放
# 曲线函数：(x / 2) ^ 2 * 0.95 + 0.1
# 反函数： sqrt((y - 0.1) / 0.95) * 2
var zoom_mapped:float = 1
var zoom_local:float = 1
var page:int = 0

func _ready() -> void:
	$margin_container_zoom/h_box_container/button_zoom_out.connect("pressed", change_zoom.bind(-0.1))
	$margin_container_zoom/h_box_container/button_zoom_in.connect("pressed", change_zoom.bind(+0.1))
	$margin_container_tool/h_box_container/button_edit.connect("pressed", set_current_tool.bind(0))
	$margin_container_tool/h_box_container/button_draw.connect("pressed", set_current_tool.bind(1))
	$margin_container_tool/h_box_container/button_eraser.connect("pressed", set_current_tool.bind(2))
	$margin_container_page/h_box_container/button_prev.connect("pressed", change_page.bind(-1))
	$margin_container_page/h_box_container/button_next.connect("pressed", change_page.bind(+1))
	set_process_input(false)

func _input(event:InputEvent) -> void:
	if !document || !visible:
		return
	if event is InputEventMultiScreenDrag && get_global_rect().has_point(event.position):
		change_offset(event.relative)
	if event is InputEventScreenPinch && event.position && get_global_rect().has_point(event.position):
		change_zoom(event.relative / 1000)
	var actual_position:Vector2
	if event is InputEventMouseButton || event is InputEventMouseMotion || event is InputEventSingleScreenTouch || event is InputEventSingleScreenDrag || event is InputEventMultiScreenDrag || event is InputEventScreenPinch:
		actual_position = event.position - $sub_viewport_container.global_position - document.get_global_position()
		actual_position /= zoom_mapped
	if event is InputEventMouseButton:
		if current_tool != 2:
			if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
				document.start_dragging(actual_position)
			else:
				document.end_dragging()
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if current_tool == 2 || event.pen_inverted:
				document.cancel_dragging()
				document.erase(actual_position)
			elif current_tool == 0:
				change_offset(event.relative)
			else:
				document.dragging(actual_position)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			document.cancel_dragging()
			document.erase(actual_position)

func open() -> void:
	visible = true
	set_process_input(true)

func close() -> void:
	visible = false
	set_process_input(false)

func set_document(_document) -> void:
	if is_instance_valid(document):
		$sub_viewport_container/sub_viewport.remove_child(document)
	document = _document
	var rect:Rect2 = document.get_rect()
	zoom_mapped = min($sub_viewport_container/sub_viewport.size.x / rect.size.x, $sub_viewport_container/sub_viewport.size.y / rect.size.y)
	zoom = sqrt((zoom_mapped - 0.1) / 0.95) * 2
	zoom_local = 1
	offset = $sub_viewport_container/sub_viewport.size / 2
	$margin_container_zoom/h_box_container/label.text = "%d%%" % (zoom_local * 100)
	$sub_viewport_container/sub_viewport.add_child(document)
	update_transform()

func update_transform() -> void:
	if !is_instance_valid(document):
		return
	var pivot:Vector2 = get_global_transform().basis_xform_inv($sub_viewport_container/sub_viewport.size * 0.5)
	var offset_result:Vector2 = offset - pivot
	offset_result *= zoom_mapped / document.scale.x
	offset = offset_result + pivot
	document.scale = Vector2(zoom_mapped, zoom_mapped)
	document.position = offset

func change_zoom(relative:float) -> void:
	var last_zoom_local:float = zoom_local
	zoom_local += relative
	zoom_local = clamp(zoom_local, 0.1, 2.0)
	zoom += zoom_local - last_zoom_local
	zoom_mapped = pow(zoom / 2, 2) * 0.95 + 0.1
	$margin_container_zoom/h_box_container/label.text = "%d%%" % (zoom_local * 100)
	update_transform()

func change_offset(relative:Vector2) -> void:
	offset += relative / 2
	update_transform()

func set_current_tool(_current_tool:int) -> void:
	current_tool = _current_tool

func change_page(dir:int) -> void:
	page += dir
	page = clamp(page, 0, document.page_count())
