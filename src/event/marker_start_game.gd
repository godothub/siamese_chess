extends MarkerEvent
class_name MarkerStartGame

@export var group:int = 1
@export var game_event:MarkerEvent = null

func show_selection() -> String:
	if level.chessboard.state.get_bit(level.player_king) & Chess.mask(Chess.x88_to_c64(level.chessboard.vector3_to_x88(global_position))):
		if group == 0:
			return "SELECTION_PLAY_AS_WHITE"
		else:
			return "SELECTION_PLAY_AS_BLACK"
	return ""

func on_selection() -> void:
	game_event.start()
