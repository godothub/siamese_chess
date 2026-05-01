extends MarkerEvent
class_name MarkerTitle

@export var text:String = ""

func on_init() -> void:
	var by:int = level.chessboard.vector3_to_x88(position)
	level.title[by] = text
