extends MarkerEvent
class_name MarkerEnterRoom

@export var hint:String = ""
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit_from:int = 0
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit_to:int = 0
@export var camera:Camera3D = null

func show_selection() -> String:
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by", 0))) & bit_from:
		return hint
	return ""

func on_selection() -> void:
	if Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by", 0))) & bit_from:
		Progress.set_value("player_by", Chess.c64_to_x88(Chess.first_bit(bit_to)))
		Player.move_camera(camera)
