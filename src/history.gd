extends Document

var state:State = null
var history:PackedStringArray = []

func parse(data:String) -> void:
	var data_dict:Dictionary = JSON.parse_string(data)
	var fen:String = data_dict["state"]
	state = Chess.parse(fen)
	history = data_dict["history"]
	draw_lines(data_dict["lines"])
	update_table()

func stringify() -> String:
	var data_dict:Dictionary = {}
	var fen:String = Chess.stringify(state)
	data_dict["state"] = fen
	data_dict["history"] = history
	data_dict["lines"] = get_lines()
	return JSON.stringify(data_dict)

func get_rect() -> Rect2:
	return $history.get_rect() * $history.transform

func set_state(_state:State) -> void:
	state = _state.duplicate()
	history.clear()
	update_table()

func push_move(move:int) -> void:
	if history.size() >= 120:
		return
	history.push_back(Chess.get_move_name(state, move))
	Chess.apply_move(state, move)
	update_table()

func rollback(_state:State, pop_count:int = 1) -> void:
	history.resize(history.size() - pop_count)
	state = _state.duplicate()
	update_table()

func update_table() -> void:
	$chessboard_flat.set_state(state)
	for i:int in range(history.size()):
		if i % 2 == 0:
			get_node("white/label_%d" % (i / 2 + 1)).text = history[i]
		else:
			get_node("black/label_%d" % (i / 2 + 1)).text = history[i]

func add_blank_line() -> void:
	history.push_back("")
	history.push_back("")
