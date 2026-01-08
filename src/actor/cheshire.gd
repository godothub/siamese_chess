extends Actor

var target_position:Vector3 = Vector3()
var target_actor:Actor = null
var tween:Tween = null

func _ready() -> void:
	$animation_tree.get("parameters/playback").start("battle_idle")
	top_level = true
	super._ready()

func play_animation(anim:String) -> void:
	$animation_tree.get("parameters/playback").travel(anim)

func introduce(_pos:Vector3) -> void:	# 登场动画
#	if tween && tween.is_running():
#		tween.kill()
#	if !visible:
	visible = true
	global_position = _pos
#	else:
#		move(_pos)

func capturing(_pos:Vector3, _captured:Actor) -> void:	# 攻击
	target_position = _pos
	target_actor = _captured
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(_pos.x, _pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	if tween && tween.is_running():
		tween.kill()
	tween = create_tween()
	if has_node("animation_tree"):
		tween.tween_callback($animation_tree.get("parameters/playback").travel.bind("battle_attack"))
	tween.tween_property(self, "global_rotation:y", target_angle, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(animation_finished.emit)

func fast_move() -> void:
	if tween && tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "global_position", target_position, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func knockdown_target() -> void:
	target_actor.captured(self)

func captured(_capturing:Actor = null) -> void:	# 被攻击
	if Chess.group(piece_type) == 0:
		Progress.accumulate("obtains", 10)
	if _capturing:
		var target_position_2d:Vector2 = Vector2(_capturing.global_position.x, _capturing.global_position.z)
		var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
		var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
		if tween && tween.is_running():
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "global_rotation:y", target_angle, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(animation_finished.emit)
	$animation_tree.get("parameters/playback").travel("battle_died")

func promote(_pos:Vector3, _piece:int) -> void:	# 升变，不过对于Cheshire而言不太可能，先留空
	pass
	
func move(_pos:Vector3) -> void:	# 单纯的移动
	target_position = _pos
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(_pos.x, _pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	if tween && tween.is_running():
		tween.kill()
	tween = create_tween()
	if has_node("animation_tree"):
		tween.tween_callback($animation_tree.get("parameters/playback").travel.bind("battle_move"))
	tween.tween_property(self, "global_rotation:y", target_angle, 0.1).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", _pos, global_position.distance_to(_pos) / 5)
	tween.set_parallel(false)
	tween.tween_callback(animation_finished.emit)
	if has_node("animation_tree"):
		tween.tween_callback($animation_tree.get("parameters/playback").travel.bind("battle_idle"))

func target() -> void:	# 作为轻子威胁重子，或牵制对手的棋子时将会面向目标准备攻击，包括将军
	if tween && tween.is_running():
		tween.kill()
	tween = create_tween()
	if has_node("animation_tree"):
		tween.tween_callback($animation_tree.get("parameters/playback").travel.bind("battle_target"))
	tween.tween_callback(animation_finished.emit)

func defend() -> void:  # 被轻子威胁，或被牵制时采取防御姿态
	if tween && tween.is_running():
		tween.kill()
	tween = create_tween()
	if has_node("animation_tree"):
		tween.tween_callback($animation_tree.get("parameters/playback").travel.bind("battle_defend"))
	tween.tween_callback(animation_finished.emit)
