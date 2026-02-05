extends StateMachine
class_name Level

var engine:ChessEngine = null	# 有可能会出现多线作战，共用同一个引擎显然不好
var chessboard:Chessboard = null
var in_battle:bool = false
var teleport:Dictionary = {}
var history_state:PackedInt64Array = []
@onready var history_document:Document = load("res://scene/history.tscn").instantiate()
var interact_list:Dictionary[int, Dictionary] = {}
var title:Dictionary[int, String] = {}

func _ready() -> void:
	engine = PastorEngine.new()
	var state = State.new()
	chessboard = $chessboard
	for node:Node in get_children():
		if node is Actor && node.piece_type != 0:
			var by:int = Chess.to_position_int(chessboard.get_position_name(node.position))
			state.add_piece(by, node.piece_type)
		if node is MarkerBit:
			var by:int = Chess.to_position_int(chessboard.get_position_name(node.position))
			state.set_bit(node.piece, state.get_bit(node.piece) | Chess.mask(Chess.to_64(by)))
		if node is MarkerEvent:
			var by:int = Chess.to_position_int($chessboard.get_position_name(node.global_position))
			state.set_bit(ord("Z"), state.get_bit(ord("Z")) | Chess.mask(Chess.to_64(by)))
			interact_list[by] = {"": node.event}
		if node is MarkerSelection:
			var by:int = Chess.to_position_int($chessboard.get_position_name(node.global_position))
			state.set_bit(ord("z"), state.get_bit(ord("z")) | Chess.mask(Chess.to_64(by)))
			if !interact_list.has(by):
				interact_list[by] = {}
			interact_list[by][node.selection] = node.event
			title[by] = ""
	var storage_piece:int = 0
	storage_piece += Progress.get_value("storage_queen", 0) << (5 * 4)
	storage_piece += Progress.get_value("storage_rook", 0) << (6 * 4)
	storage_piece += Progress.get_value("storage_bishop", 0) << (7 * 4)
	storage_piece += Progress.get_value("storage_knight", 0) << (8 * 4)
	storage_piece += Progress.get_value("storage_pawn", 0) << (9 * 4)
	state.set_bit(ord("6"), storage_piece)
	for i:int in Progress.get_value("storage_queen", 0):
		chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_queen_black.tscn").instantiate().set_larger_scale(), ord("q"))
	for i:int in Progress.get_value("storage_rook", 0):
		chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_rook_black.tscn").instantiate().set_larger_scale(), ord("r"))
	for i:int in Progress.get_value("storage_bishop", 0):
		chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_bishop_black.tscn").instantiate().set_larger_scale(), ord("b"))
	for i:int in Progress.get_value("storage_knight", 0):
		chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_knight_black.tscn").instantiate().set_larger_scale(), ord("n"))
	for i:int in Progress.get_value("storage_pawn", 0):
		chessboard.add_piece_instance_to_steady(load("res://scene/actor/piece_pawn_black.tscn").instantiate().set_larger_scale(), ord("p"))

	chessboard.set_state(state)
	for node:Node in get_children():
		if node is Actor && node.piece_type != 0:
			var by:int = Chess.to_position_int(chessboard.get_position_name(node.position))
			node.get_parent().remove_child(node)
			chessboard.add_piece_instance(node, by)
	Progress.create_if_not_exist("obtains", 0)
	Progress.create_if_not_exist("wins", 0)
	change_state("explore_idle")

var premove_from:int = -1
var premove_to:int = -1

func premove_init(explore:bool = false) -> void:
	if premove_from == -1:
		var start_from:int = chessboard.state.get_bit(ord("a"))
		chessboard.set_square_selection(start_from)
	elif premove_to == -1:
		var move_list:PackedInt32Array = Chess.generate_premove(chessboard.state, 1) if !explore else Chess.generate_explore_move(chessboard.state, 1)
		var selection:int = 0
		for iter:int in move_list:
			if Chess.from(iter) == premove_from:
				selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
		chessboard.set_square_selection(selection)

