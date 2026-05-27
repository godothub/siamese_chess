extends Level

var standard_history_zobrist:PackedInt64Array = []
var standard_history_state:Array[State] = []
var standard_history_event:Array[Dictionary] = []
@onready var standard_history_document:Document = load("res://src/doc/history.gd").new()
@onready var standard_chessboard:Chessboard = $table_0/chessboard_standard
var standard_engine:ChessEngine = PastorEngine.new()
var standard_state_machine:StateMachine = StateMachine.new()
var standard_premove_state_machine:StateMachine = StateMachine.new()
var standard_player_group:int = 0

func _ready() -> void:
	super._ready()
	standard_history_document.set_filename("history.match_with_yulan.json")
	standard_history_document.load_file()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.x88_to_vector3(cheshire_by)
	$chessboard.state.add_piece(cheshire_by, player_king)
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	chessboard.button_input_pointer = cheshire_by
	
	standard_engine.set_think_time(INF)
	standard_chessboard.set_enabled(false)
	$player.add_inspectable_item(standard_chessboard)
	$pastor.play_animation("thinking")
	title[0x54] = "CHAR_YULAN"
	title[0x55] = "CHAR_YULAN"
	standard_state_machine.name = "yulan"
	standard_state_machine.add_state("edit_state", state_ready_in_game_edit_state)
	standard_state_machine.add_state("edit_fen", state_ready_in_game_edit_fen)
	standard_state_machine.add_state("edit_turn", state_ready_in_game_edit_turn)
	standard_state_machine.add_state("start", state_ready_in_game_start)
	standard_state_machine.add_state("opponent", state_ready_in_game_opponent)
	standard_state_machine.add_state("waiting", state_ready_in_game_waiting)
	standard_state_machine.add_state("move", state_ready_in_game_move)
	standard_state_machine.add_state("player", state_ready_in_game_player, state_exit_in_game_player)
	standard_state_machine.add_state("ready_to_move", state_ready_in_game_ready_to_move, state_exit_in_game_ready_to_move)
	standard_state_machine.add_state("check_move", state_ready_in_game_check_move)
	standard_state_machine.add_state("extra_move", state_ready_in_game_extra_move)
	standard_state_machine.add_state("result", state_ready_result)
	standard_state_machine.add_state("end", state_ready_end)
	standard_premove_state_machine.name = "yulan_premove"
	standard_premove_state_machine.add_state("start", state_game_premove_start_ready)
	standard_premove_state_machine.add_state("from", state_game_premove_from_ready, state_game_premove_from_exit)
	standard_premove_state_machine.add_state("to", state_game_premove_to_ready, state_game_premove_to_exit)
	standard_premove_state_machine.add_state("extra", state_game_premove_extra_ready, state_game_premove_extra_exit)
	standard_premove_state_machine.add_state("confirm", state_game_premove_confirm_ready)
	standard_premove_state_machine.add_state("stop", state_game_premove_stop_ready)
	game_premove_branch = PremoveBranch.new()

func interact_pastor() -> void:
	state_machine.change_state("stop")
	$player.force_set_camera($camera_pastor)

	var from:int = Chess.c64_to_x88(Chess.first_bit($chessboard.state.get_bit(player_king)))
	if from != 0x54:
		$chessboard.execute_move(Chess.create(from, 0x54, 0))
		await $chessboard.animation_finished
	$chessboard.set_enabled(false)
	standard_chessboard.set_enabled(true)
	$chessboard/pieces/cheshire.set_position($chessboard.name_to_vector3("e2"))
	$chessboard/pieces/cheshire.set_rotation(Vector3(0, PI / 2, 0))
	$chessboard/pieces/cheshire.play_animation("thinking")
	$player.force_set_camera($camera_chessboard)

	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	standard_state_machine.change_state("edit_state")

var game_premove_branch:PremoveBranch = PremoveBranch.new()
var game_premove_from:int = -1
var game_premove_to:int = -1

