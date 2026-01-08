extends Node3D
class_name Level

signal level_state_changed(state:String)

var engine:ChessEngine = null	# 有可能会出现多线作战，共用同一个引擎显然不好
var chessboard:Chessboard = null
var in_battle:bool = false
var teleport:Dictionary = {}
var history_state:PackedInt64Array = []
@onready var history_document:Document = load("res://scene/history.tscn").instantiate()
var level_state:String = ""
var level_state_signal_connection:Array = []
var mutex:Mutex = Mutex.new()
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
	chessboard.set_state(state)
	for node:Node in get_children():
		if node is Actor && node.piece_type != 0:
			var by:int = Chess.to_position_int(chessboard.get_position_name(node.position))
			node.get_parent().remove_child(node)
			chessboard.add_piece_instance(node, by)
	Progress.create_if_not_exist("obtains", 0)
	Progress.create_if_not_exist("wins", 0)
	change_state("explore_idle")

func change_state(next_state:String, arg:Dictionary = {}) -> void:
	mutex.lock()
	# 涉及到信号的自动断连
	for connection:Dictionary in level_state_signal_connection:
		connection["signal"].disconnect(connection["method"])
	level_state_signal_connection.clear()
	# 执行状态退出方法
	if has_method("state_exit_" + level_state):
		call_deferred("state_exit_" + level_state)
	level_state = next_state
	call_deferred("state_ready_" + level_state, arg)
	level_state_changed.emit.call_deferred(level_state)
	mutex.unlock()

func state_signal_connect(_signal:Signal, _method:Callable) -> void:
	_signal.connect(_method)
	assert(_signal.is_connected(_method))
	level_state_signal_connection.push_back({"signal": _signal, "method": _method})

func state_ready_explore_idle(_arg:Dictionary) -> void:
	var by:int = Chess.to_x88(chessboard.state.bit_index("k".unicode_at(0))[0])
	var selection:PackedStringArray = []
	var start_from:int = chessboard.state.get_bit(ord("K")) | chessboard.state.get_bit(ord("k")) | \
						 chessboard.state.get_bit(ord("Q")) | chessboard.state.get_bit(ord("q")) | \
						 chessboard.state.get_bit(ord("R")) | chessboard.state.get_bit(ord("r")) | \
						 chessboard.state.get_bit(ord("B")) | chessboard.state.get_bit(ord("b")) | \
						 chessboard.state.get_bit(ord("N")) | chessboard.state.get_bit(ord("n")) | \
						 chessboard.state.get_bit(ord("P")) | chessboard.state.get_bit(ord("p"))
	state_signal_connect(Dialog.on_next, change_state.bind("dialog"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_ready_to_move", {"from": chessboard.selected})
	)
	if chessboard.state.get_bit("z".unicode_at(0)) & Chess.mask(Chess.to_64(by)):
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
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
	state_signal_connect(Dialog.on_next, func() -> void:
		match Dialog.selected:
			"卡牌":
				change_state("explore_select_card", {"selection": selection})
			"档案":
				Archive.open()
				change_state("explore_idle")
			"统计":
				Dialog.push_selection(["统计", "卡牌", "档案", "设置"], 
					"获得货币：%d  赢局：%d" % [Progress.get_value("obtains", 0), Progress.get_value("wins", 0)], false, false)
			"设置":
				change_state("explore_idle")
	)
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_check_move", {"from": from, "to": chessboard.selected, "move_list": move_list})
	)
	state_signal_connect(chessboard.click_empty, change_state.bind("explore_idle"))
	Dialog.push_selection(["统计", "卡牌", "档案", "设置"], "", false, false)
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
	decision_list.push_back("cancel")
	state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "cancel":
			change_state("explore_idle")
		else:
			change_state("explore_move", {"move": decision_to_move[Dialog.selected]})
	)
	Dialog.push_selection(decision_list, "请选择一个着法", true, true)

func state_ready_explore_move(_arg:Dictionary) -> void:
	state_signal_connect(chessboard.animation_finished, change_state.bind("explore_check_attack", _arg))
	chessboard.execute_move(_arg["move"])

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
	var by:int = Chess.to_x88(chessboard.state.bit_index("k".unicode_at(0))[0])
	if _arg.has("move") && Chess.to(_arg["move"]) == by && chessboard.state.get_bit("Z".unicode_at(0)) & Chess.mask(Chess.to_64(by)):
		change_state("interact", {"callback": interact_list[by][""]})
		return
	change_state("explore_idle")

func state_ready_explore_select_card(_arg:Dictionary) -> void:
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	state_signal_connect(HoldCard.selected, change_state.bind("explore_use_card", _arg))
	Dialog.push_selection(["取消"], "选择一张卡", false, false)
	HoldCard.show_card()

func state_exit_explore_select_card() -> void:
	Dialog.clear()
	HoldCard.hide_card()

func state_ready_explore_use_card(_arg:Dictionary) -> void:
	if HoldCard.selected_card.use_directly:
		change_state("explore_using_card")
		return
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("explore_using_card", {"by": chessboard.selected})
	)
	Dialog.push_selection(["取消"], "选择一个位置", false, false)
	chessboard.set_square_selection(_arg["selection"])

func state_exit_explore_use_card() -> void:
	Dialog.clear()

