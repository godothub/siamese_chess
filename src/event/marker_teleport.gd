extends MarkerEvent
class_name MarkerTeleport

@export var to:String = ""
@export var args:Dictionary = {}
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func show_selection() -> String:
	if level.chessboard.state.get_bit(level.player_king) & bit:
		return "SELECTION_GOTO"
	return ""

func on_selection() -> void:
	if level.chessboard.state.get_bit(level.player_king) & bit:
		await Loading.change_scene(to, args)