func state_game_premove_start_ready(_arg:Dictionary) -> void:
	if !game_premove_branch:
		game_premove_branch = PremoveBranch.new()
	if !game_premove_branch.move_order.size():
		game_premove_branch.future_state = standard_chessboard.state.duplicate()
	standard_premove_state_machine.change_state.call_deferred("from")

func state_game_premove_from_ready(_arg:Dictionary) -> void:
	game_premove_from = -1
	game_premove_to = -1
	var start_from:int = 0
	var move_list:PackedInt32Array = Chess.generate_premove(game_premove_branch.future_state, standard_player_group)
	if game_premove_branch.move_order.size():
		Dialog.show_cancel()
	for iter:int in move_list:
		start_from |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))

	standard_premove_state_machine.state_signal_connect(standard_chessboard.click_selection, func (_selected:int) -> void:
		game_premove_from = _selected
		standard_premove_state_machine.change_state.call_deferred("to", {"from": _selected})
	)
	standard_premove_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		game_premove_branch.future_state = standard_chessboard.state.duplicate()
		game_premove_branch.move_order = []
	)
	standard_chessboard.set_square_selection(start_from)

func state_game_premove_from_exit() -> void:
	Dialog.clear()
	Dialog.hide_cancel()

func state_game_premove_to_ready(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_premove(game_premove_branch.future_state, standard_player_group)
	var selection:int = 0
	for iter:int in move_list:
		if Chess.from(iter) == _arg["from"]:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	standard_premove_state_machine.state_signal_connect(standard_chessboard.click_selection, func(_selected:int) -> void:
		game_premove_to = _selected
		var cnt:int = 0
		for iter:int in move_list:
			if Chess.from(iter) == _arg["from"] && Chess.to(iter) == _selected:
				cnt += 1
		if cnt == 1:
			standard_premove_state_machine.change_state.call_deferred("confirm", {"move": Chess.create(_arg["from"], _selected, 0)})
		elif cnt > 1:
			standard_premove_state_machine.change_state.call_deferred("extra", {"from": _arg["from"], "to": _selected})
	)
	standard_premove_state_machine.state_signal_connect(standard_chessboard.click_empty, func(_selected:int) -> void:
		standard_premove_state_machine.change_state.call_deferred("from")
	)
	standard_premove_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		standard_premove_state_machine.change_state.call_deferred("from")
	)
	Dialog.show_cancel()
	standard_chessboard.set_square_selection(selection)

func state_game_premove_to_exit() -> void:
	Dialog.hide_cancel()

func state_game_premove_extra_ready(_arg:Dictionary) -> void:
	var map:Dictionary = {
		ord("Q"): "PIECE_QUEEN",
		ord("R"): "PIECE_ROOK",
		ord("B"): "PIECE_BISHOP",
		ord("N"): "PIECE_KNIGHT",
		ord("q"): "PIECE_QUEEN",
		ord("r"): "PIECE_ROOK",
		ord("b"): "PIECE_BISHOP",
		ord("n"): "PIECE_KNIGHT",
	}
	var move_list:PackedInt32Array = Chess.generate_premove(standard_chessboard.state, standard_player_group)
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in move_list:
		if Chess.from(iter) == _arg["from"] && Chess.to(iter) == _arg["to"]:
			decision_list.push_back(map[Chess.extra(iter)])
			decision_to_move[decision_list[-1]] = iter
	standard_premove_state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		standard_premove_state_machine.change_state.call_deferred("confirm", {"move": decision_to_move[Dialog.selected]})
	)
	standard_premove_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		standard_premove_state_machine.change_state.call_deferred("from")
	)
	standard_premove_state_machine.state_signal_connect(Clock.timeout, standard_premove_state_machine.change_state.call_deferred.bind("enemy_win"))
	Dialog.show_cancel()
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, false)

