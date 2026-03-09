extends Node3D
class_name Level

var player_group:int = 0
var player_all:int = 0
var player_king:int = 0
var enemy_all:int = 0
var enemy_king:int = 0

var engine:ChessEngine = null	# 有可能会出现多线作战，共用同一个引擎显然不好
var chessboard:Chessboard = null
var in_battle:bool = false
var teleport:Dictionary = {}
var history_state:PackedInt64Array = []
@onready var history_document:Document = load("res://scene/history.tscn").instantiate()
var interact_list:Dictionary[int, Dictionary] = {}
var title:Dictionary[int, String] = {}
var state_machine:StateMachine = null

func _ready() -> void:
	player_all = ord("A") if player_group == 0 else ord("a")
	player_king = ord("K") if player_group == 0 else ord("k")
	enemy_all = ord("a") if player_group == 0 else ord("A")
	enemy_king = ord("k") if player_group == 0 else ord("K")
	engine = PastorEngine.new()
	state_machine = StateMachine.new()
	var state = State.new()
	chessboard = $chessboard
	$player.add_inspectable_item(chessboard)
	for node:Node in get_children():
		if node is MarkerActor:
			var by:int = chessboard.vector3_to_x88(node.position)
			state.add_piece(by, node.piece)
		if node is MarkerMultiActor:
			var bit:int = node.bit
			while bit:
				var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
				state.add_piece(by, node.piece)
				bit = Chess.next_bit(bit)
		if node is MarkerBit:
			state.set_bit(node.piece, state.get_bit(node.piece) | node.bit)
		if node is MarkerEvent:
			state.set_bit(ord("Z"), state.get_bit(ord("Z")) | node.bit)
			var bit:int = node.bit
			while bit:
				var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
				if !interact_list.has(by):
					interact_list[by] = {}
				interact_list[by][""] = node.event
				bit = Chess.next_bit(bit)
		if node is MarkerSelection:
			state.set_bit(ord("z"), state.get_bit(ord("z")) | node.bit)
			var bit:int = node.bit
			while bit:
				var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
				if !interact_list.has(by):
					interact_list[by] = {}
				interact_list[by][node.selection] = node.event
				title[by] = ""
				bit = Chess.next_bit(bit)
	var storage_piece:int = 0
	storage_piece += int(Progress.get_value("storage_queen", 0)) << (5 * 4)
	storage_piece += int(Progress.get_value("storage_rook", 0)) << (6 * 4)
	storage_piece += int(Progress.get_value("storage_bishop", 0)) << (7 * 4)
	storage_piece += int(Progress.get_value("storage_knight", 0)) << (8 * 4)
	storage_piece += int(Progress.get_value("storage_pawn", 0)) << (9 * 4)
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
		if node is MarkerActor:
			var by:int = chessboard.vector3_to_x88(node.position)
			var instance:Actor = node.instantiate()
			if is_instance_valid(instance):
				chessboard.add_piece_instance(instance, by)
	Progress.create_if_not_exist("obtains", 0)
	Progress.create_if_not_exist("wins", 0)
	state_machine.add_state("versus_start", state_ready_versus_start)
	state_machine.add_state("versus_enemy", state_ready_versus_enemy)
	state_machine.add_state("versus_waiting", state_ready_versus_waiting)
	state_machine.add_state("versus_move", state_ready_versus_move)
	state_machine.add_state("versus_player", state_ready_versus_player, state_exit_versus_player)
	state_machine.add_state("versus_ready_to_move", state_ready_versus_ready_to_move, state_exit_versus_ready_to_move)
	state_machine.add_state("versus_check_move", state_ready_versus_check_move)
	state_machine.add_state("versus_extra_move", state_ready_versus_extra_move)
	state_machine.add_state("versus_select_empty_square", state_ready_versus_select_empty_square)
	state_machine.add_state("versus_select_piece", state_ready_versus_select_piece)
	state_machine.add_state("player_win", state_ready_player_win)
	state_machine.add_state("enemy_win", state_ready_enemy_win)
	state_machine.add_state("conclude", state_ready_conclude)
	state_machine.add_state("draw", state_ready_draw)
	state_machine.add_state("dialog", state_ready_dialog)
	state_machine.add_state("interact", state_ready_interact)
	state_machine.change_state("versus_start")

