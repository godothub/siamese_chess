extends Actor

var position_name:String = ""
var sfx:AudioStreamPlayer3D = null
var larger_scale:bool = false
var promote_instance:Actor = null

func _ready() -> void:
	super._ready()
	top_level = true
	var audio_stream_randomizer:AudioStreamRandomizer = AudioStreamRandomizer.new()
	audio_stream_randomizer.random_pitch = 1.3
	audio_stream_randomizer.random_volume_offset_db = 2.0
	audio_stream_randomizer.add_stream(-1, load("res://assets/audio/351518__mh2o__chess_move_on_alabaster.wav"))
	sfx = AudioStreamPlayer3D.new()
	sfx.stream = audio_stream_randomizer
	sfx.bus = &"SFX"
	add_child(sfx)
	sfx.unit_size = 40 if larger_scale else 2
	sfx.volume_db = 0 if larger_scale else 0
	if has_meta("larger_scale") && get_meta("larger_scale"):
		set_larger_scale()
	#if position_name:
	#	position = chessboard.convert_name_to_position(position_name)
	#else:
	#	position_name = chessboard.get_position_name(position)
	#	position = chessboard.convert_name_to_position(position_name)

func introduce(_pos:Vector3) -> void:	# 登场动画
	visible = true
	global_position = _pos

func move(_pos:Vector3) -> void:
	var tween:Tween = create_tween()
	tween.tween_callback(sfx.play)
	tween.tween_property(self, "global_position", _pos, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(animation_finished.emit)

func capturing(_pos:Vector3, _captured:Actor) -> void:	# 攻击
	var tween:Tween = create_tween()
	tween.tween_callback(sfx.play)
	tween.tween_property(self, "global_position", _pos, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(animation_finished.emit)
	_captured.captured(self)

func captured(_capturing:Actor = null) -> void:	# 被攻击
	if larger_scale && Chess.group(piece_type) == 0:
		Progress.accumulate("obtains", 5)
	visible = false
	return

func promote(_pos:Vector3, _piece:int) -> void:
	var tween:Tween = create_tween()
	tween.tween_callback(sfx.play)
	tween.tween_property(self, "global_position", _pos, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(change_model.bind(_piece))
	tween.tween_callback(animation_finished.emit)

func unpromote() -> void:
	if is_instance_valid(promote_instance):
		promote_instance.queue_free()
	$piece.visible = true

func change_model(_piece:int) -> void:
	$piece.visible = false
	match _piece:
		81:
			promote_instance = load("res://scene/actor/piece_queen_white.tscn").instantiate()
		82:
			promote_instance = load("res://scene/actor/piece_rook_white.tscn").instantiate()
		66:
			promote_instance = load("res://scene/actor/piece_bishop_white.tscn").instantiate()
		78:
			promote_instance = load("res://scene/actor/piece_knight_white.tscn").instantiate()
		113:
			promote_instance = load("res://scene/actor/piece_queen_black.tscn").instantiate()
		114:
			promote_instance = load("res://scene/actor/piece_rook_black.tscn").instantiate()
		98:
			promote_instance = load("res://scene/actor/piece_bishop_black.tscn").instantiate()
		110:
			promote_instance = load("res://scene/actor/piece_knight_black.tscn").instantiate()
	add_child(promote_instance)
	promote_instance.top_level = false

func set_larger_scale() -> Actor:
	scale = Vector3(8, 8, 8)
	larger_scale = true
	return self