func state_game_premove_extra_exit() -> void:
	Dialog.clear()
	Dialog.hide_cancel()

func state_game_premove_confirm_ready(_arg:Dictionary) -> void:
	game_premove_from = -1
	game_premove_to = -1
	game_premove_branch.move_order.push_back(_arg["move"])
	Chess.apply_move(game_premove_branch.future_state, _arg["move"])
	standard_chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), Chess.from(_arg["move"]))
	standard_chessboard.draw_pointer("premove", Color(0.639, 0.051, 0.196, 1.0), Chess.to(_arg["move"]))
	standard_premove_state_machine.change_state.call_deferred("from")

func state_game_premove_stop_ready(_arg:Dictionary) -> void:
	pass

var edit_piece:int = 0
func state_ready_in_game_edit_state(_arg:Dictionary) -> void:
	standard_state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		match _selected:
			"PIECE_WHITE":
				Dialog.push_selection(["PIECE_WHITE_KING", "PIECE_WHITE_QUEEN", "PIECE_WHITE_ROOK", "PIECE_WHITE_BISHOP", "PIECE_WHITE_KNIGHT", "PIECE_WHITE_PAWN"], "HINT_EDIT", false, false)
				return
			"PIECE_BLACK":
				Dialog.push_selection(["PIECE_BLACK_KING", "PIECE_BLACK_QUEEN", "PIECE_BLACK_ROOK", "PIECE_BLACK_BISHOP", "PIECE_BLACK_KNIGHT", "PIECE_BLACK_PAWN"], "HINT_EDIT", false, false)
				return
			"PIECE_NEUTRAL":
				Dialog.push_selection(["PIECE_BARRIER", "PIECE_BREAKABLE_BARRIER"], "HINT_EDIT", false, false)
				return
			"PIECE_WHITE_KING":
				edit_piece = ord("K")
			"PIECE_WHITE_QUEEN":
				edit_piece = ord("Q")
			"PIECE_WHITE_ROOK":
				edit_piece = ord("R")
			"PIECE_WHITE_BISHOP":
				edit_piece = ord("B")
			"PIECE_WHITE_KNIGHT":
				edit_piece = ord("N")
			"PIECE_WHITE_PAWN":
				edit_piece = ord("P")
			"PIECE_BLACK_KING":
				edit_piece = ord("k")
			"PIECE_BLACK_QUEEN":
				edit_piece = ord("q")
			"PIECE_BLACK_ROOK":
				edit_piece = ord("r")
			"PIECE_BLACK_BISHOP":
				edit_piece = ord("b")
			"PIECE_BLACK_KNIGHT":
				edit_piece = ord("n")
			"PIECE_BLACK_PAWN":
				edit_piece = ord("p")
			"PIECE_BARRIER":
				edit_piece = ord("#")
			"PIECE_BREAKABLE_BARRIER":
				edit_piece = ord("*")
			"PIECE_REMOVE":
				edit_piece = 0
			"SELECTION_IMPORT_FEN":
				standard_state_machine.change_state("edit_fen")
				return
			"SELECTION_FINISH":
				standard_state_machine.change_state("edit_turn")
				return
			"SELECTION_CANCEL":
				standard_state_machine.change_state("end")
				return
		Dialog.push_selection(["SELECTION_CANCEL", "PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_NEUTRAL", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], "HINT_EDIT", false, false)
	)
	standard_state_machine.state_signal_connect(standard_chessboard.click_empty, func (_selected:int) -> void:
		if standard_chessboard.state.has_piece(_selected):
			standard_chessboard.state.capture_piece(_selected)
			standard_chessboard.remove_piece_instance(standard_chessboard.chessboard_piece[_selected])
		if edit_piece:
			standard_chessboard.state.add_piece(_selected, edit_piece)
			standard_chessboard.add_piece_instance(Chessboard.get_default_piece_instance(edit_piece), _selected)
	)
	Dialog.push_selection(["SELECTION_CANCEL", "PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_NEUTRAL", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], "HINT_EDIT", false, false)

