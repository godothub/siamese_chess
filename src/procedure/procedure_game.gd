extends LevelProcedure
class_name ProcedureGame

# 如果为2，就相当于同时控制黑白双方
signal move_played(move:int)
@export var player_group:int = 1

var engine:ChessEngine = null	# 有可能会出现多线作战，共用同一个引擎显然不好
@export var engine_standard_think_time = 2
@export var engine_standard_think_depth = 20
@export var engine_relax_think_time = INF
@export var engine_relax_think_depth = 2
@export var can_take_back:bool = true
@export var can_leave:bool = true
@export var leave_on_end:bool = true
@export var chessboard:Chessboard = null
@export var history_name:String = ""
var history_zobrist:PackedInt64Array = []
var history_state:Array[State] = []
var history_event:Array = []
@onready var history_document:Document = load("res://src/doc/history.gd").new()
var state_machine:StateMachine = StateMachine.new()
var premove_state_machine:StateMachine = StateMachine.new()

func _ready() -> void:
	engine = PastorEngine.new()
	state_machine.name = "game"
	state_machine.add_state("start", state_ready_start)
	state_machine.add_state("engine", state_ready_engine)
	state_machine.add_state("waiting", state_ready_waiting)
	state_machine.add_state("move", state_ready_move)
	state_machine.add_state("player", state_ready_player, state_exit_player)
	state_machine.add_state("ready_to_move", state_ready_ready_to_move, state_exit_ready_to_move)
	state_machine.add_state("check_move", state_ready_check_move)
	state_machine.add_state("extra_move", state_ready_extra_move, state_exit_extra_move)
	state_machine.add_state("result", state_ready_result)
	state_machine.add_state("end", state_ready_end)
	premove_state_machine.name = "premove"
	premove_state_machine.add_state("start", state_premove_start_ready)
	premove_state_machine.add_state("from", state_premove_from_ready, state_premove_from_exit)
	premove_state_machine.add_state("to", state_premove_to_ready)
	premove_state_machine.add_state("extra", state_premove_extra_ready, state_premove_extra_exit)
	premove_state_machine.add_state("confirm", state_premove_confirm_ready)
	premove_state_machine.add_state("stop", state_premove_stop_ready)
	
	connect("tree_exiting", on_tree_exiting)

func start() -> void:
	if history_name:
		history_document.set_filename("history." + history_name + ".json")
		history_document.load_file()
	state_machine.change_state("start")

class PremoveBranch extends RefCounted:
	var move_order:PackedInt32Array = []
	var future_state:State = null

var premove_branch:PremoveBranch = PremoveBranch.new()
var premove_from:int = -1
var premove_to:int = -1

func state_premove_start_ready(_arg:Dictionary) -> void:
	if !premove_branch:
		premove_branch = PremoveBranch.new()
	if !premove_branch.move_order.size():
		premove_branch.future_state = chessboard.state.duplicate()
	premove_state_machine.change_state.call_deferred("from")

func state_premove_from_ready(_arg:Dictionary) -> void:
	premove_from = -1
	premove_to = -1
	var start_from:int = 0
	var move_list:PackedInt32Array = Chess.generate_premove(premove_branch.future_state, player_group)
	for iter:int in move_list:
		start_from |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))

	premove_state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		premove_from = _selected
		premove_state_machine.change_state.call_deferred("to", {"from": _selected})
	)
	premove_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		premove_branch.future_state = chessboard.state.duplicate()
		premove_branch.move_order = []
	)
	if premove_branch.move_order.size():
		Dialog.show_cancel()
	chessboard.set_square_selection(start_from)

func state_premove_from_exit() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()
	Dialog.hide_cancel()

func state_premove_to_ready(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_premove(premove_branch.future_state, player_group)
	var selection:int = 0
	for iter:int in move_list:
		if Chess.from(iter) == _arg["from"]:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	premove_state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		premove_to = _selected
		var cnt:int = 0
		for iter:int in move_list:
			if Chess.from(iter) == _arg["from"] && Chess.to(iter) == _selected:
				cnt += 1
		if cnt == 1:
			premove_state_machine.change_state.call_deferred("confirm", {"move": Chess.create(_arg["from"], _selected, 0)})
		elif cnt > 1:
			premove_state_machine.change_state.call_deferred("extra", {"from": _arg["from"], "to": _selected})
	)
	premove_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		premove_state_machine.change_state.call_deferred("from")
	)
	premove_state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		premove_state_machine.change_state.call_deferred("from")
	)
	Dialog.show_cancel()
	chessboard.set_square_selection(selection)

func state_premove_to_exit() -> void:
	chessboard.set_square_selection(0)
	Dialog.hide_cancel()

func state_premove_extra_ready(_arg:Dictionary) -> void:
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
	var move_list:PackedInt32Array = Chess.generate_premove(premove_branch.future_state, player_group)
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in move_list:
		if Chess.from(iter) == _arg["from"] && Chess.to(iter) == _arg["to"]:
			decision_list.push_back(map[Chess.extra(iter)])
			decision_to_move[decision_list[-1]] = iter
	premove_state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		premove_state_machine.change_state.call_deferred("from")
	)
	premove_state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		premove_state_machine.change_state.call_deferred("confirm", {"move": decision_to_move[_selected]})
	)
	Dialog.show_cancel()
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, false)

