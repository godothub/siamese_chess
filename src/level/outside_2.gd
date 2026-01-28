extends "res://src/level/outside.gd"

var battle_finished:bool = false

func _ready() -> void:
	super._ready()
	battle_finished = Progress.has_key("outside_2_battle") && Progress.get_value("outside_2_battle")
	if !battle_finished:
		var table:Array = [
			{
				"actor": load("res://scene/actor/enemy_cheshire.tscn").instantiate(),
				"pos": 0x51,
				"piece": ord("K")
			}
		]
		for iter:Dictionary in table:
			var actor:Actor = iter["actor"]
			var piece_pos:int = iter["pos"]
			actor.position = $chessboard.convert_name_to_position(Chess.to_position_name(piece_pos))
			$chessboard.state.add_piece(piece_pos, iter["piece"])
			$chessboard.add_piece_instance(actor, piece_pos)
	connect("level_state_changed", on_level_state_changed)

func on_level_state_changed(state:String) -> void:
	if state == "black_win":
		battle_finished = true
		Progress.set_value("outside_2_battle", true)
