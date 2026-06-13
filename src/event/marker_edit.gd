extends MarkerProcedure
class_name MarkerEdit

var edit_piece:int = 0
var state_machine:StateMachine = StateMachine.new()
@export var chessboard:Chessboard = null

func _ready() -> void:
	state_machine.add_state("edit_state", state_ready_edit_state, state_exit_edit_state)
	state_machine.add_state("edit_fen", state_ready_edit_fen)
	state_machine.add_state("stop", state_ready_stop)

func start() -> void:
	state_machine.change_state("edit_state")

func state_ready_edit_state(_arg:Dictionary) -> void:
	state_machine.state_signal_connect(Dialog.on_select, func (_selected:String) -> void:
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
				state_machine.change_state("edit_fen")
				return
			"SELECTION_FINISH":
				state_machine.change_state("stop", {"result": "finished"})
				return
		Dialog.push_selection(["PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_NEUTRAL", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], "HINT_EDIT", false, false)
	)
	state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		state_machine.change_state("stop", {"result": "canceled"})
	)
	state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		if chessboard.state.has_piece(_selected):
			chessboard.state.capture_piece(_selected)
			chessboard.remove_piece_instance(chessboard.chessboard_piece[_selected])
		if edit_piece:
			chessboard.state.add_piece(_selected, edit_piece)
			chessboard.add_piece_instance(Chessboard.get_default_piece_instance(edit_piece), _selected)
	)
	Dialog.push_selection(["PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_NEUTRAL", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], "HINT_EDIT", false, false)
	Dialog.show_cancel()

func state_exit_edit_state() -> void:
	Dialog.hide_cancel()

func state_ready_edit_fen(_arg:Dictionary) -> void:
	var text_input_instance:TextInput = TextInput.create_text_input_instance("输入FEN格式的布局：", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	add_child(text_input_instance)
	state_machine.state_signal_connect(text_input_instance.confirmed, func(text:String) -> void:
		var test_state:State = Chess.parse(text)
		if test_state:
			chessboard.state = test_state
			chessboard.remove_piece_set()
			chessboard.add_default_piece_set()
		else:
			Toast.create_instance("HINT_ILLEGAL_FORMAT")
		state_machine.change_state("edit_state")
	)

func state_ready_stop(_arg:Dictionary) -> void:
	procedure_end.emit(_arg.get("result", ""))
