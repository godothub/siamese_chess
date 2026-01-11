extends InspectableItem
class_name Chessboard

signal clicked()
signal click_selection()
signal click_empty()
signal animation_finished()

@export var COLOR_LAST_MOVE:Color = Color(0.569, 0.569, 0.569, 1.0)
@export var COLOR_MOVE:Color = Color(0.56, 0.157, 0.164, 1.0)
@export var COLOR_POINTER:Color = Color(0.176, 0.176, 0.176, 1.0)

@onready var fallback_piece:Actor = load("res://scene/actor/piece_shrub.tscn").instantiate()
var backup_piece:Array = []	#  被吃的子统一放这里管理
var mouse_start_position_name:String = ""
var mouse_moved:bool = false
var state:State = null
var chessboard_piece:Dictionary[int, Actor] = {}
var king_instance:Array[Actor] = [null, null]

var square_selection:int = 0
var selected:int = -1

func _ready() -> void:
	super._ready()

func add_default_piece_set() -> void:	# 最好交由外部来负责棋子的准备
	backup_piece.clear()
	chessboard_piece.clear()
	for i:int in 128:
		if !state.has_piece(i):
			continue
		match String.chr(state.get_piece(i)):
			"K":
				add_piece_instance(load("res://scene/actor/piece_king_white.tscn").instantiate(), i)
			"Q":
				add_piece_instance(load("res://scene/actor/piece_queen_white.tscn").instantiate(), i)
			"R":
				add_piece_instance(load("res://scene/actor/piece_rook_white.tscn").instantiate(), i)
			"B":
				add_piece_instance(load("res://scene/actor/piece_bishop_white.tscn").instantiate(), i)
			"N":
				add_piece_instance(load("res://scene/actor/piece_knight_white.tscn").instantiate(), i)
			"P":
				add_piece_instance(load("res://scene/actor/piece_pawn_white.tscn").instantiate(), i)
			"W":
				add_piece_instance(load("res://scene/actor/piece_checker_1_white.tscn").instantiate(), i)
			"X":
				add_piece_instance(load("res://scene/actor/piece_checker_2_white.tscn").instantiate(), i)
			"Y":
				add_piece_instance(load("res://scene/actor/piece_checker_3_white.tscn").instantiate(), i)
			"Z":
				add_piece_instance(load("res://scene/actor/piece_checker_4_white.tscn").instantiate(), i)
			"k":
				add_piece_instance(load("res://scene/actor/piece_king_black.tscn").instantiate(), i)
			"q":
				add_piece_instance(load("res://scene/actor/piece_queen_black.tscn").instantiate(), i)
			"r":
				add_piece_instance(load("res://scene/actor/piece_rook_black.tscn").instantiate(), i)
			"b":
				add_piece_instance(load("res://scene/actor/piece_bishop_black.tscn").instantiate(), i)
			"n":
				add_piece_instance(load("res://scene/actor/piece_knight_black.tscn").instantiate(), i)
			"p":
				add_piece_instance(load("res://scene/actor/piece_pawn_black.tscn").instantiate(), i)
			"w":
				add_piece_instance(load("res://scene/actor/piece_checker_1_black.tscn").instantiate(), i)
			"x":
				add_piece_instance(load("res://scene/actor/piece_checker_2_black.tscn").instantiate(), i)
			"y":
				add_piece_instance(load("res://scene/actor/piece_checker_3_black.tscn").instantiate(), i)
			"z":
				add_piece_instance(load("res://scene/actor/piece_checker_4_black.tscn").instantiate(), i)

func remove_piece_set() -> void:
	for by:int in chessboard_piece:
		chessboard_piece[by].queue_free()
	for iter:Actor in backup_piece:
		iter.queue_free()
	chessboard_piece.clear()
	backup_piece.clear()

