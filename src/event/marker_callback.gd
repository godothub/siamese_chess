extends MarkerEvent
class_name MarkerCallback

@export var node:Node = null
@export var method_name:StringName = ""
@export var arg:Array = []
@export var selection:String = ""
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func show_selection() -> String:
	if level.chessboard.state.get_bit(level.player_king) & bit:
		return selection
	return ""

func on_selection() -> void:
	await node.callv(method_name, arg)