func state_ready_in_game_edit_fen(_arg:Dictionary) -> void:
	var text_input_instance:TextInput = TextInput.create_text_input_instance("输入FEN格式的布局：", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	add_child(text_input_instance)
	standard_state_machine.state_signal_connect(text_input_instance.confirmed, func(text:String) -> void:
		var test_state:State = Chess.parse(text)
		if test_state:
			standard_chessboard.state = test_state
			standard_chessboard.remove_piece_set()
			standard_chessboard.add_default_piece_set()
		else:
			Toast.create_instance("HINT_ILLEGAL_FORMAT")
		standard_state_machine.change_state("edit_state")
	)

func state_ready_in_game_edit_turn(_arg:Dictionary) -> void:
	standard_state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		match _selected:
			"SELECTION_CANCEL":
				standard_state_machine.change_state("end")
				return
			"SELECTION_PLAY_AS_WHITE":
				standard_player_group = 0
			"SELECTION_PLAY_AS_BLACK":
				standard_player_group = 1
			"SELECTION_PLAY_AS_RANDOM":
				standard_player_group = randi() % 2
		if standard_player_group == 0:
			standard_chessboard.rotation.y = 0
		else:
			standard_chessboard.rotation.y = PI
		standard_state_machine.change_state("start")
	)
	Dialog.push_selection(["SELECTION_PLAY_AS_BLACK", "SELECTION_PLAY_AS_WHITE", "SELECTION_PLAY_AS_RANDOM", "SELECTION_CANCEL"], "", true, false)

func state_ready_in_game_start(_arg:Dictionary) -> void:
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	standard_history_state.clear()
	standard_history_zobrist.clear()
	standard_history_event.clear()
	standard_history_document.new_page()
	standard_history_document.set_state(-1, standard_chessboard.state)
	standard_history_document.set_sign(-1, Time.get_datetime_string_from_system(), name, tr("CHAR_YULAN"), tr("CHAR_LOTUS"), tr("CHAR_YULAN"))
	standard_premove_state_machine.change_state("stop")
	if standard_chessboard.state.get_turn() != standard_player_group:
		standard_state_machine.change_state("opponent")
	else:
		standard_state_machine.change_state("player")

func state_ready_in_game_opponent(_arg:Dictionary) -> void:
	standard_state_machine.state_signal_connect(standard_engine.search_finished, func () -> void:
		print("score: ", standard_engine.get_score())
		print("deepest depth: ", standard_engine.get_deepest_depth())
		print("deepest ply: ", standard_engine.get_deepest_ply())
		print("evaluated_position: ", standard_engine.get_evaluated_position())
		print("beta_cutoff: ", standard_engine.get_beta_cutoff())
		print("transposition_table_cutoff: ", standard_engine.get_transposition_table_cutoff())
		standard_state_machine.change_state("move", {"move": standard_engine.get_search_result()})
	)
	if !Setting.get_value("relax"):
		standard_engine.set_max_depth(20)
		standard_engine.set_quies_enabled(true)
	else:
		standard_engine.set_max_depth(2)
		standard_engine.set_quies_enabled(false)
	standard_engine.set_think_time(3)
	standard_engine.start_search(standard_chessboard.state, 1 - standard_player_group, standard_history_state, Callable())
	if standard_premove_state_machine.current_state == "stop":
		standard_premove_state_machine.change_state("start")

func state_ready_in_game_waiting() -> void:
	standard_state_machine.state_signal_connect(standard_engine.search_finished, standard_state_machine.change_state.bind("opponent"))
	standard_engine.stop_search()

