extends Actor

@export var direction:Vector3 = Vector3(0, 0, 1)
var state_machine:StateMachine = null

func _ready() -> void:
	state_machine = StateMachine.new()
	state_machine.add_state("idle", state_ready_idle, Callable(), state_process_idle)
	state_machine.add_state("move", state_ready_move, Callable(), state_process_move)
	state_machine.add_state("evade", state_ready_evade)
	state_machine.change_state("idle")

func _physics_process(_delta:float) -> void:
	state_machine.process(_delta)	# 由于生命周期限制，最好在这里调用状态的process方法

func state_ready_idle(_arg:Dictionary) -> void:
	$animation_tree.get("parameters/playback").travel("idle")

func state_process_idle(_delta:float) -> void:
	velocity = Vector3(0, 0, 0)
	move_and_slide()
	if get_slide_collision_count():
		state_machine.change_state("evade")
	if direction:
		state_machine.change_state("move")

func state_ready_move(_arg:Dictionary) -> void:
	$animation_tree.get("parameters/playback").travel("walk")

func state_process_move(_delta:float) -> void:
	velocity = direction
	global_rotation.y = Vector3.ZERO.direction_to(direction).y
	move_and_slide()
	if get_last_slide_collision():
		state_machine.change_state("evade")

func state_ready_evade(_arg:Dictionary) -> void:
	$animation_tree.get("parameters/playback").travel("evade")
	var tween:Tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direction.rotated(Vector3.UP, PI / 2), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(state_machine.change_state.bind("idle"))
