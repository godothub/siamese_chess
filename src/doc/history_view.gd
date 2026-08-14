extends NotableView
class_name HistoryView

var current_move:int = 0
var state_list:Array[State] = []

static var regex_fen:RegEx = RegEx.create_from_string("(?i:^\\s*fen\\s*$)")
static var regex_board:RegEx = RegEx.create_from_string("(?i:^\\s*board\\s*$)")
static var regex_initial_board:RegEx = RegEx.create_from_string("(?i:^\\s*initial\\s*board\\s*$)")
static var regex_next_move:RegEx = RegEx.create_from_string("(?i:^\\s*(next\\s*move)\\s*$)")
static var regex_prev_move:RegEx = RegEx.create_from_string("(?i:^\\s*(prev\\s*move)\\s*$)")
static var regex_next_page:RegEx = RegEx.create_from_string("(?i:^\\s*(next\\s*page)\\s*$)")
static var regex_prev_page:RegEx = RegEx.create_from_string("(?i:^\\s*(prev\\s*page)\\s*$)")

func _ready() -> void:
	for i:int in range(60):
		get_node("history/white/label_%d" % (i + 1)).connect("gui_input", press_move.bind(i * 2))
		get_node("history/black/label_%d" % (i + 1)).connect("gui_input", press_move.bind(i * 2 + 1))

func set_document(_document:Document) -> void:
	assert(_document is History)
	if document:
		document.disconnect("content_changed", update_table)
	super.set_document(_document)
	_document.connect("content_changed", update_table)
	update_table()

func open() -> void:
	super.open()

func close() -> void:
	super.close()

func update_table() -> void:
	$history/chessboard_flat.set_state(document.page_list[page_index].initial_state)
	$history/label_date_value.text = tr(document.page_list[page_index].date)
	$history/label_event_value.text = tr(document.page_list[page_index].event)
	$history/label_white_value.text = tr(document.page_list[page_index].white)
	$history/label_black_value.text = tr(document.page_list[page_index].black)
	$history/label_recorder_value.text = tr(document.page_list[page_index].recorder)
	state_list.clear()
	for i:int in range(60):
		get_node("history/white/label_%d" % (i + 1)).text = ""
		get_node("history/black/label_%d" % (i + 1)).text = ""
	var test_state:State = document.page_list[page_index].initial_state.duplicate()
	for i:int in range(document.page_list[page_index].history.size()):
		Chess.apply_move(test_state, document.page_list[page_index].history_raw[i])
		state_list.push_back(test_state.duplicate())
		if i % 2 == 0:
			get_node("history/white/label_%d" % (i / 2 + 1)).text = document.page_list[page_index].history[i]
		else:
			get_node("history/black/label_%d" % (i / 2 + 1)).text = document.page_list[page_index].history[i]

func turn_page(_page:int) -> void:
	super.turn_page(_page)
	update_table()

func read_label(label:Label) -> void:
	Narrative.speak(label.text, true)

func press_move(event:InputEvent, index:int) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		if state_list.size() > index:
			$history/chessboard_flat.set_state(state_list[index])

func on_command_received(cmd:String) -> void:
	super.on_command_received(cmd)
	if regex_board.search(cmd):
		Terminal.print($history/chessboard_flat.state.print_board())
		return
	if regex_next_move.search(cmd):
		if current_move >= document.page_list[page_index].history.size() - 1:
			Terminal.print(tr("DOCUMENT_HISTORY_END_OF_GAME"))
		else:
			current_move += 1
			Terminal.print(document.page_list[page_index].history[current_move])
		return
	if regex_prev_move.search(cmd):
		if current_move <= 0:
			Terminal.print(tr("DOCUMENT_HISTORY_BEGIN_OF_GAME"))
		else:
			current_move -= 1
			Terminal.print(document.page_list[page_index].history[current_move])
		return
	if regex_initial_board.search(cmd):
		Terminal.print(document.page_list[page_index].initial_state.print_board())
	if regex_next_page.search(cmd):
		if page_index >= document.page_count() - 1:
			Terminal.print(tr("DOCUMENT_END_OF_DOCUMENT"))
		else:
			turn_page(page_index + 1)
		return
	
	if regex_prev_page.search(cmd):
		if page_index <= 0:
			Terminal.print(tr("DOCUMENT_BEGIN_OF_DOCUMENT"))
		else:
			turn_page(page_index - 1)
		return
