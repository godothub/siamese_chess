extends Node2D
class_name Document
# 文档分为模板和实例
# 实例包含了文件名称和变量

var filename:String = ""	# 文档名称，唯一
var template:String = ""	# 模板路径

func _ready() -> void:
	pass

func parse(_data:Dictionary) -> void:
	pass

func dict() -> Dictionary:
	return {}

func save_file() -> void:
	var data:String = JSON.stringify(dict())
	var path:String = "user://archive/" + filename
	DirAccess.make_dir_absolute("user://archive/")
	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(data)
	file.close()

func load_file() -> void:
	if FileAccess.file_exists("user://archive/" + filename):
		var data:String = FileAccess.get_file_as_string("user://archive/" + filename)
		parse(JSON.parse_string(data))

func clear_file() -> void:
	DirAccess.remove_absolute("user://archive/" + filename)

func set_filename(_filename:String) -> void:
	filename = _filename

func get_filename() -> String:
	return filename

func get_rect() -> Rect2:
	return Rect2(-552 / 2, -780 / 2, 552, 780)

func click(_click_position:Vector2) -> void:
	pass

func start_dragging(_start_position:Vector2) -> void:
	pass

func dragging(_drawing_position:Vector2) -> void:
	pass

func end_dragging() -> void:
	pass

func cancel_dragging() -> void:
	pass

func erase(_drawing_position:Vector2) -> void:
	pass

func new_page() -> void:
	pass

func turn_page(_page:int) -> void:
	pass

func page_count() -> int:
	return 0

func page_index() -> int:
	return 0
