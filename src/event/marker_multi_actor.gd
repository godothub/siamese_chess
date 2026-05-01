extends MarkerEvent
class_name MarkerMultiActor

@export var piece:int = 0
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func on_init() -> void:
	var current_bit = bit
	while current_bit:
		var by:int = Chess.c64_to_x88(Chess.first_bit(current_bit))
		level.chessboard.state.add_piece(by, piece)
		current_bit = Chess.next_bit(current_bit)
