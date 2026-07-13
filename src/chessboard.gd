extends InspectableItem
class_name Chessboard

signal clicked()
signal hovered(selected:int)
signal click_selection(selected:int)
signal click_empty(selected:int)
signal selection_down(selected:int)
signal empty_down(selected:int)
signal selection_up(selected:int)
signal empty_up(selected:int)
signal empty_double_click(selected:int)
signal selection_hold(selected:int)
signal animation_finished()

@export var COLOR_LAST_MOVE:Color = Color(0.52, 0.333, 0.27, 1.0)
@export var COLOR_MOVE:Color = Color(0.655, 0.208, 0.199, 1.0)
@export var COLOR_POINTER:Color = Color(0.78, 0.619, 0.32, 1.0)
@export var actor_scale_factor:float = 1
@export var show_bit:PackedInt32Array = [ord("-"), ord("|")]

var backup_piece:Array = []	# 被吃的子统一放这里管理
var steady_piece:Dictionary = {}	# 待加入棋盘中的后备棋子放这里管理，跟被吃棋子区别在于这些棋子可以派上场
# 格式：{ 棋子编号: [对象1、 对象2] }

var fallback_piece:Dictionary = {
	ord("K"): {"actor": load("res://scene/actor/piece_king_white.tscn"), "meta": {}},
	ord("Q"): {"actor": load("res://scene/actor/piece_queen_white.tscn"), "meta": {}},
	ord("R"): {"actor": load("res://scene/actor/piece_rook_white.tscn"), "meta": {}},
	ord("B"): {"actor": load("res://scene/actor/piece_bishop_white.tscn"), "meta": {}},
	ord("N"): {"actor": load("res://scene/actor/piece_knight_white.tscn"), "meta": {}},
	ord("P"): {"actor": load("res://scene/actor/piece_pawn_white.tscn"), "meta": {}},
	ord("k"): {"actor": load("res://scene/actor/piece_king_black.tscn"), "meta": {}},
	ord("q"): {"actor": load("res://scene/actor/piece_queen_black.tscn"), "meta": {}},
	ord("r"): {"actor": load("res://scene/actor/piece_rook_black.tscn"), "meta": {}},
	ord("b"): {"actor": load("res://scene/actor/piece_bishop_black.tscn"), "meta": {}},
	ord("n"): {"actor": load("res://scene/actor/piece_knight_black.tscn"), "meta": {}},
	ord("p"): {"actor": load("res://scene/actor/piece_pawn_black.tscn"), "meta": {}}
}

var pointer_position_name:String = ""
var mouse_start_position_name:String = ""
var mouse_hold:bool = false
var mouse_moved:bool = false
var button_input_hold:bool = false
var button_input_moved:bool = false
var button_input_pointer:int = 0
var button_input_dir_axis:int = 0
var direction_mapping:Dictionary = {}

var state:State = null
var chessboard_piece:Dictionary[int, Actor] = {}
var bit_instance:Dictionary[int, Dictionary]
var king_instance:Array[Actor] = [null, null]

var square_selection:int = 0
var double_click_threshold:float = 0.3
var hold_threshold:float = 0.3
var double_click_timer:float = 0

var das_timer:Timer = Timer.new()
var arr_timer:Timer = Timer.new()
var das_interval:float = 0.3
var arr_interval:float = 0.1
var keep_das_interval:float = 0.1