func state_premove_extra_exit() -> void:
	Dialog.hide_cancel()
	Dialog.clear()

func state_premove_confirm_ready(_arg:Dictionary) -> void:
	premove_from = -1
	premove_to = -1
	premove_branch.move_order.push_back(_arg["move"])
	Chess.apply_move(premove_branch.future_state, _arg["move"])
	chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), Chess.from(_arg["move"]))
	chessboard.draw_pointer("premove", Color(0.639, 0.051, 0.196, 1.0), Chess.to(_arg["move"]))
	premove_state_machine.change_state.call_deferred("from")

func state_premove_stop_ready(_arg:Dictionary) -> void:
	pass

func state_ready_start(_arg:Dictionary) -> void:
	Clock.set_time(Progress.get_value("time_left", 60 * 15), 5)
	if history_name:
		history_document.new_page()
		history_document.set_state(-1, chessboard.state)
		history_document.set_sign(-1, Time.get_datetime_string_from_system(), name, tr("CHAR_YULAN"), tr("CHAR_LOTUS"), tr("CHAR_YULAN"))
	var end_type:String = Chess.get_end_type(chessboard.state)
	if end_type != "":
		state_machine.change_state.call_deferred("result")
	else:
		back_to_game()

func state_ready_engine(_arg:Dictionary) -> void:
	state_machine.state_signal_connect(engine.search_finished, func () -> void:
		assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(engine.get_search_result()))))
		state_machine.change_state.call_deferred("move", {"move": engine.get_search_result()})
	)
	if !Setting.get_value("relax"):
		engine.set_max_depth(engine_standard_think_depth)
		engine.set_think_time(engine_standard_think_time)
		engine.set_quies_enabled(false)
	else:
		engine.set_max_depth(engine_relax_think_depth)
		engine.set_think_time(engine_relax_think_time)
		engine.set_quies_enabled(true)
	engine.start_search(chessboard.state, chessboard.state.get_turn(), history_zobrist, Callable())
	if premove_state_machine.current_state == "stop" && player_group != 2 && player_group != 3:
		premove_state_machine.change_state.call_deferred("start")

func state_ready_waiting() -> void:
	state_machine.state_signal_connect(engine.search_finished, state_machine.change_state.call_deferred.bind("engine"))
	engine.stop_search()

func state_ready_move(_arg:Dictionary) -> void:
	Clock.pause()
	if history_name:
		history_document.push_move(-1, _arg["move"])
	history_zobrist.push_back(chessboard.state.get_zobrist())
	history_state.push_back(chessboard.state.duplicate())
	if Setting.get_value("text_to_speech"):
		var content:String = "WHITE_PLAY" if chessboard.state.get_turn() == 0 else "BLACK_PLAY"
		content = tr(content).format({"move": Localization.move_name_to_pronounce(Chess.get_move_name(chessboard.state, _arg["move"]))})
		Narrative.speak(content, false)
	if premove_state_machine.current_state == "stop" && player_group != 2 && player_group != 3:
		premove_state_machine.change_state.call_deferred("start")
	state_machine.state_signal_connect(chessboard.animation_finished, func () -> void:
		var end_type:String = Chess.get_end_type(chessboard.state)
		if end_type != "" && leave_on_end:
			state_machine.change_state.call_deferred("result")
		else:
			back_to_game()
	)
	
	assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(_arg["move"]))) 
	|| Chess.from(_arg["move"]) == Chess.to(_arg["move"]) && !chessboard.state.has_piece(Chess.from(_arg["move"])))

	history_event.push_back(chessboard.execute_move(_arg["move"]))
	move_played.emit(_arg["move"])

var available_events:Dictionary = {}

func state_ready_player(_arg:Dictionary) -> void:
	premove_state_machine.change_state("stop")
	var start_from:int = 0
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, chessboard.state.get_turn())
	for iter:int in move_list:
		start_from |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))

	state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		state_machine.change_state.call_deferred("ready_to_move", {"from": _selected})
	)
	state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		if _selected == "SELECTION_TAKE_BACK":
			await take_back()
		elif _selected == "SELECTION_LEAVE_GAME":
			state_machine.change_state("end")
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.call_deferred.bind("engine_win"))

	if Chess.get_end_type(chessboard.state) == "":
		chessboard.set_square_selection(start_from)
	else:
		chessboard.set_square_selection(0)
	show_dialog_selection("HINT_YOUR_TURN")

func show_dialog_selection(hint:String) -> void:
	var dialog_selection:PackedStringArray = []
	if history_event.size() > 1 && can_take_back:
		dialog_selection.push_back("SELECTION_TAKE_BACK")
	if can_leave:
		dialog_selection.push_back("SELECTION_LEAVE_GAME")
	Dialog.push_selection(dialog_selection, hint, false, false)

