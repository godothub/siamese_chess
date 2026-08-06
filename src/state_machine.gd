extends RefCounted
class_name StateMachine

signal state_changed(state:String)
var name:String = ""
var current_state:String = ""
var last_state:String = ""
var state_list:Dictionary = {}
var signal_container:SignalContainer = SignalContainer.new()
var mutex:Mutex = Mutex.new()

func add_state(new_state:String, ready_callback:Callable = Callable(), exit_callback:Callable = Callable(), process_callback:Callable = Callable(), input_callback:Callable = Callable(),) -> void:
	assert(new_state)
	state_list[new_state] = {
		"ready": ready_callback,
		"exit": exit_callback,
		"process": process_callback,
		"input": input_callback
	}

func process(_delta:float) -> void:
	if state_list[current_state]["process"].is_valid():
		state_list[current_state]["process"].call(_delta)

func input(_event:InputEvent) -> void:
	if state_list[current_state]["input"].is_valid():
		state_list[current_state]["input"].call(_event)

func change_state(next_state:String, arg:Dictionary = {}) -> void:
	mutex.lock()
	# 涉及到信号的自动断连
	signal_container.disconnect_all()
	last_state = current_state
	current_state = next_state
	# 执行状态退出方法
	print_verbose(name + ":" + current_state)
	if last_state && state_list[last_state]["exit"].is_valid():
		state_list[last_state]["exit"].call()
	mutex.unlock()
	if state_list[current_state]["ready"].is_valid():
		state_list[current_state]["ready"].call(arg)
	state_changed.emit.call_deferred(current_state)

func state_signal_connect(_signal:Signal, _method:Callable) -> void:
	signal_container.add_connection(_signal, _method)