static func get_default_piece_instance(piece:int) -> Actor:
	match piece:
		ord('K'):
			return load("res://scene/actor/piece_king_white.tscn").instantiate()
		ord('Q'):
			return load("res://scene/actor/piece_queen_white.tscn").instantiate()
		ord('R'):
			return load("res://scene/actor/piece_rook_white.tscn").instantiate()
		ord('B'):
			return load("res://scene/actor/piece_bishop_white.tscn").instantiate()
		ord('N'):
			return load("res://scene/actor/piece_knight_white.tscn").instantiate()
		ord('P'):
			return load("res://scene/actor/piece_pawn_white.tscn").instantiate()
		ord('k'):
			return load("res://scene/actor/piece_king_black.tscn").instantiate()
		ord('q'):
			return load("res://scene/actor/piece_queen_black.tscn").instantiate()
		ord('r'):
			return load("res://scene/actor/piece_rook_black.tscn").instantiate()
		ord('b'):
			return load("res://scene/actor/piece_bishop_black.tscn").instantiate()
		ord('n'):
			return load("res://scene/actor/piece_knight_black.tscn").instantiate()
		ord('p'):
			return load("res://scene/actor/piece_pawn_black.tscn").instantiate()
		ord('*'):
			return load("res://scene/actor/piece_checker_1_black.tscn").instantiate()
		ord('#'):
			return load("res://scene/actor/piece_barrier.tscn").instantiate()
		ord('|'):
			return load("res://scene/actor/bit_wall_rank.tscn").instantiate()
		ord('-'):
			return load("res://scene/actor/bit_wall_file.tscn").instantiate()
	return null

func _ready() -> void:
	super._ready()
	das_timer.one_shot = true
	arr_timer.one_shot = false
	das_timer.connect("timeout", func() -> void:
		repeat_moving_pointer()
		arr_timer.start(arr_interval)
	)
	arr_timer.connect("timeout", repeat_moving_pointer)
	add_child(das_timer)
	add_child(arr_timer)

func add_default_piece_set() -> void:	# 最好交由外部来负责棋子的准备
	backup_piece.clear()
	chessboard_piece.clear()
	for i:int in 128:
		if !state.has_piece(i):
			continue
		var new_instance:Actor = get_default_piece_instance(state.get_piece(i))
		add_child(new_instance)
		add_piece_instance(new_instance, i)
	for piece:int in show_bit:
		var bit:int = state.get_bit(piece)
		while bit != 0:
			var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
			var new_instance:Actor = get_default_piece_instance(piece)
			add_child(new_instance)
			add_bit_instance(new_instance, piece, by)
			bit = Chess.next_bit(bit)

func remove_piece_set() -> void:
	for by:int in chessboard_piece:
		chessboard_piece[by].queue_free()
	for piece:int in bit_instance:
		for iter:Actor in bit_instance[piece]:
			iter.queue_free()
	for iter:Actor in backup_piece:
		iter.queue_free()
	chessboard_piece.clear()
	bit_instance.clear()
	backup_piece.clear()

var button_pressed:Dictionary = {}
func button_input(_button:String, _pressed:bool) -> bool:
	var camera:Camera3D = get_viewport().get_camera_3d()
	var direction:float = camera.global_rotation.y
	direction -= global_rotation.y
	if _pressed && button_pressed.has(_button):
		return true
	elif _pressed:
		button_pressed[_button] = true
	if !_pressed && !button_pressed.has(_button):
		return true
	elif !_pressed:
		button_pressed.erase(_button)
	if direction > -PI / 4 * 3 && direction <= -PI / 4:
		direction_mapping = {"up": 1, "down": -1, "left": -16, "right": 16}
	elif direction > -PI / 4 && direction <=  PI / 4:
		direction_mapping = {"up": -16, "down":16, "left": -1, "right": 1}
	elif direction >  PI / 4 && direction <=  PI / 4 * 3:
		direction_mapping = {"up": -1, "down": 1, "left": 16, "right": -16}
	else:
		direction_mapping = {"up": 16, "down": -16, "left": 1, "right": -1}
	if _button in ["up", "down", "left", "right"]:
		if _pressed:
			button_input_dir_axis += direction_mapping[_button]
			if arr_timer.is_stopped() && das_timer.is_stopped():
				das_timer.start(das_interval)
				button_input_moved = true
				return repeat_moving_pointer()
			if !arr_timer.is_stopped():
				arr_timer.stop()
				arr_timer.start(arr_interval)
				return repeat_moving_pointer()
		elif !_pressed:
			button_input_dir_axis -= direction_mapping[_button]
			if button_input_dir_axis == 0:
				das_timer.stop()
				arr_timer.stop()
			return true
	elif _button =="accept":
		if _pressed:
			$audio_stream_player_click_down.play()
			button_input_hold = true
			button_input_moved = false
			tap_position(Chess.x88_to_name(button_input_pointer), true)
		elif button_input_moved:
			$audio_stream_player_click_up.play()
			tap_position(Chess.x88_to_name(button_input_pointer), false)
			button_input_moved = false
			button_input_hold = false
		else:
			$audio_stream_player_click_up.play()
			button_input_hold = false
	return true

