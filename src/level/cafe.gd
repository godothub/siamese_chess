extends Level

var standard_history_zobrist:PackedInt64Array = []
var standard_history_state:Array[State] = []
var standard_history_event:Array[Dictionary] = []
@onready var standard_history_document:Document = load("res://scene/history.tscn").instantiate()
var standard_engine:ChessEngine = PastorEngine.new()
var chessboard_state:String = ""

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.convert_name_to_position(Chess.to_position_name(cheshire_by))
	$chessboard.state.add_piece(cheshire_by, ord("k"))
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	
	standard_engine.set_max_depth(6)
	standard_engine.set_think_time(INF)
	$player.force_set_camera($camera)
	$table_0/chessboard_standard.set_enabled(false)
	$pastor.play_animation("thinking")
	interact_list[0x54] = {"下棋": interact_pastor}
	title[0x54] = "玉兰"
	interact_list[0x55] = {"下棋": interact_pastor}
	title[0x55] = "玉兰"

func interact_pastor() -> void:
	var from:int = $chessboard.state.bit_index(ord("k"))[0]
	from = Chess.to_x88(from)
	if from != 0x54:
		$chessboard.execute_move(Chess.create(from, 0x54, 0))
	$chessboard.set_enabled(false)
	$table_0/chessboard_standard.set_enabled(true)
	$chessboard/pieces/cheshire.set_position($chessboard.convert_name_to_position("e2"))
	$chessboard/pieces/cheshire.play_animation("thinking")
	$player.force_set_camera($camera_chessboard)
	change_state("in_game_start")

func state_ready_in_game_start(_arg:Dictionary) -> void:
	$table_0/chessboard_standard.state = Chess.create_initial_state()
	$table_0/chessboard_standard.remove_piece_set()
	$table_0/chessboard_standard.add_default_piece_set()
	history_document.set_state($table_0/chessboard_standard.state)
	history_document.set_filename("history." + String.num_int64(Time.get_unix_time_from_system()) + ".json")
	if $table_0/chessboard_standard.state.get_turn() == 0:
		change_state("in_game_enemy")
	else:
		change_state("in_game_player")

func state_ready_in_game_enemy(_arg:Dictionary) -> void:
	$table_0/chessboard_standard.set_square_selection(0)
	state_signal_connect(engine.search_finished, func() -> void:
		change_state("in_game_move", {"move": engine.get_search_result()})
	)
	engine.set_think_time(3)
	engine.set_max_depth(20)
	engine.start_search($table_0/chessboard_standard.state, 0, standard_history_state, Callable())

func state_ready_in_game_waiting() -> void:
	state_signal_connect(engine.search_finished, change_state.bind("in_game_enemy"))
	engine.stop_search()

func state_ready_in_game_move(_arg:Dictionary) -> void:
	history_document.push_move(_arg["move"])
	standard_history_state.push_back($table_0/chessboard_standard.state.duplicate())
	standard_history_zobrist.push_back($table_0/chessboard_standard.state.get_zobrist())
	var rollback_event:Dictionary = $table_0/chessboard_standard.execute_move(_arg["move"])
	standard_history_event.push_back(rollback_event)
	if Chess.get_end_type($table_0/chessboard_standard.state) != "":
		change_state("game_end")
	elif $table_0/chessboard_standard.state.get_turn() == 0:
		change_state("in_game_enemy")
	else:
		change_state("in_game_player")

