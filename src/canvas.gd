extends Node3D

@onready var resolution:float = 512

var pointer:Dictionary[String, Array] = {}

class ChessboardPointer extends Node2D:
	var resolution:float = 512
	var color:Color = Color(0, 0, 0, 1)
	func _draw() -> void:
		#draw_rect(Rect2(-resolution / 16, -resolution / 16, resolution / 8, resolution / 8), color.lightened(0.1))
		draw_rect(Rect2(-resolution / 16, -resolution / 16, resolution / 8, resolution / 8), color, false, 10)

func _ready() -> void:
	$sub_viewport.size = Vector2(resolution, resolution)

func draw_pointer(type:String, color:Color, drawing_position:Vector2, priority:int = 0) -> void:
	if !pointer.has(type):
		pointer[type] = []
	var new_point:ChessboardPointer = ChessboardPointer.new()
	new_point.position = drawing_position
	new_point.color = color
	new_point.resolution = resolution
	new_point.z_index = priority
	$sub_viewport.add_child(new_point)
	pointer[type].push_back(new_point)

func clear_pointer(type:String) -> void:
	if !pointer.has(type):
		return
	for iter:Node2D in pointer[type]:
		iter.queue_free()
	pointer.erase(type)

func convert_name_to_position(_name:String) -> Vector2:
	var ascii:PackedByteArray = _name.to_ascii_buffer()
	var converted:Vector2 = Vector2(ascii[0] - 97, 7 - (ascii[1] - 49))
	return converted * resolution / 8 + Vector2(resolution / 16, resolution / 16)