func repeat_moving_pointer() -> bool:
	if !((button_input_pointer + button_input_dir_axis) & 0x88):
		button_input_pointer += button_input_dir_axis
		finger_on_position(Chess.x88_to_name(button_input_pointer))
		return true
	return false

func area_input(_from:Object, _to:Area3D, _instant:bool, _pressed:bool, _event_position:Vector3, _normal:Vector3) -> void:
	if _instant:
		if _pressed:
			$audio_stream_player_click_down.global_position = _to.global_position
			$audio_stream_player_click_down.play()
			finger_on_position(_to.get_name())
			tap_position(_to.get_name(), true)
			mouse_hold = true
			mouse_moved = false
			mouse_start_position_name = _to.get_name()
			clicked.emit.call_deferred()
		elif mouse_moved:
			$audio_stream_player_click_up.global_position = _to.global_position
			$audio_stream_player_click_up.play()
			tap_position(_to.get_name(), false)
			finger_up()
			mouse_start_position_name = ""
			mouse_moved = false
			mouse_hold = false
		else:
			$audio_stream_player_click_up.global_position = _to.global_position
			$audio_stream_player_click_up.play()
			mouse_hold = false
	else:
		var position_name:String = _to.get_name()
		if mouse_start_position_name != position_name:
			mouse_moved = true
		button_input_pointer = Chess.name_to_x88(position_name)
		finger_on_position(position_name)

func set_state(_state:State) -> void:
	$canvas.clear_pointer("last_move")
	$canvas.clear_pointer("move")
	state = _state.duplicate()
	#king_instance[0].set_warning(Chess.is_check(state, 1))
	#king_instance[1].set_warning(Chess.is_check(state, 0))

func x88_to_vector3(_by:int) -> Vector3:
	var position_name:String = "%c%d" % [_by % 16 + 97, 7 - _by / 16 + 1]
	return get_node(position_name).position

func vector3_to_x88(_position:Vector3) -> int:
	return Chess.name_to_x88(vector3_to_name(_position))

func vector3_to_name(_position:Vector3) -> String:
	var nearest:Area3D = null
	for i:int in 8:
		for j:int in 8:
			var position_name:String = "%c%d" % [i + 97, j + 1]
			if !nearest || _position.distance_squared_to(get_node(position_name).global_position) < _position.distance_squared_to(nearest.global_position):
				nearest = get_node(position_name)
	return nearest.name

func name_to_vector3(_position_name:String) -> Vector3:
	return get_node(_position_name).position

func tap_position(position_name:String, down:bool = true) -> void:
	var selected:int = Chess.name_to_x88(position_name)
	if square_selection != -1 && (Chess.mask(Chess.x88_to_c64(selected)) & square_selection):
		if down:
			selection_down.emit.call_deferred(selected)
			get_tree().create_timer(hold_threshold).timeout.connect(func () -> void:
				if mouse_hold && !mouse_moved || button_input_hold && !button_input_moved:
					selection_hold.emit.call_deferred(selected)
			)
		else:
			selection_up.emit.call_deferred(selected)
		click_selection.emit.call_deferred(selected)
		return
	if down:
		click_empty.emit.call_deferred(selected)
	if down:
		if (Time.get_unix_time_from_system() - double_click_timer <= double_click_threshold):
			empty_double_click.emit.call_deferred(selected)
			double_click_timer = 0
		else:
			double_click_timer = Time.get_unix_time_from_system()
		empty_down.emit.call_deferred(selected)
	else:
		empty_up.emit.call_deferred(selected)

