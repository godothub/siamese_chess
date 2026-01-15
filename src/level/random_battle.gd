extends "res://src/level/outside.gd"

var random_pattern:Array = [
	{
		"map": [
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			 "P",      "P",      "P",      "P",      "P",      "P",      "P",      "P",
		   "NBR",    "NBR",    "NBR",      "K",    "NBR",    "NBR",    "NBR",    "NBR",
		]
	},
	{
		"map": [
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			 "P",      "P",      "P",      "P",      "P",      "P",      "P",      "P",
			   0,        0,        0,      "K",        0,        0,        0,        0,
		]
	},
	{
		"map": [
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,      "*",      "*",      "*",      "*",      "*",        0,
			   0,      "*",      "*",      "*",      "*",      "*",      "*",        0,
			   0,      "*",      "*",      "*",      "*",     "N*",      "*",        0,
			   0,      "*",      "*",      "*",      "*",      "*",      "*",        0,
			   0,      "*",     "N*",      "*",      "K",      "*",      "*",        0,
			   0,      "*",      "*",      "*",      "*",      "*",      "*",        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
		]
	},
	{
		"map": [
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,    "BN ",    "BN ",    "BN ",    "BN ",        0,        0,
			   0,        0,    "BN ",    "BN ",    "BN ",    "BN ",        0,        0,
			   0,        0,    "BN ",    "BN ",      "K",    "BN ",        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
		]
	},
	{
		"map": [
			   0,      "n",        0,        0,        0,        0,      "n",        0,
			   0,        0,        0,        0,        0,        0,        0,        0,
			   0,        0,    "#  ",    "#  ",    "#  ",    "#  ",        0,        0,
			   0,        0,    "#  ",    "#  ",    "#  ",    "#  ",        0,        0,
			   0,        0,    "#  ",    "#  ",    "#  ",    "#  ",        0,        0,
			   0,        0,    "#  ",    "#  ",    "#  ",    "#  ",        0,        0,
			   0,        0,        0,        0,        0,      "#",      "#",      "#",
			   0,        0,        0,        0,        0,      "#",      "K",      "#",
		]
	}
]

var actor:Dictionary = {
	ord('P'): load("res://scene/actor/piece_pawn_white.tscn").instantiate().set_larger_scale(),
	ord('N'): load("res://scene/actor/piece_knight_white.tscn").instantiate().set_larger_scale(),
	ord('B'): load("res://scene/actor/piece_bishop_white.tscn").instantiate().set_larger_scale(),
	ord('R'): load("res://scene/actor/piece_rook_white.tscn").instantiate().set_larger_scale(),
	ord('Q'): load("res://scene/actor/piece_queen_white.tscn").instantiate().set_larger_scale(),
	ord('K'): load("res://scene/actor/enemy_cheshire.tscn").instantiate(),
	ord('p'): load("res://scene/actor/piece_pawn_black.tscn").instantiate().set_larger_scale(),
	ord('n'): load("res://scene/actor/piece_knight_black.tscn").instantiate().set_larger_scale(),
	ord('b'): load("res://scene/actor/piece_bishop_black.tscn").instantiate().set_larger_scale(),
	ord('r'): load("res://scene/actor/piece_rook_black.tscn").instantiate().set_larger_scale(),
	ord('q'): load("res://scene/actor/piece_queen_black.tscn").instantiate().set_larger_scale(),
	ord('*'): load("res://scene/actor/shrub.tscn").instantiate(),
	ord('#'): load("res://scene/actor/stone.tscn").instantiate(),
}
var white:Array = [ord('P'), ord('N'), ord('B'), ord('R'), ord('Q')]

var pattern_seed:int = Time.get_unix_time_from_system()

func _ready() -> void:
	var map_pos:Vector2i = get_meta("map_pos")
	$teleport_pointer_1.args["map_pos"] = map_pos + Vector2i(0, 1)
	$teleport_pointer_2.args["map_pos"] = map_pos + Vector2i(0, 1)
	$teleport_pointer_3.args["map_pos"] = map_pos + Vector2i(0, -1)
	$teleport_pointer_4.args["map_pos"] = map_pos + Vector2i(0, -1)
	$teleport_pointer_5.args["map_pos"] = map_pos + Vector2i(-1, 0)
	$teleport_pointer_6.args["map_pos"] = map_pos + Vector2i(-1, 0)
	$teleport_pointer_7.args["map_pos"] = map_pos + Vector2i(1, 0)
	$teleport_pointer_8.args["map_pos"] = map_pos + Vector2i(1, 0)
	super._ready()
	pattern_seed += map_pos.x * 100 + map_pos.y
	seed(pattern_seed)
	var pattern:Array = random_pattern[randi() % random_pattern.size()]["map"]
	for i:int in 64:
		if pattern[i]:
			var piece:int = pattern[i].unicode_at(randi() % pattern[i].length())
			if piece != ord(" "):
				$chessboard.state.add_piece(Chess.to_x88(i), piece)
				$chessboard.add_piece_instance(actor[piece].duplicate(), Chess.to_x88(i))
