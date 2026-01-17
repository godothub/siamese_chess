extends MarkerSelection
class_name MarkerDocument

@export var file_path:String = "usr://archive/"
@export var file_content:Dictionary = {"lines": []}
@export var comment:String = ""

func event() -> void:
	if !FileAccess.file_exists(file_path):
		var dir:DirAccess = DirAccess.open("user://archive/")
		if !dir:
			DirAccess.make_dir_absolute("user://archive/")
			dir = DirAccess.open("user://archive/")
		var path:String = file_path
		var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(file_content))
		file.close()
	Archive.open()
	Archive.open_document(file_path)
	level.change_state("explore_idle")
