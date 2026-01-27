extends Node3D
class_name StateMachine

signal level_state_changed(state:String)
var state_name:String = ""
var	connection_list:Array = []
var mutex:Mutex = Mutex.new()

func change_state(next_state:String, arg:Dictionary = {}) -> void:
	mutex.lock()
	# 涉及到信号的自动断连
	for connection:Dictionary in	connection_list:
		connection["signal"].disconnect(connection["method"])
	connection_list.clear()
	# 执行状态退出方法
	if has_method("state_exit_" + state_name):
		call("state_exit_" + state_name)
	state_name = next_state
	call_deferred("state_ready_" + state_name, arg)
	level_state_changed.emit.call_deferred(state_name)
	mutex.unlock()

func state_signal_connect(_signal:Signal, _method:Callable) -> void:
	_signal.connect(_method)
	assert(_signal.is_connected(_method))
	connection_list.push_back({"signal": _signal, "method": _method})
