extends Panel
class_name DocumentView

var document:Document
var page_index:int = 0

static var regex_close:RegEx = RegEx.create_from_string("")

func set_document(_document:Document) -> void:
	document = _document

func open() -> void:
	pass

func close() -> void:
	pass

func click(_click_position:Vector2) -> void:
	pass

func start_dragging(_start_position:Vector2) -> void:
	pass

func dragging(_drawing_position:Vector2) -> void:
	pass

func end_dragging() -> void:
	pass

func cancel_dragging() -> void:
	pass

func erase(_drawing_position:Vector2) -> void:
	pass

func set_focus(_focus:int) -> void:
	pass

func detail() -> void:
	pass

func focus_count() -> int:
	return 0

func new_page() -> void:
	pass

func turn_page(_page:int) -> void:
	page_index = _page

func on_command_received(_cmd:String) -> void:
	pass
