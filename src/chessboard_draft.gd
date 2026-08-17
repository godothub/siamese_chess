extends InspectableItem

var region:Rect2 = Rect2(0, 0, 384, 512)
var color:Color = Color(0.5, 0.5, 0.5, 1)
var lines:Array[Line2D] = []	# 直接暴力搜解决问题
var drawing_line:Line2D = null
var uv_mapping:UVMapping = null
var last_event_position_2d:Vector2 = Vector2(-1, -1)
var use_eraser:bool = false

func _ready() -> void:
	var array_mesh:ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, $mesh_instance.mesh.get_mesh_arrays())
	$mesh_instance.mesh = array_mesh
	uv_mapping = UVMapping.new()
	uv_mapping.set_mesh($mesh_instance.mesh)
	super._ready()

func input(_from:Node3D, _to:Area3D, _event:InputEvent, _event_position:Vector3, _normal:Vector3) -> void:
	var event_position_3d:Vector3 = $mesh_instance.global_transform.affine_inverse() * _event_position
	var event_normal_3d:Vector3 = $mesh_instance.global_transform.orthonormalized().basis.inverse() * _normal
	var event_position_2d:Vector2 = Vector2()
	event_position_2d = uv_mapping.get_uv_coords(event_position_3d, event_normal_3d)
	if event_position_2d == Vector2(-1, -1):
		if last_event_position_2d != Vector2(-1, -1):
			event_position_2d = last_event_position_2d
	else:
		event_position_2d.x *= region.size.x
		event_position_2d.y *= region.size.y
	last_event_position_2d = event_position_2d
	if _event is InputEventMouseButton:
		if !use_eraser:
			if _event.pressed && _event.button_index == MOUSE_BUTTON_LEFT:
				start_drawing(event_position_2d)
			else:
				end_drawing()
	elif _event is InputEventMouseMotion:
		if _event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if use_eraser || _event.pen_inverted:
				cancel_drawing()
				erase_line(event_position_2d)
			else:
				drawing_curve(event_position_2d)
		elif _event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			cancel_drawing()
			erase_line(event_position_2d)

func start_drawing(start_position:Vector2) -> void:
	var new_line:Line2D = Line2D.new()
	new_line.joint_mode = Line2D.LINE_JOINT_ROUND
	new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	new_line.default_color = color
	new_line.width = 5
	new_line.add_point(start_position)
	drawing_line = new_line
	$sub_viewport.add_child(new_line)
	lines.push_back(new_line)

func drawing_curve(drawing_position:Vector2) -> void:
	if !is_instance_valid(drawing_line):
#		start_draw(finger_index, drawing_position)
		return
	if drawing_line.get_point_count() > 0 && drawing_line.get_point_position(drawing_line.get_point_count() - 1).distance_squared_to(drawing_position) < 3 * 3:
		return
	drawing_line.add_point(drawing_position)

func drawing_straight(drawing_position) -> void:
	if !is_instance_valid(drawing_line):
		return
	#if drawing_line.get_point_count() > 0 && drawing_line.get_point_position(drawing_line.get_point_count() - 1).distance_squared_to(drawing_position) < 3 * 3:
	#	return
	# 有可能会做折现，不做清理
	if drawing_line.get_point_count() < 2:
		drawing_line.add_point(drawing_position)
	drawing_line.set_point_position(drawing_line.get_point_count() - 1, drawing_position)

func end_drawing() -> void:
	if !is_instance_valid(drawing_line):
		return
	drawing_line = null

func cancel_drawing() -> void:
	if is_instance_valid(drawing_line):
		if lines.has(drawing_line):
			lines.erase(drawing_line)
		drawing_line.queue_free()

func erase_line(drawing_position:Vector2) -> void:
	cancel_drawing()
	var point_list:Array = $sub_viewport.get_children()
	for iter:Line2D in point_list:
		if iter.get_point_count() < 2:
			iter.queue_free()
		for i:int in iter.get_point_count():
			if iter.get_point_position(i).distance_squared_to(drawing_position) < 10 * 10:
				iter.queue_free()
				break

func clear_lines() -> void:
	for iter:Line2D in lines:
		iter.queue_free()
	lines.clear()
