extends MarkerEvent

var taken:bool = false
@export var cover:Texture2D = null
@export var actor:PackedScene = null
@export var card_piece:int = 0
@export var comment:String = ""
@export var progress_key:String = ""

func _ready() -> void:
	taken = Progress.has_key(progress_key) && Progress.get_value(progress_key)
	visible = !taken

func event() -> void:
	if taken:
		level.change_state("explore_idle")
		return
	taken = true
	Progress.set_value(progress_key, true)
	var storage_piece:int = level.chessboard.state.get_storage_piece()
	match card_piece:
		ord("q"):
			Progress.accumulate("storage_queen", 1)
			storage_piece += 1 << (5 * 4)
			level.chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_queen_black.tscn").instantiate().set_larger_scale(), ord("q"))
		ord("r"):
			Progress.accumulate("storage_rook", 1)
			storage_piece += 1 << (6 * 4)
			level.chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_rook_black.tscn").instantiate().set_larger_scale(), ord("r"))
		ord("b"):
			Progress.accumulate("storage_bishop", 1)
			storage_piece += 1 << (7 * 4)
			level.chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_bishop_black.tscn").instantiate().set_larger_scale(), ord("b"))
		ord("n"):
			Progress.accumulate("storage_knight", 1)
			storage_piece += 1 << (8 * 4)
			level.chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_knight_black.tscn").instantiate().set_larger_scale(), ord("n"))
		ord("p"):
			Progress.accumulate("storage_pawn", 1)
			storage_piece += 1 << (9 * 4)
			level.chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_pawn_black.tscn").instantiate().set_larger_scale(), ord("p"))
	visible = false
	level.chessboard.state.set_storage_piece(storage_piece)
	Dialog.push_dialog(comment, "HINT_GET_PIECE", false, false, false)
	level.change_state("explore_idle")