func finger_on_position(position_name:String) -> void:
	$canvas.clear_pointer("pointer")
	if !position_name:
		return
	if position_name != pointer_position_name:
		var by:int = Chess.name_to_x88(position_name)
		if (by / 16 + by % 16) % 2 == 0:
			$audio_stream_player_tik.global_position = get_node(position_name).global_position
			$audio_stream_player_tik.play()
		else:
			$audio_stream_player_tok.global_position = get_node(position_name).global_position
			$audio_stream_player_tok.play()
		Input.vibrate_handheld(50, 0.2)
		Narrative.stop()
		if state.has_piece(Chess.name_to_x88(position_name)):
			var piece:int = state.get_piece(Chess.name_to_x88(position_name))
			Narrative.speak(tr("THERE_IS_A_PIECE").format({"piece": Localization.piece_to_pronounce(piece), "by": Localization.position_name_to_pronounce(position_name)}), false)
		hovered.emit(by)
	pointer_position_name = position_name
	$canvas.draw_pointer("pointer", COLOR_POINTER, Chess.name_to_x88(position_name))

func finger_up() -> void:
	$canvas.clear_pointer("pointer")

func set_square_selection(_square_selection:int) -> void:
	$canvas.clear_pointer("move")
	square_selection = _square_selection
	var bit:int = square_selection
	while bit:
		var by:int = Chess.c64_to_x88(Chess.first_bit(bit))
		$canvas.draw_pointer("move", COLOR_MOVE, by)
		bit = Chess.next_bit(bit)

func execute_move(move:int) -> Dictionary:
	var event:Dictionary = Chess.apply_move_custom(state, move)
	var rollback_event:Dictionary = receive_event(event)
	Chess.apply_move(state, move)
	$canvas.clear_pointer("last_move")
	if move != -1:
		$canvas.draw_pointer("last_move", COLOR_LAST_MOVE, Chess.from(move))
		$canvas.draw_pointer("last_move", COLOR_LAST_MOVE, Chess.to(move))
	#king_instance[0].set_warning(Chess.is_check(state, 1))
	#king_instance[1].set_warning(Chess.is_check(state, 0))
	return rollback_event

# 由引擎通过字典传入事件、并通过字典返回撤销事件。
func receive_event(event:Dictionary) -> Dictionary:
	match event["type"]:
		"move":
			move_piece_instance(event["from"], event["to"])
			return event.duplicate()
		"capture":
			var captured_instance:Actor = chessboard_piece.get(event["to"], null)
			capture_piece_instance(event["from"], event["to"])
			return {
				"type": "capture",
				"from": event["from"],
				"to": event["to"],
				"captured_instance": captured_instance
			}
		"promotion&capture":
			var captured_instance:Actor = chessboard_piece.get(event["to"], null)
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
			var captured_instance:Actor = chessboard_piece.get(event["captured"], null)
			en_passant_piece_instance(event["from"], event["to"], event["captured"])
			return {
				"type": "en_passant",
				"captured_instance": captured_instance,
				"captured": event["captured"],
				"from": event["from"],
				"to": event["to"]
			}
		"introduce":
			move_piece_instance_from_steady(event["by"], event["piece"])
			return event.duplicate()
		"leave":
			move_piece_instance_to_steady(event["by"], event["piece"])
			return event.duplicate()
		"pass":
			do_nothing()
			return event.duplicate()
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
			chessboard_piece[event["to"]].unpromote()
			move_piece_instance(event["to"], event["from"])
		"move":
			move_piece_instance(event["to"], event["from"])
		"castle":
			castle_piece_instance(event["to_king"], event["from_king"], event["to_rook"], event["from_rook"])
		"en_passant":
			move_piece_instance(event["to"], event["from"])
			move_piece_instance_from_backup(event["captured"], event["captured_instance"])
		"introduce":
			move_piece_instance_to_steady(event["by"], event["piece"])
		"leave":
			move_piece_instance_from_steady(event["by"], event["piece"])
		"king_explore":
			move_piece_instance(event["to"], event["from"])
		"pass":
			do_nothing()