var premove_from:int = -1
var premove_to:int = -1

func premove_init() -> void:
	if premove_from == -1:
		var start_from:int = chessboard.state.get_bit(player_all)
		chessboard.set_square_selection(start_from)
	elif premove_to == -1:
		var move_list:PackedInt32Array = Chess.generate_premove(chessboard.state, 1) if chessboard.state.get_bit(enemy_all) else Chess.generate_explore_move(chessboard.state, player_group)
		var selection:int = 0
		for iter:int in move_list:
			if Chess.from(iter) == premove_from:
				selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
		chessboard.set_square_selection(selection)

func premove_pressed() -> void:
	var start_from:int = chessboard.state.get_bit(player_all)
	if premove_from == -1 || premove_to != -1:
		premove_to = -1
		chessboard.clear_pointer("premove")
		var move_list:PackedInt32Array = Chess.generate_premove(chessboard.state, 1) if chessboard.state.get_bit(enemy_all) else Chess.generate_explore_move(chessboard.state, player_group)
		var selection:int = 0
		premove_from = chessboard.selected
		for iter:int in move_list:
			if Chess.from(iter) == premove_from:
				selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
		chessboard.set_square_selection(selection)
	else:
		premove_to = chessboard.selected
		chessboard.draw_pointer("premove", Color(0.64, 0.051, 0.198, 1.0), premove_from, 1)
		chessboard.draw_pointer("premove", Color(0.639, 0.051, 0.196, 1.0), premove_to, 1)
		chessboard.set_square_selection(start_from)

func premove_cancel() -> void:
	var start_from:int = chessboard.state.get_bit(player_all)
	premove_from = -1
	premove_to = -1
	chessboard.clear_pointer("premove")
	chessboard.set_square_selection(start_from)

func state_ready_versus_start(_arg:Dictionary) -> void:
	Clock.set_time(Progress.get_value("time_left", 60 * 15), 5)
	chessboard.state.set_turn(0)
	chessboard.state.set_castle(0xF)
	chessboard.state.set_step_to_draw(0)
	chessboard.state.set_round(1)
	history_document.set_state(chessboard.state)
	history_document.set_filename("history." + String.num_int64(Time.get_unix_time_from_system()) + ".json")
	if Chess.get_end_type(chessboard.state) == "checkmate_black":
		state_machine.change_state("player_win")
	elif Chess.get_end_type(chessboard.state) == "checkmate_white":
		state_machine.change_state("enemy_win")
	elif chessboard.state.get_bit(ord("Z")) & chessboard.state.get_bit(player_king):
		state_machine.change_state("interact", {"callback": interact_list[Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))][""]})
	elif chessboard.state.get_turn() != player_group:
		state_machine.change_state("versus_enemy")
	else:
		state_machine.change_state("versus_player")

func state_ready_versus_enemy(_arg:Dictionary) -> void:
	if !chessboard.state.get_bit(enemy_all):
		state_machine.change_state("versus_move", {"move": -1})
		return
	state_machine.state_signal_connect(chessboard.click_selection, premove_pressed)
	state_machine.state_signal_connect(chessboard.click_empty, premove_cancel)
	state_machine.state_signal_connect(engine.search_finished, func() -> void:
		assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(engine.get_search_result()))))
		state_machine.change_state("versus_move", {"move": engine.get_search_result()})
	)
	if !Setting.get_value("relax"):
		engine.set_max_depth(20)
		engine.set_quies(false)
	else:
		engine.set_max_depth(2)
		engine.set_quies(true)
	engine.set_think_time(2)
	engine.start_search(chessboard.state, 1 - player_group, history_state, Callable())
	premove_init()

func state_ready_versus_waiting() -> void:
	state_machine.state_signal_connect(engine.search_finished, state_machine.change_state.bind("versus_enemy"))
	engine.stop_search()

