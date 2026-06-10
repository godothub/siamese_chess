extends MarkerProcedure
class_name MarkerDecorate

@export var chessboard:Chessboard = null
var available_model:Array = []
var current_model_index:int = -1
var current_model_instance:Node3D = null
var state_machine:StateMachine = StateMachine.new()

func _ready() -> void:
	var dir:DirAccess = DirAccess.open("res://assets/model")
	dir.list_dir_begin()
	var file_name:String = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() && file_name.ends_with(".glb"):
			available_model.push_back(load("res://assets/model/" + file_name))
		file_name = dir.get_next()
	state_machine.add_state("decorate", state_ready_decorate, Callable(), Callable(), state_input_decorate)
	state_machine.add_state("stop", state_ready_stop)

func start() -> void:
	state_machine.change_state("decorate")

func change_model(index:int) -> void:
	if current_model_instance:
		current_model_instance.queue_free()
	current_model_index = index
	current_model_instance = available_model[current_model_index].instantiate()
	chessboard.add_child(current_model_instance)

func state_ready_decorate(_arg:Dictionary) -> void:
	state_machine.state_signal_connect(chessboard.hovered, func (by:int) -> void:
		if !current_model_instance:
			return
		current_model_instance.global_position = chessboard.x88_to_vector3(by)
	)
	state_machine.state_signal_connect(chessboard.click_empty, func (by:int) -> void:
		if !current_model_instance:
			return
		current_model_instance.global_position = chessboard.x88_to_vector3(by)
		if !(current_model_index in range(0, available_model.size())):
			return
		current_model_instance = available_model[current_model_index].instantiate()
		chessboard.add_child(current_model_instance)
	)

func state_input_decorate(event:InputEvent) -> void:
	if event.is_action_pressed("tab_left"):
		current_model_instance.rotation.y += 2 / PI
	if event.is_action_pressed("tab_right"):
		current_model_instance.rotation.y -= 2 / PI
	if event.is_action_pressed("select"):
		current_model_index = ((current_model_index + 1) + available_model.size()) % available_model.size()
		change_model(current_model_index)

func state_ready_stop(_arg:Dictionary) -> void:
	procedure_end.emit(_arg.get("result", ""))

func _input(event:InputEvent) -> void:
	state_machine.input(event)
