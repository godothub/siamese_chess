extends LevelEvent
class_name EventEntrance

func on_init() -> void:
	pass
	# var cheshire_by:int = Progress.get_value("player_by", level.chessboard.vector3_to_x88(position))
	# var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	# cheshire_instance.position = level.chessboard.x88_to_vector3(cheshire_by)
	# level.chessboard.state.add_piece(cheshire_by, level.player_king)
	# level.chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	# level.chessboard.button_input_pointer = cheshire_by
