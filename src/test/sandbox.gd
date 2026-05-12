extends Node3D

var state:State = null
var initial_state:State = null
@onready var chessboard = $chessboard

func _ready() -> void:
	$player.force_set_camera($camera_3d)
	chessboard.set_enabled(true)
	while !is_instance_valid(state):
		var text_input_instance:TextInput = TextInput.create_text_input_instance("输入FEN格式的布局：", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
		add_child(text_input_instance)
		await text_input_instance.confirmed
		state = Chess.parse(text_input_instance.text)
	initial_state = state.duplicate()
	chessboard.set_state(state.duplicate())
	chessboard.add_default_piece_set()
	select_first()

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey && event.is_pressed() && event.keycode == KEY_R:
		reset()

func select_first() -> void:
	chessboard.set_square_selection(
		state.get_bit(ord("K")) | state.get_bit(ord("k")) |
		state.get_bit(ord("Q")) | state.get_bit(ord("q")) |
		state.get_bit(ord("R")) | state.get_bit(ord("r")) |
		state.get_bit(ord("B")) | state.get_bit(ord("b")) |
		state.get_bit(ord("N")) | state.get_bit(ord("n")) |
		state.get_bit(ord("P")) | state.get_bit(ord("p"))
	)
	chessboard.click_selection.connect(first_selected)

func first_selected(selected:int) -> void:
	chessboard.click_selection.disconnect(first_selected)
	select_second.call_deferred(selected)

func select_second(from:int) -> void:
	var move_list:PackedInt32Array = Chess.generate_valid_move(state, state.get_turn())
	var selection:int = 0
	for iter:int in move_list:
		if Chess.from(iter) == from:
			selection |= Chess.mask(Chess.x88_to_c64(Chess.to(iter)))
	chessboard.set_square_selection(selection)
	chessboard.click_selection.connect(second_selected.bind(from, move_list))
	chessboard.click_empty.connect(second_empty)

func second_selected(to:int, from:int, move_list:PackedInt32Array) -> void:
	chessboard.click_selection.disconnect(second_selected)
	chessboard.click_empty.disconnect(second_empty)
	check_move.call_deferred(from, to, move_list)

func second_empty(_selected:int) -> void:
	chessboard.click_selection.disconnect(second_selected)
	chessboard.click_empty.disconnect(second_empty)
	select_first.call_deferred()

func check_move(from:int, to:int, move_list:PackedInt32Array) -> void:
	move_list = Array(move_list).filter(func (move:int) -> bool: return from == Chess.from(move) && to == Chess.to(move))
	if move_list.size() > 1:
		select_move.call_deferred(move_list)
	elif move_list.size() == 1:
		apply_move.call_deferred(move_list[0])

func select_move(move_list:PackedInt32Array) -> void:
	var decision_list:PackedStringArray = []
	var decision_to_move:Dictionary = {}
	for iter:int in move_list:
		decision_list.push_back("%c" % Chess.extra(iter))
		decision_to_move[decision_list[-1]] = iter
	decision_list.push_back("cancel")
	Dialog.push_selection(decision_list, "请选择一个着法", true, true)
	await Dialog.on_next
	if Dialog.selected == "cancel":
		select_first.call_deferred()
	else:
		apply_move.call_deferred(decision_to_move[Dialog.selected])

func apply_move(move:int) -> void:
	chessboard.execute_move(move)
	Chess.apply_move(state, move)
	select_first.call_deferred()

func reset() -> void:
	state = initial_state.duplicate()
	chessboard.set_state(initial_state)
