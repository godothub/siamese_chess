extends Level

var standard_history_zobrist:PackedInt64Array = []
var standard_history_state:Array[State] = []
var standard_history_event:Array[Dictionary] = []
@onready var standard_history_document:Document = load("res://src/doc/history.gd").new()
@onready var standard_chessboard:Chessboard = $table_0/chessboard_standard
var standard_player_group:int = 0

func _ready() -> void:
	super._ready()
	standard_history_document.set_filename("history.match_with_yulan.json")
	standard_history_document.load_file()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	
	standard_chessboard.set_enabled(false)
	$player.add_inspectable_item(standard_chessboard)
	$pastor.play_animation("thinking")
	standard_state_machine.add_state("edit_state", state_ready_in_game_edit_state)
	standard_state_machine.add_state("edit_fen", state_ready_in_game_edit_fen)
	standard_state_machine.add_state("edit_turn", state_ready_in_game_edit_turn)

func interact_pastor() -> void:
	level.change_state("yulan_game")
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

func state_ready_end(_arg:Dictionary) -> void:
	standard_history_document.save_file()
	$player.force_set_camera($camera)
	$chessboard/pieces/cheshire.play_animation("battle_idle")
	$chessboard/pieces/cheshire.set_position($chessboard.name_to_vector3("e3"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")