func premove_pressed(explore:bool = false) -> void:
	var start_from:int = chessboard.state.get_bit(ord("a"))
	if premove_from == -1 || premove_to != -1:
		premove_to = -1
		chessboard.clear_pointer("premove")
		var move_list:PackedInt32Array = Chess.generate_premove(chessboard.state, 1) if !explore else Chess.generate_explore_move(chessboard.state, 1)
		var selection:int = 0
		premove_from = chessboard.selected
		for iter:int in move_list:
			if Chess.from(iter) == premove_from:
				selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
		chessboard.set_square_selection(selection)
	else:
		premove_to = chessboard.selected
		chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), premove_from, 1)
		chessboard.draw_pointer("premove", Color(0.639, 0.051, 0.196, 1.0), premove_to, 1)
		chessboard.set_square_selection(start_from)

func premove_cancel() -> void:
	var start_from:int = chessboard.state.get_bit(ord("a"))
	premove_from = -1
	premove_to = -1
	chessboard.clear_pointer("premove")
	chessboard.set_square_selection(start_from)

func state_ready_explore_idle(_arg:Dictionary) -> void:
	var by:int = Chess.to_x88(chessboard.state.bit_index(ord("k"))[0])
	var selection:PackedStringArray = []
	var start_from:int = chessboard.state.get_bit(ord("a"))
	state_signal_connect(Dialog.on_next, change_state.bind("dialog"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_ready_to_move", {"from": chessboard.selected})
	)
	state_signal_connect(chessboard.empty_double_click, func () -> void:
		change_state("explore_select_piece", {"by": chessboard.selected})
	)
	if chessboard.state.get_bit(ord("z")) & Chess.mask(Chess.to_64(by)):
		selection = interact_list[by].keys()
		Dialog.push_selection(selection, title[by], false, false)
	chessboard.set_square_selection(start_from)

func state_exit_explore_idle() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_explore_ready_to_move(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_explore_move(chessboard.state, 1)
	var selection:int = 0
	var from:int = _arg["from"]
	var from_piece:int = chessboard.state.get_piece(from)
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
	state_signal_connect(Dialog.on_next, func() -> void:
		match Dialog.selected:
			"SELECTION_PIECES":
				change_state("explore_select_empty_square", {"selection": selection})
			"SELECTION_DOCUMENTS":
				Archive.open()
				change_state("explore_idle")
			"SELECTION_STATUS":
				Dialog.push_selection(["SELECTION_STATUS", "SELECTION_PIECES", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS"], 
					tr("HINT_STATUS") % [Progress.get_value("obtains", 0), Progress.get_value("wins", 0)], false, false)
			"SELECTION_SETTINGS":
				Setting.open()
				change_state("explore_idle")
			"SELECTION_REMOVE_PIECE":
				change_state("explore_move", {"move": Chess.create(from, from, 0)})
			"SELECTION_CANCEL":
				change_state("explore_idle")
	)
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_check_move", {"from": from, "to": chessboard.selected, "move_list": move_list})
	)
	state_signal_connect(chessboard.click_empty, change_state.bind("explore_idle"))
	if from_piece == ord("k"):
		Dialog.push_selection(["SELECTION_STATUS", "SELECTION_PIECES", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS", "SELECTION_CANCEL"], "", false, false)
	else:
		Dialog.push_selection(["SELECTION_REMOVE_PIECE", "SELECTION_CANCEL"], "", false, false)
	chessboard.set_square_selection(selection)

func state_exit_explore_ready_to_move() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_explore_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var move_list:PackedInt32Array = Array(_arg["move_list"]).filter(func (move:int) -> bool: return from == Chess.from(move) && to == Chess.to(move))
	if move_list.size() == 0:
		change_state("explore_idle", {})
		return
	elif move_list.size() > 1:
		change_state("explore_extra_move", {"move_list": move_list})
	else:
		change_state("explore_move", {"move": move_list[0]})

func state_ready_explore_extra_move(_arg:Dictionary) -> void:
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in _arg["move_list"]:
		decision_list.push_back("%c" % Chess.extra(iter))
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("SELECTION_CANCEL")
	state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "SELECTION_CANCEL":
			change_state("explore_idle")
		else:
			change_state("explore_move", {"move": decision_to_move[Dialog.selected]})
	)
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, true)

func state_ready_explore_move(_arg:Dictionary) -> void:
	state_signal_connect(chessboard.click_selection, premove_pressed.bind(true))
	state_signal_connect(chessboard.click_empty, premove_cancel)
	state_signal_connect(chessboard.animation_finished, change_state.bind("explore_check_attack", _arg))
	chessboard.execute_move(_arg["move"])
	premove_init(true)

func state_ready_explore_check_attack(_arg:Dictionary) -> void:
	if !chessboard.state.get_bit(ord("K")):
		change_state("explore_check_interact", _arg)
		return
	if Chess.is_check(chessboard.state, 1):
		change_state("versus_alert")
		return
	var white_move_list:PackedInt32Array = Chess.generate_move(chessboard.state, 0)
	for move:int in white_move_list:
		var to:int = Chess.to(move)
		if !chessboard.state.has_piece(to):
			continue
		if char(chessboard.state.get_piece(to)) in ["k", "q", "r", "b", "n", "p"]:
			change_state("versus_alert")
			return
	change_state("explore_check_interact", _arg)

func state_ready_explore_check_interact(_arg:Dictionary) -> void:
	var by:int = Chess.to_x88(chessboard.state.bit_index(ord("k"))[0])
	if _arg.has("move") && Chess.to(_arg["move"]) == by && chessboard.state.get_bit(ord("Z")) & Chess.mask(Chess.to_64(by)):
		change_state("interact", {"callback": interact_list[by][""]})
		return
	change_state("explore_check_premove")

func state_ready_explore_check_premove(_arg:Dictionary) -> void:
	if premove_from != -1 && premove_to != -1:
		change_state("explore_check_move", {"from": premove_from, "to": premove_to, "move_list": Chess.generate_explore_move(chessboard.state, 1)})
		premove_from = -1
		premove_to = -1
	elif premove_from != -1:
		change_state("explore_ready_to_move", {"from": premove_from})
		premove_from = -1
		premove_to = -1
	else:
		change_state("explore_idle")

func state_ready_explore_select_empty_square(_arg:Dictionary) -> void:
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_select_piece", {"by": chessboard.selected})
	)
	Dialog.push_selection(["SELECTION_CANCEL"], "HINT_SELECT_SQUARE", false, false)
	chessboard.set_square_selection(~chessboard.state.get_bit(ord(".")))

func state_ready_explore_select_piece(_arg:Dictionary) -> void:
	var storage_piece:int = chessboard.state.get_bit(ord("6"))
	var by:int = _arg["by"]
	var start_from:int = chessboard.state.get_bit(ord("a"))
	if chessboard.state.has_piece(by):
		change_state("explore_idle")
		return
	var selection:Array = []
	if (storage_piece >> (5 * 4)) & 0xF:
		selection.push_back("PIECE_QUEEN")
	if (storage_piece >> (6 * 4)) & 0xF:
		selection.push_back("PIECE_ROOK")
	if (storage_piece >> (7 * 4)) & 0xF:
		selection.push_back("PIECE_BISHOP")
	if (storage_piece >> (8 * 4)) & 0xF:
		selection.push_back("PIECE_KNIGHT")
	if (storage_piece >> (9 * 4)) & 0xF:
		selection.push_back("PIECE_PAWN")
	selection.push_back("SELECTION_CANCEL")
	state_signal_connect(Dialog.on_next, func () -> void:
		match Dialog.selected:
			"SELECTION_CANCEL":
				change_state("explore_idle")
			"PIECE_QUEEN":
				change_state("explore_move", {"move": Chess.create(by, by, ord("q"))})
			"PIECE_ROOK":
				change_state("explore_move", {"move": Chess.create(by, by, ord("r"))})
			"PIECE_BISHOP":
				change_state("explore_move", {"move": Chess.create(by, by, ord("b"))})
			"PIECE_KNIGHT":
				change_state("explore_move", {"move": Chess.create(by, by, ord("n"))})
			"PIECE_PAWN":
				change_state("explore_move", {"move": Chess.create(by, by, ord("p"))})
	)
	state_signal_connect(chessboard.empty_double_click, func () -> void:
		change_state("explore_select_piece", {"by": chessboard.selected})
	)
	state_signal_connect(chessboard.click_empty, change_state.bind("explore_idle"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_ready_to_move", {"from": chessboard.selected})
	)
	Dialog.push_selection(selection, "HINT_ADD_PIECE", false, false)
	chessboard.set_square_selection(start_from)

func state_exit_explore_select_piece() -> void:
	Dialog.clear()

func state_ready_versus_alert(_arg:Dictionary) -> void:
	state_signal_connect(Dialog.on_next, change_state.bind("versus_start"))
	Dialog.push_dialog("HINT_ENEMY_SPOTTED", "", true, true)

func state_ready_versus_start(_arg:Dictionary) -> void:
	Clock.set_time(30, 1)
	chessboard.state.set_turn(0)
	chessboard.state.set_castle(0xF)
	chessboard.state.set_step_to_draw(0)
	chessboard.state.set_round(1)
	history_document.set_state(chessboard.state)
	history_document.set_filename("history." + String.num_int64(Time.get_unix_time_from_system()) + ".json")
	if Chess.get_end_type(chessboard.state) == "checkmate_black":
		change_state("black_win")
	elif Chess.get_end_type(chessboard.state) == "checkmate_white":
		change_state("white_win")
	elif chessboard.state.get_turn() == 0:
		change_state("versus_enemy")
	else:
		change_state("versus_player")

func state_ready_versus_enemy(_arg:Dictionary) -> void:
	state_signal_connect(chessboard.click_selection, premove_pressed)
	state_signal_connect(chessboard.click_empty, premove_cancel)
	state_signal_connect(engine.search_finished, func() -> void:
		assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(engine.get_search_result()))))
		change_state("versus_move", {"move": engine.get_search_result()})
	)
	if !Progress.get_value("relax", false):
		engine.set_max_depth(20)
		engine.set_quies(false)
	else:
		engine.set_max_depth(2)
		engine.set_quies(true)
	engine.set_think_time(2)
	engine.start_search(chessboard.state, 0, history_state, Callable())
	premove_init()