func input(_from:Node3D, _to:Area3D, _event:InputEvent, _event_position:Vector3, _normal:Vector3) -> void:
	if _event is InputEventMouseButton:
		if _event.pressed && _event.button_index == MOUSE_BUTTON_LEFT:
			finger_on_position(_to.get_name())
			tap_position(_to.get_name())
			mouse_moved = false
			mouse_start_position_name = _to.get_name()
			clicked.emit.call_deferred()
		elif !_event.pressed && mouse_moved && _event.button_index == MOUSE_BUTTON_LEFT:
			tap_position(_to.get_name())
			finger_up()
			mouse_start_position_name = ""
	if _event is InputEventMouseMotion:
		var position_name:String = _to.get_name()
		if mouse_start_position_name != position_name:
			mouse_moved = true
		finger_on_position(position_name)

func set_state(_state:State) -> void:
	$canvas.clear_pointer("last_move")
	$canvas.clear_pointer("move")
	state = _state.duplicate()
	#king_instance[0].set_warning(Chess.is_check(state, 1))
	#king_instance[1].set_warning(Chess.is_check(state, 0))

func get_position_name(_position:Vector3) -> String:
	var nearest:Area3D = null
	for i:int in 8:
		for j:int in 8:
			var position_name:String = "%c%d" % [i + 97, j + 1]
			if !nearest || _position.distance_squared_to(get_node(position_name).global_position) < _position.distance_squared_to(nearest.global_position):
				nearest = get_node(position_name)
	return nearest.name

func convert_name_to_position(_position_name:String) -> Vector3:
	return get_node(_position_name).position

func tap_position(position_name:String) -> void:
	selected = Chess.to_position_int(position_name)
	if square_selection != -1 && (Chess.mask(Chess.to_64(selected)) & square_selection):
		click_selection.emit.call_deferred()
		return
	click_empty.emit.call_deferred()

func finger_on_position(position_name:String) -> void:
	$canvas.clear_pointer("pointer")
	if !position_name:
		return
	$canvas.draw_pointer("pointer", COLOR_POINTER, $canvas.convert_name_to_position(position_name))

func finger_up() -> void:
	$canvas.clear_pointer("pointer")

func set_square_selection(_square_selection:int) -> void:
	$canvas.clear_pointer("move")
	selected = -1
	square_selection = _square_selection
	var bit:int = square_selection
	while bit:
		var by:int = Chess.to_x88(Chess.first_bit(bit))
		$canvas.draw_pointer("move", COLOR_MOVE, $canvas.convert_name_to_position(Chess.to_position_name(by)))
		bit = Chess.next_bit(bit)

func execute_move(move:int) -> Dictionary:
	var event:Dictionary = Chess.apply_move_custom(state, move)
	var rollback_event:Dictionary = receive_event(event)
	Chess.apply_move(state, move)
	$canvas.clear_pointer("move")
	$canvas.clear_pointer("last_move")
	$canvas.draw_pointer("last_move", COLOR_LAST_MOVE, $canvas.convert_name_to_position(Chess.to_position_name(Chess.from(move))))
	$canvas.draw_pointer("last_move", COLOR_LAST_MOVE, $canvas.convert_name_to_position(Chess.to_position_name(Chess.to(move))))
	#king_instance[0].set_warning(Chess.is_check(state, 1))
	#king_instance[1].set_warning(Chess.is_check(state, 0))
	selected = -1
	return rollback_event