func state_ready_in_game_player(_arg:Dictionary) -> void:
	var start_from:int = $table_0/chessboard_standard.state.get_bit(ord("K")) | $table_0/chessboard_standard.state.get_bit(ord("k")) | \
						 $table_0/chessboard_standard.state.get_bit(ord("Q")) | $table_0/chessboard_standard.state.get_bit(ord("q")) | \
						 $table_0/chessboard_standard.state.get_bit(ord("R")) | $table_0/chessboard_standard.state.get_bit(ord("r")) | \
						 $table_0/chessboard_standard.state.get_bit(ord("B")) | $table_0/chessboard_standard.state.get_bit(ord("b")) | \
						 $table_0/chessboard_standard.state.get_bit(ord("N")) | $table_0/chessboard_standard.state.get_bit(ord("n")) | \
						 $table_0/chessboard_standard.state.get_bit(ord("P")) | $table_0/chessboard_standard.state.get_bit(ord("p"))
	state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "悔棋":
			if standard_history_event.size() <= 1:
				Dialog.push_selection(["离开对局"], "已回退", false, false)
				return
			$table_0/chessboard_standard.state = standard_history_state[-2]
			$table_0/chessboard_standard.set_square_selection(
				$table_0/chessboard_standard.state.get_bit(ord("k")) |
				$table_0/chessboard_standard.state.get_bit(ord("q")) |
				$table_0/chessboard_standard.state.get_bit(ord("r")) |
				$table_0/chessboard_standard.state.get_bit(ord("b")) |
				$table_0/chessboard_standard.state.get_bit(ord("n")) |
				$table_0/chessboard_standard.state.get_bit(ord("p"))
			)
			$table_0/chessboard_standard.receive_rollback_event(standard_history_event[-1])
			$table_0/chessboard_standard.receive_rollback_event(standard_history_event[-2])
			standard_history_zobrist.resize(standard_history_zobrist.size() - 2)
			standard_history_state.resize(standard_history_state.size() - 2)
			standard_history_event.resize(standard_history_event.size() - 2)
			history_document.rollback($table_0/chessboard_standard.state, 2)
			await $table_0/chessboard_standard.animation_finished
			if standard_history_event.size() <= 1:
				Dialog.push_selection(["离开对局"], "已回退", false, false)
			else:
				Dialog.push_selection(["悔棋", "离开对局"], "已回退", false, false)
		elif Dialog.selected == "离开对局":
			change_state("game_end")
	)
	state_signal_connect($table_0/chessboard_standard.click_selection, func () -> void:
		change_state("in_game_ready_to_move", {"from": $table_0/chessboard_standard.selected})
	)

	if standard_history_event.size() <= 1:
		Dialog.push_selection(["离开对局"], "轮到你了", false, false)
	else:
		Dialog.push_selection(["悔棋", "离开对局"], "轮到你了", false, false)
	$table_0/chessboard_standard.set_square_selection(start_from)

func state_exit_in_game_player() -> void:
	Dialog.clear()

func state_ready_in_game_ready_to_move(_arg:Dictionary) -> void:
	var move_list:PackedInt32Array = Chess.generate_valid_move($table_0/chessboard_standard.state, 1)
	var selection:int = 0
	var from:int = _arg["from"]
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.to_64(Chess.to(iter)))
	state_signal_connect($table_0/chessboard_standard.click_selection, func () -> void:
		change_state("in_game_check_move", {"from": from, "to": $table_0/chessboard_standard.selected, "move_list": move_list})
	)
	state_signal_connect($table_0/chessboard_standard.click_empty, change_state.bind("in_game_player"))
	$table_0/chessboard_standard.set_square_selection(selection)

func state_ready_in_game_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var move_list:PackedInt32Array = Array(_arg["move_list"]).filter(func (move:int) -> bool: return from == Chess.from(move) && to == Chess.to(move))
	if move_list.size() == 0:
		change_state("in_game_player", {})
		return
	elif move_list.size() > 1:
		change_state("in_game_extra_move", {"move_list": move_list})
	else:
		change_state("in_game_move", {"move": move_list[0]})

func state_ready_in_game_extra_move(_arg:Dictionary) -> void:
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in _arg["move_list"]:
		decision_list.push_back("%c" % Chess.extra(iter))
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("cancel")
	state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "cancel":
			change_state("in_game_player")
		else:
			change_state("in_game_move", {"move": decision_to_move[Dialog.selected]})
	)
	Dialog.push_selection(decision_list, "请选择一个着法", true, true)

func state_ready_game_end(_arg:Dictionary) -> void:
	history_document.save_file()
	match Chess.get_end_type($table_0/chessboard_standard.state):
		"checkmate_black":
			Dialog.push_dialog("黑方胜", "", true, true)
			await Dialog.on_next
		"checkmate_white":
			Dialog.push_dialog("白方胜", "", true, true)
			await Dialog.on_next
		"stalemate_black":
			Dialog.push_dialog("平局", "", true, true)
			await Dialog.on_next
		"stalemate_white":
			Dialog.push_dialog("平局", "", true, true)
			await Dialog.on_next
		"50_moves":
			Dialog.push_dialog("平局", "", true, true)
			await Dialog.on_next
	$player.force_set_camera($camera)
	$chessboard/pieces/cheshire.play_animation("battle_idle")
	$chessboard/pieces/cheshire.set_position($chessboard.convert_name_to_position("e3"))
	$chessboard.set_enabled(true)
	$table_0/chessboard_standard.set_enabled(false)
	change_state("explore_idle")