func state_exit_player() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_ready_to_move(_arg:Dictionary) -> void:
	premove_state_machine.change_state.call_deferred("stop")
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, chessboard.state.get_turn())
	var square_selection:int = 0
	var from:int = _arg["from"]
	if !chessboard.state.has_piece(from):
		state_machine.change_state("player")
		return
	var actor:Actor = chessboard.chessboard_piece.get(from, null)
	for iter:int in move_list:
		if Chess.from(iter) == from:
			square_selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	if square_selection == 0:
		back_to_game()
		return
	state_machine.state_signal_connect(chessboard.click_selection, func (_selected:int) -> void:
		state_machine.change_state.call_deferred("check_move", {"from": from, "to": _selected})
	)
	state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		if actor:
			actor.idle()
		back_to_game()
	)
	state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		if actor:
			actor.idle()
		back_to_game()
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.call_deferred.bind("engine_win"))
	state_machine.state_signal_connect(Dialog.on_select, func(_selected:String) -> void:
		available_events[_selected].on_selection.call_deferred()
	)
	Dialog.show_cancel()
	if actor:
		actor.ready_to_move()
	chessboard.set_square_selection(square_selection)

func state_exit_ready_to_move() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()
	Dialog.hide_cancel()

func state_ready_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, chessboard.state.get_turn())
	if _arg.has("from"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["from"] == Chess.from(move))
	if _arg.has("to"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["to"] == Chess.to(move))
	if _arg.has("extra"):
		move_list = Array(move_list).filter(func (move:int) -> bool: return _arg["extra"] == Chess.extra(move))
	if move_list.size() == 0:
		if premove_branch.move_order:
			premove_branch.move_order.clear()
			premove_branch.future_state = chessboard.state.duplicate()
		back_to_game()
		return
	elif move_list.size() > 1:
		state_machine.change_state.call_deferred("extra_move", {"from": from, "to": to, "move_list": move_list})
	else:
		state_machine.change_state.call_deferred("move", {"move": move_list[0]})

func state_ready_extra_move(_arg:Dictionary) -> void:
	premove_state_machine.change_state.call_deferred("stop")
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
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	var from:int = _arg["from"]
	var actor:Actor = chessboard.chessboard_piece.get(from, null)
	for iter:int in _arg["move_list"]:
		decision_list.push_back(map[Chess.extra(iter)])
		decision_to_move[decision_list[-1]] = iter
	
	state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		if actor:
			actor.idle()
		back_to_game()
	)
	state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
		state_machine.change_state.call_deferred("move", {"move": decision_to_move[_selected]})
	)
	Dialog.show_cancel()
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.call_deferred.bind("engine_win"))
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, false)

func state_exit_extra_move() -> void:
	Dialog.clear()
	Dialog.hide_cancel()

func state_ready_result(_arg:Dictionary) -> void:
	premove_state_machine.change_state("stop")
	var result:String = Chess.get_end_type(chessboard.state)
	if history_name:
		history_document.save_file()
	state_machine.change_state("end", {"result": result})

func state_ready_end(_arg:Dictionary) -> void:
	procedure_end.emit(_arg.get("result", ""))

func clean_history() -> void:
	history_event.clear()
	history_zobrist.clear()
	history_state.clear()

func take_back() -> void:
	if history_event.size() <= 1:
		show_dialog_selection("HINT_TAKE_BACKED")
		return
	chessboard.state = history_state[-2]
	chessboard.set_square_selection(chessboard.state.get_bit(ord('A') if chessboard.state.get_turn() == 0 else ord('a')))
	chessboard.receive_rollback_event(history_event[-1])
	chessboard.receive_rollback_event(history_event[-2])
	history_zobrist.resize(history_zobrist.size() - 2)
	history_state.resize(history_state.size() - 2)
	history_event.resize(history_event.size() - 2)
	if history_name:
		history_document.rollback(-1, chessboard.state, 2)
	await chessboard.animation_finished
	show_dialog_selection("HINT_TAKE_BACKED")

func back_to_game() -> void:
	if is_queued_for_deletion():
		return
	if chessboard.state.get_turn() != player_group && player_group != 2 || player_group == 3:
		state_machine.change_state.call_deferred("engine")
	elif premove_branch && premove_branch.move_order.size():
		var next_premove:int = premove_branch.move_order[0]
		premove_branch.move_order.remove_at(0)
		if premove_branch.move_order.size() == 0:
			chessboard.clear_pointer("premove")
		state_machine.change_state.call_deferred("check_move", {"from": Chess.from(next_premove), "to": Chess.to(next_premove), "extra": Chess.extra(next_premove)})
	elif premove_state_machine.current_state == "to":
		state_machine.change_state.call_deferred("ready_to_move", {"from": premove_from})
	else:
		state_machine.change_state.call_deferred("player")

func on_tree_exiting() -> void:
	if engine.is_searching():
		engine.search_finished.connect(func() -> void:
			engine.free()
		)
		engine.stop_search()