# 由引擎通过字典传入事件、并通过字典返回撤销事件。
func receive_event(event:Dictionary) -> Dictionary:
	match event["type"]:
		"move":
			move_piece_instance(event["from"], event["to"])
			return event.duplicate()
		"capture":
			var captured_instance:Actor = chessboard_piece[event["to"]]
			capture_piece_instance(event["from"], event["to"])
			return {
				"type": "capture",
				"from": event["from"],
				"to": event["to"],
				"captured_instance": captured_instance
			}
		"promotion&capture":
			var captured_instance:Actor = chessboard_piece[event["to"]]
			promote_and_capture_piece_instance(event["from"], event["to"], event["piece"])
			return {
				"type": "promotion&capture",
				"from": event["from"],
				"to": event["to"],
				"captured_instance": captured_instance
			}
		"promotion":
			promote_piece_instance(event["from"], event["to"], event["piece"])
			return event.duplicate()
		"castle":
			castle_piece_instance(event["from_king"], event["to_king"], event["from_rook"], event["to_rook"])
			return event.duplicate()
		"en_passant":
			var captured_instance:Actor = chessboard_piece[event["captured"]]
			en_passant_piece_instance(event["from"], event["to"], event["captured"])
			return {
				"type": "en_passant",
				"captured_instance": captured_instance,
				"captured": event["captured"],
				"from": event["from"],
				"to": event["to"]
			}
		"grafting":
			graft_piece_instance(event["from"], event["to"])
			return event.duplicate()
		"king_explore":
			king_explore_instance(event["from"], event["path"])
			return {
				"type": "king_explore",
				"from": event["from"],
				"to": event["path"][-1]
			}
	return {}

func receive_rollback_event(event:Dictionary) -> void:
	match event["type"]:
		"capture":
			move_piece_instance(event["to"], event["from"])
			move_piece_instance_from_backup(event["to"], event["captured_instance"])
		"promotion&capture":
			chessboard_piece[event["to"]].unpromote()
			move_piece_instance(event["to"], event["from"])
			move_piece_instance_from_backup(event["to"], event["captured_instance"])
		"promotion":
			move_piece_instance(event["to"], event["from"])
		"move":
			move_piece_instance(event["to"], event["from"])
		"castle":
			castle_piece_instance(event["to_king"], event["from_king"], event["to_rook"], event["from_rook"])
		"en_passant":
			move_piece_instance(event["to"], event["from"])
			move_piece_instance_from_backup(event["captured"], event["captured_instance"])
		"grafting":
			graft_piece_instance(event["to"], event["from"])
		"king_explore":
			move_piece_instance(event["to"], event["from"])

func add_piece_instance(instance:Actor, by:int) -> void:	# 注意根据state摆放棋盘
	$pieces.add_child(instance)
	if by == -1:
		instance.visible = false
		backup_piece.push_back(instance)
	else:
		instance.visible = true
		chessboard_piece[by] = instance
		if state.get_piece(by) == ord("K"):
			king_instance[0] = instance
		if state.get_piece(by) == ord("k"):
			king_instance[1] = instance
		instance.introduce(get_node(Chess.to_position_name(by)).global_position)

func remove_piece_instance(instance:Actor) -> void:
	var by:Variant = chessboard_piece.find_key(instance)
	$pieces.remove_child(instance)
	chessboard_piece.erase(by)
	backup_piece.erase(instance)

func move_piece_instance_to_other(from:int, to:int, other:Chessboard) -> Actor:
	var instance:Actor = chessboard_piece[from]
	chessboard_piece.erase(from)
	instance.get_parent().remove_child(instance)
	other.add_piece_instance(instance, to)
	return instance

func move_piece_instance_from_backup(by:int, piece_instance:Actor) -> void:
	chessboard_piece[by] = piece_instance
	backup_piece.erase(piece_instance)
	piece_instance.introduce(get_node(Chess.to_position_name(by)).global_position)

func move_piece_instance(from:int, to:int) -> void:
	var instance:Actor = chessboard_piece[from]
	instance.move(get_node(Chess.to_position_name(to)).global_position)
	chessboard_piece.erase(from)
	chessboard_piece[to] = instance
	await instance.animation_finished
	animation_finished.emit.call_deferred()

func castle_piece_instance(from_1:int, to_1:int, from_2:int, to_2:int) -> void:
	var instance_1:Actor = chessboard_piece[from_1]
	instance_1.move(get_node(Chess.to_position_name(to_1)).global_position)
	chessboard_piece.erase(from_1)
	chessboard_piece[to_1] = instance_1
	var instance_2:Actor = chessboard_piece[from_2]
	instance_2.move(get_node(Chess.to_position_name(to_2)).global_position)
	chessboard_piece.erase(from_2)
	chessboard_piece[to_2] = instance_2
	await instance_1.animation_finished
	animation_finished.emit.call_deferred()

