extends LevelEvent
class_name EventTeleport

@export var disabled:bool = false
@export var to:String = ""
@export var by:int = 0
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func show_selection() -> String:
	if disabled:
		return ""
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by", 0))) & bit:
		return "SELECTION_GOTO"
	return ""

func on_selection() -> void:
	if disabled:
		return
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by", 0))) & bit:
		Progress.set_value("player_by", by, true)
		await Loading.change_scene(to)