func state_ready_in_game_move(_arg:Dictionary) -> void:
	standard_history_document.push_move(-1, _arg["move"])
	standard_history_state.push_back(standard_chessboard.state.duplicate())
	standard_history_zobrist.push_back(standard_chessboard.state.get_zobrist())
	if Setting.get_value("text_to_speech"):
		var content:String = "WHITE_PLAY" if standard_chessboard.state.get_turn() == 0 else "BLACK_PLAY"
		content = tr(content).format({"move": Chess.get_move_name(standard_chessboard.state, _arg["move"])})
		Narrative.speak(content, false)
	var rollback_event:Dictionary = standard_chessboard.execute_move(_arg["move"])
	standard_history_event.push_back(rollback_event)
	if Chess.get_end_type(standard_chessboard.state) != "":
		standard_state_machine.change_state("result")
	elif standard_chessboard.state.get_turn() != standard_player_group:
		standard_state_machine.change_state("opponent")
	elif game_premove_branch && game_premove_branch.move_order.size():
		var next_premove:int = game_premove_branch.move_order[0]
		game_premove_branch.move_order.remove_at(0)
		if game_premove_branch.move_order.size() == 0:
			standard_chessboard.clear_pointer("premove")
		standard_state_machine.change_state.call_deferred("check_move", {"from": Chess.from(next_premove), "to": Chess.to(next_premove), "extra": Chess.extra(next_premove)})
	elif game_premove_from != -1 && (standard_chessboard.mouse_hold || standard_chessboard.button_input_hold):
		standard_state_machine.change_state("ready_to_move", {"from": game_premove_from})
		game_premove_from = -1
		game_premove_to = -1
	else:
		standard_state_machine.change_state("player")

func state_ready_in_game_player(_arg:Dictionary) -> void:
	standard_premove_state_machine.change_state("stop")
	var start_from:int = standard_chessboard.state.get_bit(ord('A') if standard_player_group == 0 else ord('a'))
	standard_state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "SELECTION_TAKE_BACK":
			if standard_history_event.size() <= 1:
				Dialog.push_selection(["SELECTION_LEAVE_GAME"], "HINT_TAKE_BACKED", false, false)
				return
			standard_chessboard.state = standard_history_state[-2]
			standard_chessboard.set_square_selection(standard_chessboard.state.get_bit(ord('A') if standard_player_group == 0 else ord('a')))
			standard_chessboard.receive_rollback_event(standard_history_event[-1])
			standard_chessboard.receive_rollback_event(standard_history_event[-2])
			standard_history_zobrist.resize(standard_history_zobrist.size() - 2)
			standard_history_state.resize(standard_history_state.size() - 2)
			standard_history_event.resize(standard_history_event.size() - 2)
			standard_history_document.rollback(-1, standard_chessboard.state, 2)
			await standard_chessboard.animation_finished
			if standard_history_event.size() <= 1:
				Dialog.push_selection(["SELECTION_LEAVE_GAME"], "HINT_TAKE_BACKED", false, false)
			else:
				Dialog.push_selection(["SELECTION_TAKE_BACK", "SELECTION_LEAVE_GAME"], "HINT_TAKE_BACKED", false, false)
		elif Dialog.selected == "SELECTION_LEAVE_GAME":
			standard_state_machine.change_state("end")
	)
	standard_state_machine.state_signal_connect(standard_chessboard.click_selection, func (_selected:int) -> void:
		standard_state_machine.change_state("ready_to_move", {"from": _selected})
	)

	if standard_history_event.size() <= 1:
		Dialog.push_selection(["SELECTION_LEAVE_GAME"], "HINT_YOUR_TURN", false, false)
	else:
		Dialog.push_selection(["SELECTION_TAKE_BACK", "SELECTION_LEAVE_GAME"], "HINT_YOUR_TURN", false, false)
	standard_chessboard.set_square_selection(start_from)

func state_exit_in_game_player() -> void:
	Dialog.clear()

