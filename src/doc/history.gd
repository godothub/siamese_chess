extends Notable

class HistoryPage extends RefCounted:
	var state:State = null
	var history:PackedStringArray = []

var page_list:Array[HistoryPage] = []
var current_page:int = 0
var current_page_instance:HistoryPage = null

func parse(data:Dictionary) -> void:
	super.parse(data)
	var data_arr:Array = data["history"]
	for iter:Dictionary in data_arr:
		var page:HistoryPage = HistoryPage.new()
		var fen:String = iter["state"]
		page.state = Chess.parse(fen)
		page.history = iter["history"]
		page_list.push_back(page)
	current_page = 0
	current_page_instance = page_list[current_page]
	update_table()

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	var data_arr:Array = []
	for page:HistoryPage in page_list:
		var iter:Dictionary = {}
		var fen:String = Chess.stringify(page.state)
		iter["state"] = fen
		iter["history"] = page.history
		data_arr.push_back(iter)
	data["history"] = data_arr
	return data

func get_rect() -> Rect2:
	return $history.get_rect() * $history.transform

func set_state(_state:State) -> void:
	current_page_instance.state = _state.duplicate()
	current_page_instance.history.clear()
	update_table()

func push_move(move:int) -> void:
	if current_page_instance.history.size() >= 120:
		return
	current_page_instance.history.push_back(Chess.get_move_name(current_page_instance.state, move))
	Chess.apply_move(current_page_instance.state, move)
	update_table()

func rollback(_state:State, pop_count:int = 1) -> void:
	current_page_instance.history.resize(current_page_instance.history.size() - pop_count)
	current_page_instance.state = _state.duplicate()
	update_table()

func update_table() -> void:
	$chessboard_flat.set_state(current_page_instance.state)
	for i:int in range(60):
		get_node("white/label_%d" % (i + 1)).text = ""
		get_node("black/label_%d" % (i + 1)).text = ""
	for i:int in range(current_page_instance.history.size()):
		if i % 2 == 0:
			get_node("white/label_%d" % (i / 2 + 1)).text = current_page_instance.history[i]
		else:
			get_node("black/label_%d" % (i / 2 + 1)).text = current_page_instance.history[i]

func add_blank_line() -> void:
	current_page_instance.history.push_back("")
	current_page_instance.history.push_back("")

func new_page() -> void:
	super.new_page()
	var page:HistoryPage = HistoryPage.new()
	page_list.push_back(page)
	current_page = page_list.size() - 1
	current_page_instance = page

func turn_page(_page:int) -> void:
	super.turn_page(_page)
	current_page = _page
	current_page_instance = page_list[current_page]
	update_table()

func page_count() -> int:
	return page_list.size()

func page_index() -> int:
	return current_page
