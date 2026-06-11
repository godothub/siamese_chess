extends Node3D

var state:State = null
var initial_state:State = null
var history_document:Document = load("res://src/doc/history.gd").new()
@onready var chessboard = $chessboard
var old_pastor:ChessEngine = OldPastorEngine.new()
var new_pastor:ChessEngine = PastorEngine.new()
var white_engine:ChessEngine = null
var black_engine:ChessEngine = null
var white_name:String = ""
var black_name:String = ""
var old_score:float = 0
var new_score:float = 0

func _ready() -> void:
	history_document.set_filename("history.engine_play.json")
	history_document.load_file()
	Player.force_set_camera($camera_3d)
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
	old_pastor.set_think_time(2)
	new_pastor.set_max_depth(20)
	new_pastor.set_think_time(2)
	play_match()

func play_match() -> void:
	while true:
		white_engine = old_pastor
		black_engine = new_pastor
		white_name = "CHAR_YULAN"
		black_name = "CHAR_LOTUS"
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
		print("score: ", old_score, ":", new_score)
		reset()
		white_engine = new_pastor
		black_engine = old_pastor
		white_name = "CHAR_LOTUS"
		black_name = "CHAR_YULAN"
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
		print("score: ", old_score, ":", new_score)
		reset()

func play_game() -> int:
	history_document.new_page()
	history_document.set_state(-1, initial_state)
	history_document.set_sign(-1, Time.get_datetime_string_from_system(), "engine play", white_name, black_name, "CHAR_SYSTEM")

	while Chess.get_end_type(state) == "":
		white_engine.start_search(state, state.get_turn(), [], Callable())
		await white_engine.search_finished
		var move:int = white_engine.get_search_result()
		
		print("--white--")
		print("principal_move: ", Chess.get_move_name(state, move))
		print("score: ", white_engine.get_score())
		print("deepest depth: ", white_engine.get_deepest_depth())
		print("deepest ply: ", white_engine.get_deepest_ply())
		print("evaluated_position: ", white_engine.get_evaluated_position())
		print("beta_cutoff: ", white_engine.get_beta_cutoff())
		print("transposition_table_cutoff: ", white_engine.get_transposition_table_cutoff())
		var move_score:Dictionary = white_engine.get_searched_move()
		var move_score_name:Dictionary = {}
		for key:int in move_score:
			var key_move:String = Chess.get_move_name(state, key)
			move_score_name[key_move] = move_score[key]
		print("searched_move: ", move_score_name)
		apply_move(move)
		history_document.push_move(-1, move)
		await get_tree().create_timer(0.1).timeout
		if Chess.get_end_type(state) != "":
			break

		print("--black--")
		black_engine.start_search(state, state.get_turn(), [], Callable())
		await black_engine.search_finished
		move = black_engine.get_search_result()
		print("principal_move: ", Chess.get_move_name(state, move))
		print("score: ", black_engine.get_score())
		print("deepest depth: ", black_engine.get_deepest_depth())
		print("deepest ply: ", black_engine.get_deepest_ply())
		print("evaluated_position: ", black_engine.get_evaluated_position())
		print("beta_cutoff: ", black_engine.get_beta_cutoff())
		print("transposition_table_cutoff: ", black_engine.get_transposition_table_cutoff())
		move_score = black_engine.get_searched_move()
		move_score_name = {}
		for key:int in move_score:
			var key_move:String = Chess.get_move_name(state, key)
			move_score_name[key_move] = move_score[key]
		print("searched_move: ", move_score_name)
		apply_move(move)
		history_document.push_move(-1, move)
		await get_tree().create_timer(0.1).timeout
	history_document.save_file()
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
