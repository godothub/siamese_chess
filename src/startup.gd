extends Control

func _ready() -> void:
	Progress.load_file()
	var current_level:String = Progress.get_value("current_level", "res://scene/level/train_carriage.tscn")
	Loading.change_state(current_level)
