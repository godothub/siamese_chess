extends RefCounted
class_name Document
# 文档分为模板和实例
# 实例包含了文件名称和变量
signal content_changed()

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

func page_count() -> int:
	return 0
