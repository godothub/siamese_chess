extends Control

func _ready() -> void:
	Progress.load_file()
	var current_level:String = Progress.get_value("current_level", "res://scene/level/entrance.tscn")
	if current_level == "res://scene/startup.tscn":
		current_level = "res://scene/level/entrance.tscn"
	Loading.change_scene(current_level)