func state_ready_versus_move(_arg:Dictionary) -> void:
	Clock.pause()
	history_document.push_move(_arg["move"])
	history_document.save_file()
	history_state.push_back(chessboard.state.get_zobrist())

	state_machine.state_signal_connect(chessboard.click_selection, premove_pressed)
	state_machine.state_signal_connect(chessboard.click_empty, premove_cancel)
	state_machine.state_signal_connect(chessboard.animation_finished, func() -> void:
		var end_type:String = Chess.get_end_type(chessboard.state)
		if end_type == "checkmate_black":
			state_machine.change_state("player_win")
		elif end_type == "checkmate_white":
			state_machine.change_state("enemy_win")
		elif end_type == "stalemate_black":
			state_machine.change_state("draw")
		elif end_type == "stalemate_white":
			state_machine.change_state("draw")
		#elif end_type == "not_enough_piece":
		#	state_machine.change_state("draw")
		elif chessboard.state.get_turn() != player_group && chessboard.state.get_bit(enemy_all):
			state_machine.change_state("versus_enemy")
		elif premove_from != -1 && premove_to != -1:
			chessboard.clear_pointer("premove")
			state_machine.change_state("versus_check_move", {"from": premove_from, "to": premove_to, "move_list": Chess.generate_valid_move(chessboard.state, player_group) if chessboard.state.get_bit(enemy_all) else Chess.generate_explore_move(chessboard.state, player_group)})
			premove_from = -1
			premove_to = -1
		elif chessboard.state.get_bit(ord("Z")) & Chess.mask(Chess.x88_to_c64(Chess.to(_arg["move"]))):
			state_machine.change_state("interact", {"callback": interact_list[Chess.to(_arg["move"])][""]})
		elif premove_from != -1 && (chessboard.mouse_hold || chessboard.button_input_hold):
			state_machine.change_state("versus_ready_to_move", {"from": premove_from})
			premove_from = -1
			premove_to = -1
		else:
			state_machine.change_state("versus_player")
			premove_from = -1
			premove_to = -1
	)
	
	assert(chessboard.state.get_turn() == Chess.group(chessboard.state.get_piece(Chess.from(_arg["move"]))) 
	|| Chess.from(_arg["move"]) == Chess.to(_arg["move"]) && !chessboard.state.has_piece(Chess.from(_arg["move"])))
	chessboard.execute_move(_arg["move"])
	premove_init()

func state_ready_versus_player(_arg:Dictionary) -> void:
	var start_from:int = 0
	var can_introduce:bool = false
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, player_group)
	for iter:int in move_list:
		if Chess.from(iter) == Chess.to(iter):
			can_introduce = true
		else:
			start_from |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))

	state_machine.state_signal_connect(chessboard.click_selection, func () -> void:
		state_machine.change_state("versus_ready_to_move", {"from": chessboard.selected})
	)
	if can_introduce:
		state_machine.state_signal_connect(chessboard.empty_double_click, func () -> void:
			state_machine.change_state("versus_select_piece", {"by": chessboard.selected})
		)
	state_machine.state_signal_connect(Dialog.on_next, state_machine.change_state.bind("dialog"))
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.bind("enemy_win"))
	if chessboard.state.get_bit(enemy_all):
		Clock.resume()
	chessboard.clear_pointer("premove")
	premove_from = -1
	premove_to = -1
	var by:int = Chess.c64_to_x88(Chess.first_bit(chessboard.state.get_bit(player_king)))
	var selection:PackedStringArray = []
	if chessboard.state.get_bit(ord("z")) & Chess.mask(Chess.x88_to_c64(by)):
		selection = interact_list[by].keys()
		Dialog.push_selection(selection, title[by], false, false)
	chessboard.set_square_selection(start_from)

