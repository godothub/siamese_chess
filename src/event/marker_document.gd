extends MarkerEvent
class_name MarkerDocument

@export var file_path:String = "usr://archive/"
@export var file_content:Dictionary = {"lines": []}
@export var comment:String = ""
@export var bit:int = 0
@export var selection:String = ""

func show_selection() -> String:
	if level.chessboard.state.get_bit(level.player_king) & bit:
		return selection
	return ""

func on_selection() -> void:
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
	level.show_selection()
