extends NotableView
class_name HistoryView

var current_focus:Control = null
var state_list:Array[State] = []

func _ready() -> void:
	var labels:Array = [
		$history/label_title, $history/label_date, $history/label_event, $history/label_white, $history/label_black, $history/label_recorder, $history/header/label_1, $history/header/label_2, $history/header/label_3, $history/header/label_4, $history/header/label_5, $history/header/label_6, $history/sequence/label_1, $history/sequence/label_2, $history/sequence/label_3, $history/sequence/label_4, $history/sequence/label_5, $history/sequence/label_6, $history/sequence/label_7, $history/sequence/label_8, $history/sequence/label_9, $history/sequence/label_10, $history/sequence/label_11, $history/sequence/label_12, $history/sequence/label_13, $history/sequence/label_14, $history/sequence/label_15, $history/sequence/label_16, $history/sequence/label_17, $history/sequence/label_18, $history/sequence/label_19, $history/sequence/label_20, $history/sequence/label_21, $history/sequence/label_22, $history/sequence/label_23, $history/sequence/label_24, $history/sequence/label_25, $history/sequence/label_26, $history/sequence/label_27, $history/sequence/label_28, $history/sequence/label_29, $history/sequence/label_30, $history/sequence/label_31, $history/sequence/label_32, $history/sequence/label_33, $history/sequence/label_34, $history/sequence/label_35, $history/sequence/label_36, $history/sequence/label_37, $history/sequence/label_38, $history/sequence/label_39, $history/sequence/label_40, $history/sequence/label_41, $history/sequence/label_42, $history/sequence/label_43, $history/sequence/label_44, $history/sequence/label_45, $history/sequence/label_46, $history/sequence/label_47, $history/sequence/label_48, $history/sequence/label_49, $history/sequence/label_50, $history/sequence/label_51, $history/sequence/label_52, $history/sequence/label_53, $history/sequence/label_54, $history/sequence/label_55, $history/sequence/label_56, $history/sequence/label_57, $history/sequence/label_58, $history/sequence/label_59, $history/sequence/label_60, $history/white/label_1, $history/white/label_2, $history/white/label_3, $history/white/label_4, $history/white/label_5, $history/white/label_6, $history/white/label_7, $history/white/label_8, $history/white/label_9, $history/white/label_10, $history/white/label_11, $history/white/label_12, $history/white/label_13, $history/white/label_14, $history/white/label_15, $history/white/label_16, $history/white/label_17, $history/white/label_18, $history/white/label_19, $history/white/label_20, $history/white/label_21, $history/white/label_22, $history/white/label_23, $history/white/label_24, $history/white/label_25, $history/white/label_26, $history/white/label_27, $history/white/label_28, $history/white/label_29, $history/white/label_30, $history/white/label_31, $history/white/label_32, $history/white/label_33, $history/white/label_34, $history/white/label_35, $history/white/label_36, $history/white/label_37, $history/white/label_38, $history/white/label_39, $history/white/label_40, $history/white/label_41, $history/white/label_42, $history/white/label_43, $history/white/label_44, $history/white/label_45, $history/white/label_46, $history/white/label_47, $history/white/label_48, $history/white/label_49, $history/white/label_50, $history/white/label_51, $history/white/label_52, $history/white/label_53, $history/white/label_54, $history/white/label_55, $history/white/label_56, $history/white/label_57, $history/white/label_58, $history/white/label_59, $history/white/label_60, $history/black/label_1, $history/black/label_2, $history/black/label_3, $history/black/label_4, $history/black/label_5, $history/black/label_6, $history/black/label_7, $history/black/label_8, $history/black/label_9, $history/black/label_10, $history/black/label_11, $history/black/label_12, $history/black/label_13, $history/black/label_14, $history/black/label_15, $history/black/label_16, $history/black/label_17, $history/black/label_18, $history/black/label_19, $history/black/label_20, $history/black/label_21, $history/black/label_22, $history/black/label_23, $history/black/label_24, $history/black/label_25, $history/black/label_26, $history/black/label_27, $history/black/label_28, $history/black/label_29, $history/black/label_30, $history/black/label_31, $history/black/label_32, $history/black/label_33, $history/black/label_34, $history/black/label_35, $history/black/label_36, $history/black/label_37, $history/black/label_38, $history/black/label_39, $history/black/label_40, $history/black/label_41, $history/black/label_42, $history/black/label_43, $history/black/label_44, $history/black/label_45, $history/black/label_46, $history/black/label_47, $history/black/label_48, $history/black/label_49, $history/black/label_50, $history/black/label_51, $history/black/label_52, $history/black/label_53, $history/black/label_54, $history/black/label_55, $history/black/label_56, $history/black/label_57, $history/black/label_58, $history/black/label_59, $history/black/label_60
	]
	for iter:Label in labels:
		iter.connect("mouse_entered", read_label.bind(iter))
		iter.connect("focus_entered", read_label.bind(iter))
	
	for i:int in range(60):
		get_node("history/white/label_%d" % (i + 1)).connect("gui_input", press_move.bind(i * 2))
		get_node("history/black/label_%d" % (i + 1)).connect("gui_input", press_move.bind(i * 2 + 1))
	current_focus = labels[0]

func set_document(_document:Document) -> void:
	assert(_document is History)
	if document:
		document.disconnect("content_changed", update_table)
	super.set_document(_document)
	_document.connect("content_changed", update_table)
	update_table()

func open() -> void:
	current_focus.grab_focus()

func close() -> void:
	super.close()

func update_table() -> void:
	$history/chessboard_flat.set_state(document.page_list[page_index].initial_state)
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
	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(label.text, Setting.get_value("voice"), 50, 1, 1, 0, true)

func press_move(event:InputEvent, index:int) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		if state_list.size() > index:
			$history/chessboard_flat.set_state(state_list[index])

func press_direction(_dir:int) -> void:
	var next_focus:Control = current_focus.find_valid_focus_neighbor(_dir)
	if next_focus:
		current_focus = next_focus
		current_focus.grab_focus()

func press_confirm() -> void:
	if Setting.get_value("text_to_speech"):
		DisplayServer.tts_speak(current_focus.text, Setting.get_value("voice"), 50, 1, 1, 0, true)
