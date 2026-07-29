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
	Terminal.connect("command_received", on_command_received)

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
			"SELECTION_FLAGS":
				Dialog.push_selection(["SELECTION_FIRST_MOVE", "SELECTION_CASTLE", "SELECTION_EN_PASSANT"], "HINT_EDIT", false, false)
				return
			"SELECTION_FIRST_MOVE":
				Dialog.push_selection(["SELECTION_WHITE_FIRST", "SELECTION_BLACK_FIRST"], "HINT_EDIT", false, false)
				return
			"SELECTION_CASTLE":
				Dialog.push_selection([
					"SELECTION_WHITE_SHORT_CASTLE_" + ("ON" if chessboard.state.get_castle() & 8 else "OFF"),
					"SELECTION_WHITE_LONG_CASTLE_" + ("ON" if chessboard.state.get_castle() & 4 else "OFF"),
					"SELECTION_BLACK_SHORT_CASTLE_" + ("ON" if chessboard.state.get_castle() & 2 else "OFF"),
					"SELECTION_BLACK_LONG_CASTLE_" + ("ON" if chessboard.state.get_castle() & 1 else "OFF")],
				"HINT_EDIT", false, false)
				return
			"SELECTION_EN_PASSANT":
				var en_passant_name:PackedStringArray = []
				if chessboard.state.get_turn() == 0:
					for i:int in range(0x30, 0x38):
						if chessboard.state.get_piece(i) == ord("p") && (!((i - 1) & 0x88) && chessboard.state.get_piece(i - 1) == ord("P") || !((i + 1) & 0x88) && chessboard.state.get_piece(i + 1) == ord("P")) && !chessboard.state.has_piece(i - 16):
							en_passant_name.push_back(Chess.x88_to_name(i - 16))
				else:
					for i:int in range(0x40, 0x48):
						if chessboard.state.get_piece(i) == ord("P") && (!((i - 1) & 0x88) && chessboard.state.get_piece(i - 1) == ord("p") || !((i + 1) & 0x88) && chessboard.state.get_piece(i + 1) == ord("p")) && !chessboard.state.has_piece(i + 16):
							en_passant_name.push_back(Chess.x88_to_name(i + 16))
				if en_passant_name.size():
					Dialog.push_selection(en_passant_name, "HINT_EDIT", false, false)
					return
			"SELECTION_WHITE_FIRST":
				chessboard.state.set_turn(0)
			"SELECTION_BLACK_FIRST":
				chessboard.state.set_turn(1)
			"SELECTION_WHITE_SHORT_CASTLE_ON":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 8)
			"SELECTION_WHITE_SHORT_CASTLE_OFF":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 8)
			"SELECTION_WHITE_LONG_CASTLE_ON":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 4)
			"SELECTION_WHITE_LONG_CASTLE_OFF":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 4)
			"SELECTION_BLACK_SHORT_CASTLE_ON":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 2)
			"SELECTION_BLACK_SHORT_CASTLE_OFF":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 2)
			"SELECTION_BLACK_LONG_CASTLE_ON":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 1)
			"SELECTION_BLACK_LONG_CASTLE_OFF":
				chessboard.state.set_castle(chessboard.state.get_castle() ^ 1)
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
			_:
				var by:int = Chess.name_to_x88(_selected)
				if by != -1:
					chessboard.state.set_en_passant(by)
		edit_piece_name = _selected
		Dialog.push_selection(["PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_TERRAIN", "SELECTION_FLAGS", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], tr("HINT_EDIT") + " " + tr("HINT_EDIT_USING").format({"piece": tr(edit_piece_name)}), false, false)
	)
	state_machine.state_signal_connect(Dialog.on_cancel, func () -> void:
		state_machine.change_state("stop", {"result": "canceled"})
	)
	state_machine.state_signal_connect(chessboard.click_empty, func (_selected:int) -> void:
		set_piece(_selected, edit_piece, draw_bit)
	)
	Dialog.push_selection(["PIECE_REMOVE", "PIECE_WHITE", "PIECE_BLACK", "PIECE_TERRAIN", "SELECTION_FLAGS", "SELECTION_IMPORT_FEN", "SELECTION_FINISH"], tr("HINT_EDIT") + " " + tr("HINT_EDIT_USING").format({"piece": tr(edit_piece_name)}), false, false)
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

func set_piece(by:int, piece:int, is_bit:bool) -> void:
	var last_piece:int = 0
	if !is_bit && chessboard.state.has_piece(by):
		var remove_instance:Actor = chessboard.chessboard_piece[by]
		last_piece = chessboard.state.get_piece(by)
		chessboard.state.capture_piece(by)
		chessboard.remove_piece_instance(remove_instance)
		remove_instance.queue_free()
		if last_piece == piece:
			return
	if piece && is_bit && (Chess.mask(Chess.x88_to_c64(by)) & chessboard.state.get_bit(piece)):
		var remove_instance:Actor = chessboard.get_bit_instance(piece, by)
		chessboard.remove_bit_instance(remove_instance)
		chessboard.state.set_bit(piece, chessboard.state.get_bit(piece) ^ Chess.mask(Chess.x88_to_c64(by)))
		remove_instance.queue_free()
		return
	if !piece:
		return
	var new_instance:Actor = Chessboard.get_default_piece_instance(piece)
	chessboard.add_child(new_instance)
	if !is_bit:
		chessboard.state.add_piece(by, piece)
		chessboard.add_piece_instance(new_instance, by)
	else:
		chessboard.state.set_bit(piece, Chess.mask(Chess.x88_to_c64(by)) | chessboard.state.get_bit(piece))
		chessboard.add_bit_instance(new_instance, piece, by)

func on_command_received(cmd:String) -> void:
	# +[棋子][坐标] 增加
	# -[坐标] 删除
	# [FEN]	读入FEN棋谱
	# y	提交
	# n 取消
	if state_machine.current_state != "edit_state":
		return
	if cmd == "y":
		state_machine.change_state("stop", {"result": Chess.stringify(chessboard.state)})
	elif cmd == "n":
		state_machine.change_state("stop", {"result": "canceled"})
	elif cmd.begins_with("first "):
		cmd = cmd.trim_prefix("first ")
		if cmd == "w":
			chessboard.state.set_turn(0)
		elif cmd == "b":
			chessboard.state.set_turn(1)
	elif cmd.begins_with("castle "):
		cmd = cmd.trim_prefix("castle ")
		var bit:int = (int(cmd.contains("K")) << 3) + (int(cmd.contains("Q")) << 2) + (int(cmd.contains("k")) << 1) + int(cmd.contains("q"))
		chessboard.state.set_castle(bit)
	elif cmd.begins_with("en passant "):
		cmd = cmd.trim_prefix("en passant ")
		var by:int = Chess.name_to_x88(cmd)
		if by == -1:
			return
		chessboard.state.set_en_passant(by)
	elif cmd.begins_with("fen "):
		cmd = cmd.trim_prefix("fen ")
		var test_state:State = Chess.parse(cmd)
		if test_state:
			chessboard.state = test_state
			chessboard.remove_piece_set()
			chessboard.add_default_piece_set()
	elif cmd.begins_with("+") && cmd.length() == 4:
		var is_bit:bool = cmd[1] == "|" || cmd[1] == "-" || cmd[1] == '.'
		var by:int = Chess.name_to_x88(cmd.substr(2))
		if by != -1:
			set_piece(by, ord(cmd[1]), is_bit)
	elif cmd.begins_with("-") && cmd.length() == 3:
		var by:int = Chess.name_to_x88(cmd.substr(1))
		if by != -1:
			set_piece(by, 0, false)
