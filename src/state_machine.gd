extends Node3D
class_name StateMachine

signal state_changed(state:String)
var current_state:String = ""
var last_state:String = ""
var state_list:Dictionary = {}
var	connection_list:Array = []
var mutex:Mutex = Mutex.new()

func add_state(new_state:String, ready_callback:Callable = Callable(), exit_callback:Callable = Callable(), process_callback:Callable = Callable()) -> void:
	state_list[new_state] = {
		"ready": ready_callback,
		"exit": exit_callback,
		"process": process_callback,
	}

func process(_delta:float) -> void:
	if state_list[current_state]["process"].is_valid():
		state_list[current_state]["process"].call(_delta)

func change_state(next_state:String, arg:Dictionary = {}) -> void:
	mutex.lock()
	# 涉及到信号的自动断连
	for connection:Dictionary in connection_list:
		connection["signal"].disconnect(connection["method"])
	connection_list.clear()
	last_state = current_state
	current_state = next_state
	# 执行状态退出方法
	print(current_state)
	if last_state && state_list[last_state]["exit"].is_valid():
		state_list[last_state]["exit"].call()
	state_list[current_state]["ready"].call_deferred(arg)
	set_physics_process(state_list[current_state]["process"].is_valid())
	state_changed.emit.call_deferred(current_state)
	mutex.unlock()

func state_signal_connect(_signal:Signal, _method:Callable) -> void:
	_signal.connect(_method)
	assert(_signal.is_connected(_method))
	connection_list.push_back({"signal": _signal, "method": _method})
