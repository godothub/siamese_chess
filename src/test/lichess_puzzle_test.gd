extends Control

# 由于谜题数量大，测试量也比较大，故通过爬虫形式获取谜题，交给自己的引擎来解答
var engine:PastorEngine = PastorEngine.new()

func _ready() -> void:
	$http_request.connect("request_completed", on_request_completed)
	$http_request.request("https://lichess.org/api/puzzle/batch/mixed?difficulty=easy&nb=5")

func on_request_completed(_result:int, _response_code:int, _headers:PackedStringArray, _body:PackedByteArray) -> void:
	var json:Dictionary = JSON.parse_string(_body.get_string_from_utf8())
	var puzzles:Array = json["puzzles"]
	for puzzle:Dictionary in puzzles:
		var state:State = Chess.create_initial_state()
		var pgn:String = puzzle["game"]["pgn"]
		var pgn_splited:PackedStringArray = pgn.split(" ", false)
		for iter:String in pgn_splited:
			var move:int = Chess.name_to_move(state, iter)
			Chess.apply_move(state, move)
			$chessboard_flat.set_state(state)
			assert(move != -1)	# 以防某种记谱形式无法识别
		print(puzzle)	# 调试方便起见输出数据包
		print(state.print_board())
		await solve_puzzle(state, puzzle["puzzle"]["solution"])

func solve_puzzle(state:State, correct_answer:PackedStringArray) -> void:
	for iter:String in correct_answer:
		engine.set_max_depth(6)
		engine.set_think_time(INF)
		engine.start_search(state, state.get_turn(), [])
		await engine.search_finished

		var my_move:int = engine.get_search_result()
		var my_move_str:String = Chess.get_move_name(state, my_move)
		var correct_move:int = Chess.uci_to_move(iter, state.get_turn())
		var correct_move_str:String = Chess.get_move_name(state, correct_move)
		var my_move_state:State = state.duplicate()
		var correct_move_state:State = state.duplicate()
		
		print("principal_move: ", Chess.get_move_name(state, my_move))
		print("score: ", engine.get_score())
		print("deepest depth: ", engine.get_deepest_depth())
		print("deepest ply: ", engine.get_deepest_ply())
		print("evaluated_position: ", engine.get_evaluated_position())
		print("beta_cutoff: ", engine.get_beta_cutoff())
		print("transposition_table_cutoff: ", engine.get_transposition_table_cutoff())

		var move_score:Dictionary = engine.get_searched_move()
		var move_score_name:Dictionary = {}
		for key:int in move_score:
			var key_move:String = Chess.get_move_name(state, key)
			move_score_name[key_move] = move_score[key]
		print("searched_move: ", move_score_name)
		
		Chess.apply_move(my_move_state, my_move)
		Chess.apply_move(correct_move_state, correct_move)
		$chessboard_flat.set_state(my_move_state)
		if my_move != correct_move:
			printerr("Wrong Answer, your move is: ", my_move_str)
			await get_tree().create_timer(5).timeout
			$chessboard_flat.set_state(correct_move_state)
			printerr("Correct Answer is: ", correct_move_str)
			await get_tree().create_timer(5).timeout
			state = correct_move_state
			continue
		print("Correct, move is: ", correct_move_str)
		state = correct_move_state
		await get_tree().create_timer(5).timeout