func add_bit_instance(instance:Actor, piece:int, by:int) -> void:
	if !instance:
		return
	instance.scale *= actor_scale_factor
	if by == -1:
		instance.visible = false
		backup_piece.push_back(instance)
	else:
		bit_instance.get_or_add(piece, {})[by] = instance
		instance.visible = true
		instance.introduce(get_node(Chess.x88_to_name(by)).global_position)

func add_piece_instance(instance:Actor, by:int) -> void:	# 注意根据state摆放棋盘
	if !instance:
		return
	instance.scale *= actor_scale_factor	# 有时只是放大格子，而有时需要连带actor一起缩放
	if by == -1:
		instance.visible = false
		backup_piece.push_back(instance)
	else:
		instance.visible = true
		chessboard_piece[by] = instance
		#if state.get_piece(by) == ord("K"):
		#	king_instance[0] = instance
		#if state.get_piece(by) == ord("k"):
		#	king_instance[1] = instance
		instance.introduce(get_node(Chess.x88_to_name(by)).global_position)

func add_piece_instance_to_steady(instance:Actor, piece:int) -> void:
	if !instance:
		return
	steady_piece.get_or_add(piece, []).push_back(instance)
	instance.visible = false

func get_bit_instance(piece:int, by:int) -> Actor:
	return bit_instance.get(piece, {}).get(by, null)

func get_piece_instance(by:int) -> Actor:
	return chessboard_piece.get(by, null)

func move_piece_instance_to_steady(by:int, piece:int) -> void:
	var instance:Actor = chessboard_piece.get(by, null)
	if instance:
		chessboard_piece.erase(by)
		steady_piece.get_or_add(piece, []).push_back(instance)
		instance.leave()
		await instance.animation_finished
	animation_finished.emit.call_deferred()

func move_piece_instance_from_steady(by:int, piece:int) -> void:
	if !steady_piece.get_or_add(piece, []).size():
		var new_instance:Actor = fallback_piece[piece]["actor"].instantiate()
		for key:Variant in fallback_piece[piece]["meta"]:
			new_instance.set_meta(key, fallback_piece[piece]["meta"][key])
		steady_piece[piece].push_back(new_instance)
	var instance:Actor = steady_piece[piece][-1]
	steady_piece[piece].pop_back()
	chessboard_piece[by] = instance
	instance.introduce(get_node(Chess.x88_to_name(by)).global_position)
	await instance.animation_finished
	animation_finished.emit.call_deferred()

func get_piece_instance_x88(instance:Actor) -> int:
	var by:Variant = chessboard_piece.find_key(instance)
	if by == null:
		return -1
	return by

func remove_piece_instance(instance:Actor) -> void:
	if !instance:
		return
	var by:int = get_piece_instance_x88(instance)
	if by == -1:
		return
	chessboard_piece.erase(by)
	backup_piece.erase(instance)

func remove_bit_instance(instance:Actor) -> void:
	if !instance:
		return
	for piece:int in bit_instance:
		bit_instance[piece].erase(instance)

func move_piece_instance_to_other(from:int, to:int, other:Chessboard) -> Actor:
	var instance:Actor = chessboard_piece[from]
	chessboard_piece.erase(from)
	instance.get_parent().remove_child(instance)
	other.add_piece_instance(instance, to)
	return instance

func move_piece_instance_from_backup(by:int, instance:Actor) -> void:
	chessboard_piece[by] = instance
	backup_piece.erase(instance)
	instance.introduce(get_node(Chess.x88_to_name(by)).global_position)
	await instance.animation_finished
	animation_finished.emit.call_deferred()

func move_piece_instance(from:int, to:int) -> void:
	var instance:Actor = chessboard_piece.get(from, null)
	if instance:
		instance.move(get_node(Chess.x88_to_name(to)).global_position)
		chessboard_piece.erase(from)
		chessboard_piece[to] = instance
		await instance.animation_finished
	animation_finished.emit.call_deferred()