func state_exit_versus_player() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_versus_ready_to_move(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, player_group) if chessboard.state.get_bit(enemy_all) else Chess.generate_explore_move(chessboard.state, player_group)
	var selection:int = 0
	var dialog_selection:PackedStringArray = []
	var introduce_selection:int = 0
	var from:int = _arg["from"]
	var from_piece:int = chessboard.state.get_piece(from)
	var actor:Actor = chessboard.chessboard_piece[from]
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
		if Chess.from(iter) == Chess.to(iter):
			introduce_selection |= Chess.mask(Chess.x88_to_c64(Chess.from(iter)))
	if selection == 0:
		state_machine.change_state("versus_player")
		return
	state_machine.state_signal_connect(chessboard.click_selection, func () -> void:
		state_machine.change_state("versus_check_move", {"from": from, "to": chessboard.selected, "move_list": move_list})
	)
	state_machine.state_signal_connect(chessboard.click_empty, func () -> void:
		actor.idle()
		state_machine.change_state("versus_player")
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.bind("enemy_win"))
	state_machine.state_signal_connect(Dialog.on_next, func() -> void:
		match Dialog.selected:
			"SELECTION_PIECES":
				state_machine.change_state("versus_select_empty_square", {"selection": introduce_selection})
			"SELECTION_DOCUMENTS":
				Archive.open()
				state_machine.change_state("versus_player")
			"SELECTION_STATUS":
				Dialog.push_selection(["SELECTION_STATUS", "SELECTION_PIECES", "SELECTION_CAMERA", "SELECTION_THIRD_EYE", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS"], 
					tr("HINT_STATUS") % [Progress.get_value("obtains", 0), Progress.get_value("wins", 0)], false, false)
			"SELECTION_CAMERA":
				var from_position:Vector3 = chessboard.chessboard_piece[from].global_position
				from_position += Vector3(0, 1.6, 0)
				var from_rotation:Vector3 = chessboard.chessboard_piece[from].global_rotation
				Photo.move_camera(from_position, from_rotation)
				Photo.open()
				state_machine.change_state("versus_player")
			"SELECTION_THIRD_EYE":
				ThirdEye3D.set_pov($player.get_camera())
				ThirdEye3D.set_state(chessboard.state)
				ThirdEye3D.open()
				state_machine.change_state("versus_player")
			"SELECTION_SETTINGS":
				Setting.open()
				state_machine.change_state("versus_player")
			"SELECTION_CANCEL":
				state_machine.change_state("versus_player")
	)
	if from_piece == player_king:
		if introduce_selection:
			Dialog.push_selection(["SELECTION_STATUS", "SELECTION_PIECES", "SELECTION_CAMERA", "SELECTION_THIRD_EYE", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS", "SELECTION_CANCEL"], "", false, false)
		else:
			Dialog.push_selection(["SELECTION_STATUS", "SELECTION_CAMERA", "SELECTION_THIRD_EYE", "SELECTION_DOCUMENTS", "SELECTION_SETTINGS", "SELECTION_CANCEL"], "", false, false)
	else:
		Dialog.push_selection(["SELECTION_CANCEL"], "", false, false)
		Dialog.push_selection(dialog_selection, "", false, false)
	actor.ready_to_move()
	chessboard.set_square_selection(selection)

func state_exit_versus_ready_to_move() -> void:
	chessboard.set_square_selection(0)
	Dialog.clear()

func state_ready_versus_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var move_list:PackedInt32Array = Array(_arg["move_list"]).filter(func (move:int) -> bool: return from == Chess.from(move) && to == Chess.to(move))
	if move_list.size() == 0:
		state_machine.change_state("versus_player", {})
		return
	elif move_list.size() > 1:
		state_machine.change_state("versus_extra_move", {"move_list": move_list})
	else:
		state_machine.change_state("versus_move", {"move": move_list[0]})

func state_ready_versus_extra_move(_arg:Dictionary) -> void:
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in _arg["move_list"]:
		decision_list.push_back("%c" % Chess.extra(iter))
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("SELECTION_CANCEL")
	state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "SELECTION_CANCEL":
			state_machine.change_state("versus_player")
		else:
			state_machine.change_state("versus_move", {"move": decision_to_move[Dialog.selected]})
	)
	state_machine.state_signal_connect(Clock.timeout, state_machine.change_state.bind("enemy_win"))
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, true)

func state_ready_versus_select_empty_square(_arg:Dictionary) -> void:
	state_machine.state_signal_connect(Dialog.on_next, state_machine.change_state.bind("versus_player"))
	state_machine.state_signal_connect(chessboard.click_selection, func () -> void:
		state_machine.change_state("versus_select_piece", {"by": chessboard.selected})
	)
	Dialog.push_selection(["SELECTION_CANCEL"], "HINT_SELECT_SQUARE", false, false)
	chessboard.set_square_selection(_arg["introduce_selection"])

func state_ready_versus_select_piece(_arg:Dictionary) -> void:
	var storage_piece:int = chessboard.state.get_storage_piece()
	var by:int = _arg["by"]
	var start_from:int = chessboard.state.get_bit(player_all)

	var move_valid:bool = false
	var move_list:PackedInt32Array = Chess.generate_valid_move(chessboard.state, player_group)
	var pawn_available:bool = false 
	for iter:int in move_list:
		if Chess.from(iter) == Chess.to(iter) && Chess.from(iter) == by:
			move_valid = true
			if Chess.extra(iter) & 95 == ord("P"):
				pawn_available = true
	if !move_valid:
		state_machine.change_state("versus_player")
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
	if ((storage_piece >> (9 * 4)) & 0xF) && pawn_available:
		selection.push_back("PIECE_PAWN")
	selection.push_back("SELECTION_CANCEL")
	state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		match Dialog.selected:
			"SELECTION_CANCEL":
				state_machine.change_state("versus_player")
			"PIECE_QUEEN":
				state_machine.change_state("versus_move", {"move": Chess.create(by, by, ord("q"))})
			"PIECE_ROOK":
				state_machine.change_state("versus_move", {"move": Chess.create(by, by, ord("r"))})
			"PIECE_BISHOP":
				state_machine.change_state("versus_move", {"move": Chess.create(by, by, ord("b"))})
			"PIECE_KNIGHT":
				state_machine.change_state("versus_move", {"move": Chess.create(by, by, ord("n"))})
			"PIECE_PAWN":
				state_machine.change_state("versus_move", {"move": Chess.create(by, by, ord("p"))})
	)
	state_machine.state_signal_connect(chessboard.empty_double_click, func () -> void:
		state_machine.change_state("versus_select_piece", {"by": chessboard.selected})
	)
	state_machine.state_signal_connect(chessboard.click_empty, state_machine.change_state.bind("versus_idle"))
	state_machine.state_signal_connect(chessboard.click_selection, func () -> void:
		state_machine.change_state("versus_ready_to_move", {"from": chessboard.selected})
	)
	Dialog.push_selection(selection, "HINT_ADD_PIECE", false, false)
	chessboard.set_square_selection(start_from)