func state_ready_explore_using_card(_arg:Dictionary) -> void:
	var card:Card = HoldCard.selected_card
	if card.use_directly:
		card.use_card_directly()
	else:
		var by:int = _arg["by"]
		card.use_card_on_chessboard(chessboard, by)
	change_state("explore_check_attack")

func state_ready_versus_alert(_arg:Dictionary) -> void:
	state_signal_connect(Dialog.on_next, change_state.bind("versus_start"))
	Dialog.push_dialog("敌人发现了你！", "", true, true)

func state_ready_versus_start(_arg:Dictionary) -> void:
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
	chessboard.set_square_selection(0)
	state_signal_connect(engine.search_finished, func() -> void:
		change_state("versus_move", {"move": engine.get_search_result()})
	)
	engine.set_think_time(INF)
	engine.set_max_depth(6)
	engine.start_search(chessboard.state, 0, history_state, Callable())

func state_ready_versus_waiting() -> void:
	state_signal_connect(engine.search_finished, change_state.bind("versus_enemy"))
	engine.stop_search()

func state_ready_versus_move(_arg:Dictionary) -> void:
	history_document.push_move(_arg["move"])
	history_state.push_back(chessboard.state.get_zobrist())
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
		else:
			change_state("versus_player"))
	assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(_arg["move"]))))
	chessboard.execute_move(_arg["move"])

func state_ready_versus_player(_arg:Dictionary) -> void:
	var start_from:int = chessboard.state.get_bit(ord("K")) | chessboard.state.get_bit(ord("k")) | \
						 chessboard.state.get_bit(ord("Q")) | chessboard.state.get_bit(ord("q")) | \
						 chessboard.state.get_bit(ord("R")) | chessboard.state.get_bit(ord("r")) | \
						 chessboard.state.get_bit(ord("B")) | chessboard.state.get_bit(ord("b")) | \
						 chessboard.state.get_bit(ord("N")) | chessboard.state.get_bit(ord("n")) | \
						 chessboard.state.get_bit(ord("P")) | chessboard.state.get_bit(ord("p"))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("versus_ready_to_move", {"from": chessboard.selected})
	)
	chessboard.set_square_selection(start_from)

func state_ready_versus_ready_to_move(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, 1)
	var selection:int = 0
	var from:int = _arg["from"]
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
	state_signal_connect(chessboard.click_selection, func () -> void:
		change_state("versus_check_move", {"from": from, "to": chessboard.selected, "move_list": move_list})
	)
	state_signal_connect(chessboard.click_empty, change_state.bind("versus_player"))
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
	decision_list.push_back("cancel")
	state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "cancel":
			change_state("versus_player")
		else:
			change_state("versus_move", {"move": decision_to_move[Dialog.selected]})
	)
	Dialog.push_selection(decision_list, "请选择一个着法", true, true)

func state_ready_black_win(_arg:Dictionary) -> void:
	history_document.save_file()
	var bit:int = chessboard.state.get_bit(ord("K")) | \
				  chessboard.state.get_bit(ord("Q")) | \
				  chessboard.state.get_bit(ord("R")) | \
				  chessboard.state.get_bit(ord("B")) | \
				  chessboard.state.get_bit(ord("N")) | \
				  chessboard.state.get_bit(ord("P"))
	while bit:
		chessboard.state.capture_piece(Chess.to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.to_x88(Chess.first_bit(bit))].captured()
		bit = Chess.next_bit(bit)
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	Progress.accumulate("wins", 1)
	Dialog.push_dialog("你赢了！", "", true, true)

func state_ready_white_win(_arg:Dictionary) -> void:
	history_document.save_file()
	var by:int = Chess.to_x88(chessboard.state.bit_index("k".unicode_at(0))[0])
	chessboard.state.capture_piece(Chess.to_x88(by))
	#chessboard.chessboard_piece[Chess.to_x88(by)].captured()
	state_signal_connect(Dialog.on_next, change_state.bind("conclude"))
	Dialog.push_dialog("你输了！", "", true, true)

func state_ready_conclude(_arg:Dictionary) -> void:
	Loading.change_scene("res://scene/conclude.tscn", {}, 1)

func state_ready_versus_draw(_arg:Dictionary) -> void:
	history_document.save_file()
	var bit:int = chessboard.state.get_bit(ord("K")) | \
				chessboard.state.get_bit(ord("Q")) | \
				chessboard.state.get_bit(ord("R")) | \
				chessboard.state.get_bit(ord("B")) | \
				chessboard.state.get_bit(ord("N")) | \
				chessboard.state.get_bit(ord("P"))
	while bit:
		chessboard.state.capture_piece(Chess.to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.to_x88(Chess.first_bit(bit))].leave()
		bit = Chess.next_bit(bit)
	state_signal_connect(Dialog.on_next, change_state.bind("explore_idle"))
	Dialog.push_dialog("平局", "", true, true)

func state_ready_dialog(_arg:Dictionary) -> void:
	var by:int = Chess.to_x88(chessboard.state.bit_index("k".unicode_at(0))[0])
	change_state("interact", {"callback": interact_list[by][Dialog.selected]})

func state_ready_interact(_arg:Dictionary) -> void:
	_arg["callback"].call()