func capture_piece_instance(from:int, to:int) -> void:
	var instance_from:Actor = chessboard_piece[from]
	var instance_to:Actor = chessboard_piece[to]
	instance_from.capturing(get_node(Chess.to_position_name(to)).global_position, instance_to)
	move_piece_instance_to_backup(to)
	chessboard_piece.erase(from)
	chessboard_piece[to] = instance_from
	await instance_from.animation_finished
	animation_finished.emit.call_deferred()

func graft_piece_instance(from:int, to:int) -> void:
	var instance_1:Actor = chessboard_piece[from]
	var instance_2:Actor = chessboard_piece[to]
	chessboard_piece.erase(from)
	chessboard_piece.erase(to)
	instance_1.move(get_node(Chess.to_position_name(to)).global_position)
	instance_2.move(get_node(Chess.to_position_name(from)).global_position)
	chessboard_piece[from] = instance_2
	chessboard_piece[to] = instance_1
	await instance_1.animation_finished
	animation_finished.emit.call_deferred()

func promote_piece_instance(from:int, to:int, piece:int) -> void:
	var instance:Actor = chessboard_piece[from]
	instance.promote(get_node(Chess.to_position_name(to)).global_position, piece)
	chessboard_piece.erase(from)
	chessboard_piece[to] = instance
	animation_finished.emit.call_deferred()

func promote_and_capture_piece_instance(from:int, to:int, piece:int) -> void:
	var instance_from:Actor = chessboard_piece[from]
	var instance_to:Actor = chessboard_piece[to]
	instance_from.capturing(get_node(Chess.to_position_name(to)).global_position, instance_to)
	move_piece_instance_to_backup(to)
	await instance_from.animation_finished
	instance_from.promote(get_node(Chess.to_position_name(to)).global_position, piece)
	await instance_from.animation_finished
	chessboard_piece.erase(from)
	chessboard_piece[to] = instance_from
	animation_finished.emit.call_deferred()

func en_passant_piece_instance(from:int, to:int, captured:int) -> void:
	var instance_from:Actor = chessboard_piece[from]
	chessboard_piece[from].capturing(get_node(Chess.to_position_name(to)).global_position, chessboard_piece[captured])
	move_piece_instance_to_backup(captured)
	chessboard_piece.erase(from)
	chessboard_piece[to] = instance_from
	await instance_from.animation_finished
	animation_finished.emit.call_deferred()

func move_piece_instance_to_backup(by:int) -> void:
	var instance:Actor = chessboard_piece[by]
	chessboard_piece.erase(by)
	backup_piece.push_back(instance)
	#instance.visible = !pieces[instance]["hide_piece"]
	#instance.move(to_global(pieces[instance]["initial_position"]))

func exit_piece_instance(by:int, pos:Vector3) -> void:
	var instance:Actor = chessboard_piece[by]
	chessboard_piece.erase(by)
	instance.move(pos)
	await instance.animation_finished
	animation_finished.emit.call_deferred()

func king_explore_instance(from:int, path:PackedInt32Array) -> void:
	if path.is_empty():
		return
	var instance:Actor = chessboard_piece[from]
	chessboard_piece.erase(from)
	chessboard_piece[path[-1]] = instance
	for to:int in path:
		instance.move(get_node(Chess.to_position_name(to)).global_position)
		await instance.animation_finished
	animation_finished.emit.call_deferred()

func set_enabled(enabled:bool) -> void:
	super.set_enabled(enabled)
	if !enabled:
		$canvas.clear_pointer("move")
		$canvas.clear_pointer("pointer")
		selected = -1

func draw_pointer(type:String, color:Color, by:int, priority:int = 0) -> void:
	$canvas.draw_pointer(type, color, $canvas.convert_name_to_position(Chess.to_position_name(by)), priority)

func clear_pointer(type:String) -> void:
	$canvas.clear_pointer(type)
