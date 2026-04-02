extends Node3D

@onready var resolution:float = 512

var pointer:Dictionary[String, Array] = {}

class ChessboardPointer extends Node2D:
	var resolution:float = 512
	var color:Color = Color(0, 0, 0, 1)
	func _draw() -> void:
		var transparent:Color = color
		transparent.a = 0.5
		draw_rect(Rect2(-resolution / 16, -resolution / 16, resolution / 8, resolution / 8), transparent)
		draw_rect(Rect2(-resolution / 16, -resolution / 16, resolution / 8, resolution / 8), color, false, 10)

class ChessboardGrid extends Node2D:
	var resolution:float = 512
	var color:Color = Color(0.46, 0.46, 0.46, 0.722)
	func _draw() -> void:
		for i:int in 8:
			for j:int in 8:
				var pos:Vector2 = Vector2(i, j) * resolution / 8
				draw_rect(Rect2(pos.x, pos.y, resolution / 8, resolution / 8), color, false, 1)

func _ready() -> void:
	$sub_viewport.size = Vector2(resolution, resolution)
	var grid:ChessboardGrid = ChessboardGrid.new()
	grid.resolution = resolution
	grid.z_index = -1
	$sub_viewport.add_child(grid)

func draw_pointer(type:String, color:Color, by:int, priority:int = 0) -> void:
	if !pointer.has(type):
		pointer[type] = []
	var new_point:ChessboardPointer = ChessboardPointer.new()
	new_point.position = x88_to_vector2(by)
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

func name_to_vector2(_name:String) -> Vector2:
	var ascii:PackedByteArray = _name.to_ascii_buffer()
	var converted:Vector2 = Vector2(ascii[0] - 97, 7 - (ascii[1] - 49))
	return converted * resolution / 8 + Vector2(resolution / 16, resolution / 16)

func x88_to_vector2(by:int) -> Vector2:
	return Vector2(by % 16, by / 16) * resolution / 8 + Vector2(resolution / 16, resolution / 16)