func state_ready_versus_waiting() -> void:
	state_signal_connect(engine.search_finished, change_state.bind("versus_enemy"))
	engine.stop_search()

func state_ready_versus_move(_arg:Dictionary) -> void:
	Clock.pause()
	history_document.push_move(_arg["move"])
	history_document.save_file()
	history_state.push_back(chessboard.state.get_zobrist())

	state_signal_connect(chessboard.click_selection, premove_pressed)
	state_signal_connect(chessboard.click_empty, premove_cancel)
	state_signal_connect(chessboard.animation_finished, func() -> void:
		var end_type:String = Chess.get_end_type(chessboard.state)
		if end_type == "checkmate_black":
			change_state("black_win")
		elif end_type == "checkmate_white":
			change_state("white_win")
		elif end_type == "stalemate_black":
			change_state("versus_draw")
		elif end_type == "stalemate_white":
			change_state("versus_draw")
		elif end_type == "not_enough_piece":
			change_state("versus_draw")
		elif chessboard.state.get_turn() == 0:
			change_state("versus_enemy")
		elif premove_from != -1 && premove_to != -1:
			change_state("versus_check_move", {"from": premove_from, "to": premove_to, "move_list": Chess.generate_valid_move(chessboard.state, 1)})
			premove_from = -1
			premove_to = -1
		elif premove_from != -1:
			change_state("versus_ready_to_move", {"from": premove_from})
			premove_from = -1
			premove_to = -1
		else:
			change_state("versus_player"))
	
	assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(_arg["move"]))) 
	|| Chess.from(_arg["move"]) == Chess.to(_arg["move"]) && !chessboard.state.has_piece(Chess.from(_arg["move"])))
	chessboard.execute_move(_arg["move"])
	premove_init()

