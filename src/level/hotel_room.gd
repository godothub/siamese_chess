extends Level

var sandbox_state_machine:StateMachine = StateMachine.new()
var sandbox_history_zobrist:PackedInt64Array = []
var sandbox_history_state:Array[State] = []
var sandbox_history_event:Array[Dictionary] = []
var sandbox_move_list:PackedInt32Array = []
@onready var chessboard_sandbox:Chessboard = $chessboard_sandbox

func _ready() -> void:
	super._ready()
	chessboard_sandbox.set_enabled(false)
	$player.add_inspectable_item(chessboard_sandbox)
	var cheshire_by:int = get_meta("by")
	var cheshire_instance:Actor = load("res://scene/actor/cheshire.tscn").instantiate()
	cheshire_instance.position = $chessboard.x88_to_vector3(cheshire_by)
	$chessboard.state.add_piece(cheshire_by, player_king)
	$chessboard.add_piece_instance(cheshire_instance, cheshire_by)
	chessboard.button_input_pointer = cheshire_by
	sandbox_state_machine.add_state("start", state_ready_in_game_start)
	sandbox_state_machine.add_state("move", state_ready_in_game_move)
	sandbox_state_machine.add_state("player", state_ready_in_game_player, state_exit_in_game_player)
	sandbox_state_machine.add_state("ready_to_move", state_ready_in_game_ready_to_move)
	sandbox_state_machine.add_state("check_move", state_ready_in_game_check_move)
	sandbox_state_machine.add_state("extra_move", state_ready_in_game_extra_move)
	sandbox_state_machine.add_state("game_end", state_ready_game_end)

func use_chessboard() -> void:
	state_machine.change_state("stop")
	$chessboard.set_enabled(false)
	chessboard_sandbox.set_enabled(true)
	var state:State = Chess.create_initial_state()
	sandbox_state_machine.change_state("start", {"state": state})
	$player.force_set_camera($camera_chessboard)

func state_ready_in_game_start(_arg:Dictionary) -> void:
	chessboard_sandbox.state = _arg["state"]
	chessboard_sandbox.remove_piece_set()
	chessboard_sandbox.add_default_piece_set()
	sandbox_move_list = Chess.generate_valid_move(chessboard_sandbox.state, chessboard_sandbox.state.get_turn())
	sandbox_state_machine.change_state("player")

func state_ready_in_game_move(_arg:Dictionary) -> void:
	sandbox_history_state.push_back(chessboard_sandbox.state.duplicate())
	sandbox_history_zobrist.push_back(chessboard_sandbox.state.get_zobrist())
	var rollback_event:Dictionary = chessboard_sandbox.execute_move(_arg["move"])	# 就是在这里执行的着法，别看漏了
	sandbox_history_event.push_back(rollback_event)
	sandbox_move_list = Chess.generate_valid_move(chessboard_sandbox.state, chessboard_sandbox.state.get_turn())
	sandbox_state_machine.change_state("player")

func state_ready_in_game_player(_arg:Dictionary) -> void:
	var start_from:int = chessboard_sandbox.state.get_bit(ord('A') if chessboard_sandbox.state.get_turn() == 0 else ord('a'))
	sandbox_state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "SELECTION_TAKE_BACK":
			if sandbox_history_event.size() <= 0:
				Dialog.push_selection(["SELECTION_LEAVE_GAME"], "HINT_TAKE_BACKED", false, false)
				return
			chessboard_sandbox.state = sandbox_history_state[-1]
			chessboard_sandbox.set_square_selection(chessboard_sandbox.state.get_bit(ord('A') if chessboard_sandbox.state.get_turn() == 0 else ord('a')))
			chessboard_sandbox.receive_rollback_event(sandbox_history_event[-1])
			sandbox_history_zobrist.resize(sandbox_history_zobrist.size() - 1)
			sandbox_history_state.resize(sandbox_history_state.size() - 1)
			sandbox_history_event.resize(sandbox_history_event.size() - 1)
			sandbox_move_list = Chess.generate_valid_move(chessboard_sandbox.state, chessboard_sandbox.state.get_turn())
			await chessboard_sandbox.animation_finished
			if sandbox_history_event.size() <= 0:
				Dialog.push_selection(["SELECTION_LEAVE_GAME"], "HINT_TAKE_BACKED", false, false)
			else:
				Dialog.push_selection(["SELECTION_TAKE_BACK", "SELECTION_LEAVE_GAME"], "HINT_TAKE_BACKED", false, false)
		elif Dialog.selected == "SELECTION_LEAVE_GAME":
			sandbox_state_machine.change_state("game_end")
	)
	sandbox_state_machine.state_signal_connect(chessboard_sandbox.click_selection, func (_selected:int) -> void:
		sandbox_state_machine.change_state("ready_to_move", {"from": _selected})
	)

	if sandbox_history_event.size() <= 0:
		Dialog.push_selection(["SELECTION_LEAVE_GAME"], "HINT_YOUR_TURN", false, false)
	else:
		Dialog.push_selection(["SELECTION_TAKE_BACK", "SELECTION_LEAVE_GAME"], "HINT_YOUR_TURN", false, false)
	chessboard_sandbox.set_square_selection(start_from)

func state_exit_in_game_player() -> void:
	Dialog.clear()

func state_ready_in_game_ready_to_move(_arg:Dictionary) -> void:
	var selection:int = 0
	var from:int = _arg["from"]
	var actor:Actor = chessboard_sandbox.chessboard_piece[from]
	for iter:int in sandbox_move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	sandbox_state_machine.state_signal_connect(chessboard_sandbox.click_selection, func (_selected:int) -> void:
		sandbox_state_machine.change_state("check_move", {"from": from, "to": _selected})
	)
	sandbox_state_machine.state_signal_connect(chessboard_sandbox.click_empty, func (_selected:int) -> void:
		actor.idle()
		sandbox_state_machine.change_state("player")
	)
	actor.ready_to_move()
	chessboard_sandbox.set_square_selection(selection)

func state_ready_in_game_check_move(_arg:Dictionary) -> void:
	var from:int = _arg["from"]
	var to:int = _arg["to"]
	var actor:Actor = chessboard_sandbox.chessboard_piece[from]
	var check_move_list:PackedInt32Array = Array(sandbox_move_list).filter(func (move:int) -> bool: return from == Chess.from(move) && to == Chess.to(move))
	if check_move_list.size() == 0:
		actor.idle()
		sandbox_state_machine.change_state("player", {})
		return
	elif check_move_list.size() > 1:
		sandbox_state_machine.change_state("extra_move", {"from": from, "to": to, "move_list": check_move_list})
	else:
		sandbox_state_machine.change_state("move", {"move": check_move_list[0]})

func state_ready_in_game_extra_move(_arg:Dictionary) -> void:
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
	var actor:Actor = chessboard_sandbox.chessboard_piece[from]
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in _arg["move_list"]:
		decision_list.push_back(map[Chess.extra(iter)])
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("cancel")
	sandbox_state_machine.state_signal_connect(Dialog.on_next, func () -> void:
		if Dialog.selected == "cancel":
			actor.idle()
			sandbox_state_machine.change_state("player")
		else:
			sandbox_state_machine.change_state("move", {"move": decision_to_move[Dialog.selected]})
	)
	Dialog.push_selection(decision_list, "HINT_EXTRA_MOVE", true, true)

func state_ready_game_end(_arg:Dictionary) -> void:
	$chessboard.set_enabled(true)
	chessboard_sandbox.set_enabled(false)
	$player.force_set_camera($marker_camera_2/camera)
	state_machine.change_state("resume")
