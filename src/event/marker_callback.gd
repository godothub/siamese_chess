extends MarkerEvent
class_name MarkerCallback

@export var node:Node = null
@export var method_name:StringName = ""
@export var arg:Array = []
@export var selection:String = ""
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func show_selection() -> String:
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by"))) & bit:
		return selection
	return ""

func on_selection() -> void:
	node.callv.call_deferred(method_name, arg)