func state_ready_versus_player(_arg:Dictionary) -> void:
	var start_from:int = 0
	var can_introduce:bool = false
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, 1)
	for iter:int in move_list:
		if Chess.from(iter) == Chess.to(iter):
			can_introduce = true
		else:
			start_from |= Chess.mask(Chess.to_64(Chess.from(iter)))


	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("versus_ready_to_move", {"from": chessboard.selected})
	)
	if can_introduce:
		state_signal_connect(chessboard.empty_double_click, func () -> void:
			change_state("versus_select_piece", {"by": chessboard.selected})
		)
	state_signal_connect(Clock.timeout, change_state.bind("white_win"))
	Clock.resume()
	chessboard.clear_pointer("premove")
	premove_from = -1
	premove_to = -1
	chessboard.set_square_selection(start_from)

func state_ready_versus_ready_to_move(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, 1)
	var selection:int = 0
	var dialog_selection:PackedStringArray = []
	var introduce_selection:int = 0
	var from:int = _arg["from"]
	var from_piece:int = chessboard.state.get_piece(from)
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
		if Chess.from(iter) == Chess.to(iter):
			introduce_selection |= Chess.mask(Chess.to_64(Chess.from(iter)))
	if selection == 0:
		change_state("versus_player")
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("versus_check_move", {"from": from, "to": chessboard.selected, "move_list": move_list})
	)
	state_signal_connect(chessboard.click_empty, change_state.bind("versus_player"))
	state_signal_connect(Clock.timeout, change_state.bind("white_win"))
	state_signal_connect(Dialog.on_next, func() -> void:
		match Dialog.selected:
			"SELECTION_PIECES":
				change_state("versus_select_empty_square", {"selection": introduce_selection})
			"SELECTION_DOCUMENTS":
				Archive.open()
				change_state("versus_player")
			"SELECTION_STATUS":
				Dialog.push_selection(["SELECTION_STATUS", "SELECTION_PIECES", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS"], 
					tr("HINT_STATUS") % [Progress.get_value("obtains", 0), Progress.get_value("wins", 0)], false, false)
			"SELECTION_SETTINGS":
				Setting.open()
				change_state("versus_player")
			"SELECTION_CANCEL":
				change_state("versus_player")
	)
	if from_piece == ord("k"):
		if introduce_selection:
			Dialog.push_selection(["SELECTION_STATUS", "SELECTION_PIECES", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS", "SELECTION_CANCEL"], "", false, false)
		else:
			Dialog.push_selection(["SELECTION_STATUS", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS", "SELECTION_CANCEL"], "", false, false)
	else:
		Dialog.push_selection(["SELECTION_CANCEL"], "", false, false)
		Dialog.push_selection(dialog_selection, "", false, false)
	chessboard.set_square_selection(selection)

func state_ready_versus_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var move_list:PackedInt32Array = Array(_arg["move_list"]).filter(func (move:int) -> bool: return from == Chess.from(move) && to == Chess.to(move))
	if move_list.size() == 0:
		change_state("versus_player", {})
		return
	elif move_list.size() > 1:
		change_state("versus_extra_move", {"move_list": move_list})
	else:
		change_state("versus_move", {"move": move_list[0]})

func state_ready_versus_extra_move(_arg:Dictionary) -> void:
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in _arg["move_list"]:
		decision_list.push_back("%c" % Chess.extra(iter))
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("SELECTION_CANCEL")
	state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "SELECTION_CANCEL":
			change_state("versus_player")
		else:
			change_state("versus_move", {"move": decision_to_move[Dialog.selected]})
	)
	state_signal_connect(Clock.timeout, change_state.bind("white_win"))
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, true)

func state_ready_versus_select_empty_square(_arg:Dictionary) -> void:
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("versus_select_piece", {"by": chessboard.selected})
	)
	Dialog.push_selection(["SELECTION_CANCEL"], "HINT_SELECT_SQUARE", false, false)
	chessboard.set_square_selection(_arg["introduce_selection"])

func state_ready_versus_select_piece(_arg:Dictionary) -> void:
	var storage_piece:int = chessboard.state.get_bit(ord("6"))
	var by:int = _arg["by"]
	var start_from:int = chessboard.state.get_bit(ord("a"))
	if chessboard.state.has_piece(by):
		change_state("versus_player")
		return
	var selection:Array = []
	if (storage_piece >> (5 * 4)) & 0xF:
		selection.push_back("PIECE_QUEEN")
	if (storage_piece >> (6 * 4)) & 0xF:
		selection.push_back("PIECE_ROOK")
	if (storage_piece >> (7 * 4)) & 0xF:
		selection.push_back("PIECE_BISHOP")
	if (storage_piece >> (8 * 4)) & 0xF:
		selection.push_back("PIECE_KNIGHT")
	if (storage_piece >> (9 * 4)) & 0xF:
		selection.push_back("PIECE_PAWN")
	selection.push_back("SELECTION_CANCEL")
	state_signal_connect(Dialog.on_next, func () -> void:
		match Dialog.selected:
			"SELECTION_CANCEL":
				change_state("versus_player")
			"PIECE_QUEEN":
				change_state("versus_move", {"move": Chess.create(by, by, ord("q"))})
			"PIECE_ROOK":
				change_state("versus_move", {"move": Chess.create(by, by, ord("r"))})
			"PIECE_BISHOP":
				change_state("versus_move", {"move": Chess.create(by, by, ord("b"))})
			"PIECE_KNIGHT":
				change_state("versus_move", {"move": Chess.create(by, by, ord("n"))})
			"PIECE_PAWN":
				change_state("versus_move", {"move": Chess.create(by, by, ord("p"))})
	)
	state_signal_connect(chessboard.empty_double_click, func () -> void:
		change_state("versus_select_piece", {"by": chessboard.selected})
	)
	state_signal_connect(chessboard.click_empty, change_state.bind("explore_idle"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("versus_ready_to_move", {"from": chessboard.selected})
	)
	Dialog.push_selection(selection, "HINT_ADD_PIECE", false, false)
	chessboard.set_square_selection(start_from)


func state_ready_black_win(_arg:Dictionary) -> void:
	history_document.save_file()
	var bit:int = chessboard.state.get_bit(ord("A"))
	while bit:
		chessboard.state.capture_piece(Chess.to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.to_x88(Chess.first_bit(bit))].captured()
		bit = Chess.next_bit(bit)
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	Progress.accumulate("wins", 1)
	Dialog.push_dialog("HINT_YOU_WIN", "", true, true)

func state_ready_white_win(_arg:Dictionary) -> void:
	history_document.save_file()
	var by:int = Chess.to_x88(chessboard.state.bit_index(ord("k"))[0])
	chessboard.state.capture_piece(Chess.to_x88(by))
	#chessboard.chessboard_piece[Chess.to_x88(by)].captured()
	state_signal_connect(Dialog.on_next, change_state.bind("conclude"))
	Dialog.push_dialog("HINT_YOU_LOSE", "", true, true)

func state_ready_conclude(_arg:Dictionary) -> void:
	Loading.change_scene("res://scene/conclude.tscn", {}, 1)

func state_ready_versus_draw(_arg:Dictionary) -> void:
	history_document.save_file()
	var bit:int = chessboard.state.get_bit(ord("A"))
	while bit:
		chessboard.state.capture_piece(Chess.to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.to_x88(Chess.first_bit(bit))].leave()
		bit = Chess.next_bit(bit)
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	Dialog.push_dialog("平局", "", true, true)

func state_ready_dialog(_arg:Dictionary) -> void:
	var by:int = Chess.to_x88(chessboard.state.bit_index(ord("k"))[0])
	change_state("interact", {"callback": interact_list[by][Dialog.selected]})

func state_ready_interact(_arg:Dictionary) -> void:
	_arg["callback"].call()
