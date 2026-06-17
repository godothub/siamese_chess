extends MarkerProcedure
class_name MarkerDecision

@export var cancelable:bool = false
@export var hint:String = ""
@export var selection:PackedStringArray = [""]
var state_machine:StateMachine = StateMachine.new()

func _ready() -> void:
	state_machine.name = "decision"
	state_machine.add_state("select", state_ready_select, state_exit_select)
	state_machine.add_state("stop", state_ready_stop)

func start() -> void:
	state_machine.change_state("select")

func state_ready_select(_arg:Dictionary) -> void:
	state_machine.state_signal_connect(Dialog.on_select, func(_selection:String) -> void:
		state_machine.change_state("stop", {"result": _selection})
	)
	state_machine.state_signal_connect(Dialog.on_cancel, func() -> void:
		state_machine.change_state("stop", {"result": ""})
	)
	if cancelable:
		Dialog.show_cancel()
	Dialog.push_selection(selection, hint, true, false)

func state_exit_select() -> void:
	Dialog.clear()
	Dialog.hide_cancel()

func state_ready_stop(_arg:Dictionary) -> void:
	procedure_end.emit(_arg.get("result", ""))
