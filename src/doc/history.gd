extends Notable
class_name History

class HistoryPage extends RefCounted:
	var state:State = null
	var history:PackedStringArray = []
	var initial_state:State = null
	var history_raw:PackedInt32Array = []

var page_list:Array[HistoryPage] = []

func parse(data:Dictionary) -> void:
	super.parse(data)
	var data_arr:Array = data["history"]
	for iter:Dictionary in data_arr:
		var page:HistoryPage = HistoryPage.new()
		var fen:String = iter["state"]
		page.initial_state = Chess.parse(fen)
		page.history_raw = iter["history"]
		page_list.push_back(page)
		var test_state:State = page.initial_state.duplicate()
		for move:int in page.history_raw:
			page.history.push_back(Chess.get_move_name(test_state, move))
			Chess.apply_move(test_state, move)
		page.state = test_state

func dict() -> Dictionary:
	var data:Dictionary = super.dict()
	var data_arr:Array = []
	for page:HistoryPage in page_list:
		var iter:Dictionary = {}
		var fen:String = Chess.stringify(page.initial_state)
		iter["state"] = fen
		iter["history"] = page.history_raw
		data_arr.push_back(iter)
	data["history"] = data_arr
	return data

func set_state(index:int, _state:State) -> void:
	page_list[index].state = _state.duplicate()
	page_list[index].initial_state = _state.duplicate()
	page_list[index].history.clear()
	page_list[index].history_raw.clear()
	if _state.get_turn() == 1:
		page_list[index].history.push_back("-")
		page_list[index].history_raw.push_back(-1)
	content_changed.emit()

func push_move(index:int, move:int) -> void:
	if page_list[index].history.size() >= 120:
		return
	page_list[index].history_raw.push_back(move)
	page_list[index].history.push_back(Chess.get_move_name(page_list[index].state, move))
	Chess.apply_move(page_list[index].state, move)
	content_changed.emit()

func rollback(index:int, _state:State, pop_count:int = 1) -> void:
	page_list[index].history.resize(page_list[index].history.size() - pop_count)
	page_list[index].state = _state.duplicate()
	content_changed.emit()

func add_blank_line(index:int) -> void:
	page_list[index].history.push_back("")
	page_list[index].history.push_back("")
	content_changed.emit()

func new_page() -> void:
	super.new_page()
	var page:HistoryPage = HistoryPage.new()
	page_list.push_back(page)

func page_count() -> int:
	return page_list.size()