func castle_piece_instance(from_1:int, to_1:int, from_2:int, to_2:int) -> void:
	var instance_1:Actor = chessboard_piece.get(from_1, null)
	if instance_1:
		instance_1.move(get_node(Chess.x88_to_name(to_1)).global_position)
		chessboard_piece.erase(from_1)
		chessboard_piece[to_1] = instance_1
	var instance_2:Actor = chessboard_piece.get(from_2, null)
	if instance_2:
		instance_2.move(get_node(Chess.x88_to_name(to_2)).global_position)
		chessboard_piece.erase(from_2)
		chessboard_piece[to_2] = instance_2
	if instance_1:
		await instance_1.animation_finished
	elif instance_2:
		await instance_2.animation_finished
	animation_finished.emit.call_deferred()

func capture_piece_instance(from:int, to:int) -> void:
	var instance_from:Actor = chessboard_piece.get(from, null)
	var instance_to:Actor = chessboard_piece.get(to, null)
	if instance_from:
		instance_from.capturing(get_node(Chess.x88_to_name(to)).global_position, instance_to)
		if instance_to:
			move_piece_instance_to_backup(to)
		chessboard_piece.erase(from)
		chessboard_piece[to] = instance_from
		await instance_from.animation_finished
	animation_finished.emit.call_deferred()

func promote_piece_instance(from:int, to:int, piece:int) -> void:
	var instance:Actor = chessboard_piece.get(from, null)
	if instance:
		instance.promote(get_node(Chess.x88_to_name(to)).global_position, piece)
		chessboard_piece.erase(from)
		chessboard_piece[to] = instance
	animation_finished.emit.call_deferred()

func promote_and_capture_piece_instance(from:int, to:int, piece:int) -> void:
	var instance_from:Actor = chessboard_piece.get(from, null)
	var instance_to:Actor = chessboard_piece.get(to, null)
	if instance_from:
		instance_from.capturing(get_node(Chess.x88_to_name(to)).global_position, instance_to)
		if instance_to:
			move_piece_instance_to_backup(to)
		chessboard_piece.erase(from)
		chessboard_piece[to] = instance_from
		await instance_from.animation_finished
		instance_from.promote(get_node(Chess.x88_to_name(to)).global_position, piece)
		await instance_from.animation_finished
	animation_finished.emit.call_deferred()

func en_passant_piece_instance(from:int, to:int, captured:int) -> void:
	var instance_from:Actor = chessboard_piece.get(from, null)
	var instance_to:Actor = chessboard_piece.get(captured, null)
	if instance_from:
		instance_from.capturing(get_node(Chess.x88_to_name(to)).global_position, chessboard_piece[captured])
		if instance_to:
			move_piece_instance_to_backup(captured)
		chessboard_piece.erase(from)
		chessboard_piece[to] = instance_from
		await instance_from.animation_finished
	animation_finished.emit.call_deferred()

func move_piece_instance_to_backup(by:int) -> void:
	var instance:Actor = chessboard_piece.get(by, null)
	if instance:
		chessboard_piece.erase(by)
		backup_piece.push_back(instance)

func leave_piece_instance(by:int, pos:Vector3) -> void:
	var instance:Actor = chessboard_piece.get(by, null)
	if instance:
		chessboard_piece.erase(by)
		instance.move(pos)
		await instance.animation_finished
	animation_finished.emit.call_deferred()

func do_nothing() -> void:
	# 由于牵扯到发送信号，空着也需要写函数
	animation_finished.emit.call_deferred()

func set_enabled(_enabled:bool) -> void:
	super.set_enabled(_enabled)
	if !enabled:
		$canvas.clear_pointer("move")
		$canvas.clear_pointer("pointer")

func draw_pointer(type:String, color:Color, by:int) -> void:
	$canvas.draw_pointer(type, color, by)

func clear_pointer(type:String) -> void:
	$canvas.clear_pointer(type)
