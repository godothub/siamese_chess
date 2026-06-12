extends MarkerEvent
class_name MarkerTeleport

@export var to:String = ""
@export var by:int = 0
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func show_selection() -> String:
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by"))) & bit:
		return "SELECTION_GOTO"
	return ""

func on_selection() -> void:
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by"))) & bit:
		Progress.set_value("player_by", by)
		await Loading.change_scene(to)
