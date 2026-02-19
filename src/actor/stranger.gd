extends Actor

@export var direction:Vector3 = Vector3(0, 0, 1)
var state_machine:StateMachine = null

func _ready() -> void:
	state_machine = StateMachine.new()
	state_machine.add_state("idle", state_ready_idle, Callable(), state_process_idle)
	state_machine.add_state("move", state_ready_move, Callable(), state_process_move)
	state_machine.add_state("evade", state_ready_evade)
	state_machine.change_state("move")

func _physics_process(_delta:float) -> void:
	state_machine.process(_delta)	# 由于生命周期限制，最好在这里调用状态的process方法

func state_ready_idle(_arg:Dictionary) -> void:
	$animation_tree.get("parameters/playback").travel("idle")
	state_machine.state_signal_connect($area_3d.body_entered, func (_body:Node3D) -> void:
		state_machine.change_state("evade")
	)

func state_process_idle(_delta:float) -> void:
	velocity = Vector3(0, 0, 0)
	move_and_slide()

func state_ready_move(_arg:Dictionary) -> void:
	$animation_tree.get("parameters/playback").travel("walk")
	state_machine.state_signal_connect($area_3d.body_entered, func (_body:Node3D) -> void:
		state_machine.change_state("evade")
	)

func state_process_move(_delta:float) -> void:
	velocity = direction * 2
	global_rotation.y = Vector3.BACK.angle_to(direction)
	move_and_slide()

func state_ready_evade(_arg:Dictionary) -> void:
	$animation_tree.get("parameters/playback").travel("evade")
	var tween:Tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direction.rotated(Vector3.UP, PI) * 2, 1.65)
	tween.tween_callback(state_machine.change_state.bind("move"))
