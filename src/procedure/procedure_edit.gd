extends LevelProcedure
class_name ProcedureEdit

var edit_piece:int = 0
var draw_bit:bool = false
var edit_piece_name:String = "PIECE_REMOVE"
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
			"PIECE_TERRAIN":
				Dialog.push_selection(["PIECE_BARRIER", "PIECE_BREAKABLE_BARRIER", "PIECE_WALL_RANK", "PIECE_WALL_FILE"], "HINT_EDIT", false, false)
				return
			"PIECE_WHITE_KING":
				edit_piece = ord("K")
				draw_bit = false
			"PIECE_WHITE_QUEEN":
				edit_piece = ord("Q")
				draw_bit = false
			"PIECE_WHITE_ROOK":
				edit_piece = ord("R")
				draw_bit = false
			"PIECE_WHITE_BISHOP":
				edit_piece = ord("B")
				draw_bit = false
			"PIECE_WHITE_KNIGHT":
				edit_piece = ord("N")
				draw_bit = false
			"PIECE_WHITE_PAWN":
				edit_piece = ord("P")
				draw_bit = false
			"PIECE_BLACK_KING":
				edit_piece = ord("k")
				draw_bit = false
			"PIECE_BLACK_QUEEN":
				edit_piece = ord("q")
				draw_bit = false
			"PIECE_BLACK_ROOK":
				edit_piece = ord("r")
				draw_bit = false
			"PIECE_BLACK_BISHOP":
				edit_piece = ord("b")
				draw_bit = false
			"PIECE_BLACK_KNIGHT":
				edit_piece = ord("n")
				draw_bit = false
			"PIECE_BLACK_PAWN":
				edit_piece = ord("p")
				draw_bit = false
			"PIECE_BARRIER":
				edit_piece = ord("#")
				draw_bit = false
			"PIECE_BREAKABLE_BARRIER":
				edit_piece = ord("*")
				draw_bit = false
			"PIECE_WALL_RANK":
				edit_piece = ord("|")
				draw_bit = true
			"PIECE_WALL_FILE":
				edit_piece = ord("-")
				draw_bit = true
			"PIECE_REMOVE":
				edit_piece = 0
				draw_bit = false
			"SELECTION_IMPORT_FEN":
				state_machine.change_state("edit_fen")
				return
			"SELECTION_FINISH":
				state_machine.change_state("stop", {"result": Chess.stringify(chessboard.state)})
				return
		edit_piece_name = _selected
		Dialog.push_selection(["PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_TERRAIN", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], tr("HINT_EDIT") + " " + tr("HINT_EDIT_USING").format({"piece": tr(edit_piece_name)}), false, false)
	)
	state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		state_machine.change_state("stop", {"result": "canceled"})
	)
	state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		var last_piece:int = 0
		if !draw_bit && chessboard.state.has_piece(_selected):
			var remove_instance:Actor = chessboard.chessboard_piece[_selected]
			last_piece = chessboard.state.get_piece(_selected)
			chessboard.state.capture_piece(_selected)
			chessboard.remove_piece_instance(remove_instance)
			remove_instance.queue_free()
			if last_piece == edit_piece:
				return
		if edit_piece && draw_bit && (Chess.mask(Chess.x88_to_c64(_selected)) & chessboard.state.get_bit(edit_piece)):
			var remove_instance:Actor = chessboard.get_bit_instance(edit_piece, _selected)
			chessboard.remove_bit_instance(remove_instance)
			chessboard.state.set_bit(edit_piece, chessboard.state.get_bit(edit_piece) ^ Chess.mask(Chess.x88_to_c64(_selected)))
			remove_instance.queue_free()
			return
		var new_instance:Actor = Chessboard.get_default_piece_instance(edit_piece)
		chessboard.add_child(new_instance)
		if !draw_bit:
			chessboard.state.add_piece(_selected, edit_piece)
			chessboard.add_piece_instance(new_instance, _selected)
		else:
			chessboard.state.set_bit(edit_piece, Chess.mask(Chess.x88_to_c64(_selected)) | chessboard.state.get_bit(edit_piece))
			chessboard.add_bit_instance(new_instance, edit_piece, _selected)
	)
	Dialog.push_selection(["PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_TERRAIN", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], tr("HINT_EDIT") + " " + tr("HINT_EDIT_USING").format({"piece": tr(edit_piece_name)}), false, false)
	Dialog.show_cancel()

func state_exit_edit_state() -> void:
	Dialog.hide_cancel()

func state_ready_edit_fen(_arg:Dictionary) -> void:
	var text_input_instance:TextInput = TextInput.create_text_input_instance(tr("HINT_INPUT_FEN"), "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
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