func state_ready_player_win(_arg:Dictionary) -> void:
	history_document.save_file()
	Progress.set_value("time_left", Clock.get_time_left())
	var bit:int = chessboard.state.get_bit(enemy_all)
	while bit:
		chessboard.state.capture_piece(Chess.c64_to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.c64_to_x88(Chess.first_bit(bit))].captured()
		bit = Chess.next_bit(bit)
	state_machine.state_signal_connect(Dialog.on_next, state_machine.change_state.bind("versus_player"))
	Progress.accumulate("wins", 1)
	Dialog.push_dialog("HINT_YOU_WIN", "", true, true)

func state_ready_enemy_win(_arg:Dictionary) -> void:
	history_document.save_file()
	var by:int = Chess.c64_to_x88(Chess.first_bit($chessboard.state.get_bit(player_king)))
	chessboard.state.capture_piece(Chess.c64_to_x88(by))
	#chessboard.chessboard_piece[Chess.c64_to_x88(by)].captured()
	state_machine.state_signal_connect(Dialog.on_next, state_machine.change_state.bind("conclude"))
	Dialog.push_dialog("HINT_YOU_LOSE", "", true, true)

func state_ready_conclude(_arg:Dictionary) -> void:
	Loading.change_scene("res://scene/conclude.tscn", {}, 1)

func state_ready_draw(_arg:Dictionary) -> void:
	history_document.save_file()
	var bit:int = chessboard.state.get_bit(enemy_all)
	while bit:
		chessboard.state.capture_piece(Chess.c64_to_x88(Chess.first_bit(bit)))
		chessboard.chessboard_piece[Chess.c64_to_x88(Chess.first_bit(bit))].leave()
		bit = Chess.next_bit(bit)
	state_machine.state_signal_connect(Dialog.on_next, state_machine.change_state.bind("versus_player"))
	Dialog.push_dialog("平局", "", true, true)

func state_ready_dialog(_arg:Dictionary) -> void:
	var by:int = Chess.c64_to_x88(Chess.first_bit($chessboard.state.get_bit(player_king)))
	state_machine.change_state("interact", {"callback": interact_list[by][Dialog.selected]})

func state_ready_interact(_arg:Dictionary) -> void:
	_arg["callback"].call()