func state_ready_in_game_ready_to_move(_arg:Dictionary) -> void:
	standard_premove_state_machine.change_state("stop")
	var move_list:PackedInt32Array = Chess.generate_valid_move(standard_chessboard.state, standard_player_group)
	var selection:int = 0
	var from:int = _arg["from"]
	var actor:Actor = standard_chessboard.chessboard_piece[from]
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	standard_state_machine.state_signal_connect(standard_chessboard.click_selection, func (_selected:int) -> void:
		standard_state_machine.change_state("check_move", {"from": from, "to": _selected})
	)
	standard_state_machine.state_signal_connect(standard_chessboard.click_empty, func (_selected:int) -> void:
		actor.idle()
		standard_state_machine.change_state("player")
	)
	standard_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		actor.idle()
		standard_state_machine.change_state("player")
	)
	Dialog.show_cancel()
	actor.ready_to_move()
	standard_chessboard.set_square_selection(selection)

func state_exit_in_game_ready_to_move() -> void:
	Dialog.hide_cancel()

func state_ready_in_game_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var actor:Actor = standard_chessboard.chessboard_piece[from]
	var move_list:PackedInt32Array = Chess.generate_valid_move(standard_chessboard.state, standard_player_group)
	if _arg.has("from"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["from"] == Chess.from(move))
	if _arg.has("to"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["to"] == Chess.to(move))
	if _arg.has("extra"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["extra"] == Chess.extra(move))
	if move_list.size() == 0:
		if premove_branch.move_order:
			premove_branch.move_order.clear()
			premove_branch.future_state = standard_chessboard.state.duplicate()
		actor.idle()
		standard_state_machine.change_state.call_deferred("player", {})
		return
	elif move_list.size() > 1:
		standard_state_machine.change_state.call_deferred("extra_move", {"from": from, "to": to, "move_list": move_list})
	else:
		standard_state_machine.change_state.call_deferred("move", {"move": move_list[0]})

func state_ready_in_game_extra_move(_arg:Dictionary) -> void:
	standard_premove_state_machine.change_state("stop")
	var map:Dictionary = {
		ord("Q"): "PIECE_QUEEN",
		ord("R"): "PIECE_ROOK",
		ord("B"): "PIECE_BISHOP",
		ord("N"): "PIECE_KNIGHT",
		ord("q"): "PIECE_QUEEN",
		ord("r"): "PIECE_ROOK",
		ord("b"): "PIECE_BISHOP",
		ord("n"): "PIECE_KNIGHT",
	}
	var from:int = _arg["from"]
	var actor:Actor = standard_chessboard.chessboard_piece[from]
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in _arg["move_list"]:
		decision_list.push_back(map[Chess.extra(iter)])
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("cancel")
	standard_state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "cancel":
			actor.idle()
			standard_state_machine.change_state("player")
		else:
			standard_state_machine.change_state("move", {"move": decision_to_move[Dialog.selected]})
	)
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, true)

func state_ready_result(_arg:Dictionary) -> void:
	match Chess.get_end_type(standard_chessboard.state):
		"checkmate_black":
			Dialog.push_dialog("HINT_BLACK_CHECKMATE", "", true, true)
		"checkmate_white":
			Dialog.push_dialog("HINT_WHITE_CHECKMATE", "", true, true)
		"stalemate_black":
			Dialog.push_dialog("HINT_DRAW", "", true, true)
		"stalemate_white":
			Dialog.push_dialog("HINT_DRAW", "", true, true)
		"50_moves":
			Dialog.push_dialog("HINT_DRAW", "", true, true)
	standard_state_machine.state_signal_connect(Dialog.on_next, standard_state_machine.change_state.bind("end"))

func state_ready_end(_arg:Dictionary) -> void:
	standard_history_document.save_file()
	$player.force_set_camera($camera)
	$chessboard/pieces/cheshire.play_animation("battle_idle")
	$chessboard/pieces/cheshire.set_position($chessboard.name_to_vector3("e3"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	state_machine.change_state("resume")
