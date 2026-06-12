extends Level

var history_prev:Array[State] = []
var history_next:Array[State] = []
var state:State = null
var opening_book:OpeningBook = OpeningBook.new()
@onready var text_edit_name:TextEdit = $canvas_layer/panel/v_box_container/margin_container_1/text_edit_name
@onready var text_edit_description:TextEdit = $canvas_layer/panel/v_box_container/margin_container_2/text_edit_description
@onready var text_edit_move:TextEdit = $canvas_layer/panel/v_box_container/margin_container_3/text_edit_move

func _ready() -> void:
	super._ready()
	Player.force_set_camera($camera_3d)
	if FileAccess.file_exists("user://standard_opening_document.fa"):
		opening_book.load_file("user://standard_opening_document.fa")
	$marker_game.connect("move_played", receive_move)
	$canvas_layer/panel/v_box_container/margin_container/h_box_container/button_save.connect("button_down", set_text)
	$canvas_layer/panel/v_box_container/margin_container/h_box_container/button_prev.connect("button_down", prev)
	$canvas_layer/panel/v_box_container/margin_container/h_box_container/button_next.connect("button_down", next)
	
	state = Chess.parse("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	chessboard.set_state(state.duplicate())
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()
	history_prev.push_back(state.duplicate());
	get_text()
	$marker_game.start()

func receive_move(move:int) -> void:
	Chess.apply_move(state, move)
	get_text()
	history_prev.push_back(state.duplicate());
	history_next.clear();

func get_text() -> void:
	text_edit_name.text = opening_book.get_opening_name(state)
	text_edit_description.text = opening_book.get_opening_description(state)
	var move_list:PackedInt32Array = opening_book.get_suggest_move(state)
	var move_list_str:PackedStringArray = []
	text_edit_move.text = ""
	for iter:int in move_list:
		move_list_str.push_back(Chess.get_move_name(state, iter))
	text_edit_move.text = ",".join(move_list_str)

func set_text() -> void:
	var move_list_str:PackedStringArray = text_edit_move.text.split(",", false)
	var move_list:PackedInt32Array = []
	for iter:String in move_list_str:
		var move:int = Chess.name_to_move(state, iter)
		if move != -1:
			move_list.push_back(move)
	opening_book.set_opening(state, text_edit_name.text, text_edit_description.text, move_list)
	opening_book.save_file("user://standard_opening_document.fa")

func prev() -> void:
	if history_prev.size() <= 1:
		return
	history_next.push_back(history_prev.back())
	history_prev.pop_back()
	state = history_prev.back().duplicate()
	chessboard.set_state(state.duplicate())
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()
	get_text()

func next() -> void:
	if history_next.size() == 0:
		return
	history_prev.push_back(history_next.back())
	history_next.pop_back()
	state = history_prev.back().duplicate()
	chessboard.set_state(state.duplicate())
	chessboard.remove_piece_set()
	chessboard.add_default_piece_set()
	get_text()
