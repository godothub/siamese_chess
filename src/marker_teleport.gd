extends MarkerSelection
class_name MarkerTeleport

@export var to:String = ""
@export var args:Dictionary = {}

func _init() -> void:
	selection = "SELECTION_GOTO"

func event() -> void:
	if level.chessboard.state.get_bit(level.player_king) & bit:
		Loading.change_scene(to, args)
