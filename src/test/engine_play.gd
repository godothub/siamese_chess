extends Node3D

var state:State = null
var initial_state:State = null
@onready var chessboard = $chessboard
var old_pastor:ChessEngine = OldPastorEngine.new()
var new_pastor:ChessEngine = PastorEngine.new()
var white_engine:ChessEngine = null
var black_engine:ChessEngine = null
var old_score:float = 0
var new_score:float = 0

func _ready() -> void:
	$player.force_set_camera($camera_3d)
	chessboard.set_enabled(true)
	while !is_instance_valid(state):
		var text_input_instance:TextInput = TextInput.create_text_input_instance("输入FEN格式的布局：", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
		add_child(text_input_instance)
		await text_input_instance.confirmed
		state = Chess.parse(text_input_instance.text)
	initial_state = state.duplicate()
	chessboard.set_state(state.duplicate())
	chessboard.add_default_piece_set()
	old_pastor.set_max_depth(20)
	old_pastor.set_quies(false)
	old_pastor.set_think_time(5)
	new_pastor.set_max_depth(20)
	new_pastor.set_quies(false)
	new_pastor.set_think_time(5)
	play_match()

func play_match() -> void:
	while true:
		white_engine = old_pastor
		black_engine = new_pastor
		var result:int = await play_game()
		if result == 1:
			print("old pastor win")
			old_score += 1
		elif result == -1:
			print("new pastor win")
			new_score += 1
		else:
			print("draw")
			old_score += 0.5
			new_score += 0.5
		print(old_score, ":", new_score)
		reset()
		white_engine = new_pastor
		black_engine = old_pastor
		result = await play_game()
		if result == 1:
			print("new pastor win")
			new_score += 1
		elif result == -1:
			print("old pastor win")
			old_score += 1
		else:
			old_score += 0.5
			new_score += 0.5
		print(old_score, ":", new_score)
		reset()

func play_game() -> int:
	while Chess.get_end_type(state) == "":
		white_engine.start_search(state, state.get_turn(), [], Callable())
		await white_engine.search_finished
		var move:int = white_engine.get_search_result()
		apply_move(move)
		await get_tree().create_timer(0.1).timeout
		if Chess.get_end_type(state) != "":
			break
		black_engine.start_search(state, state.get_turn(), [], Callable())
		await black_engine.search_finished
		move = black_engine.get_search_result()
		apply_move(move)
		await get_tree().create_timer(0.1).timeout
	var result:String = Chess.get_end_type(state)
	print("result:" + result)
	if result == "checkmate_white":
		return 1
	if result == "checkmate_black":
		return -1
	return 0

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey && event.is_pressed() && event.keycode == KEY_R:
		reset()

func apply_move(move:int) -> void:
	chessboard.execute_move(move)
	Chess.apply_move(state, move)

func reset() -> void:
	state = initial_state.duplicate()
	chessboard.set_state(initial_state)
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()
