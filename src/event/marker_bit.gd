@tool
extends MarkerEvent
class_name MarkerBit

@export var piece:int = 0
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func on_init() -> void:
	level.chessboard.state.set_bit(piece, level.chessboard.state.get_bit(piece) | bit)
