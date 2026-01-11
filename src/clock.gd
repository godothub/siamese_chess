extends Node

signal timeout()

var time_0:float = 0
var start_thinking_0:float = 0
var extra:int = 0
var paused:bool = false

func set_time(_time:float, _extra:int) -> void:
	time_0 = _time
	extra = _extra

func _physics_process(_delta):
	if get_time_left() <= 0:
		end_game()

func start() -> void:
	start_thinking_0 = Time.get_unix_time_from_system()
	set_physics_process(true)

func get_time_left() -> float:
	if !paused:
		return time_0 - (Time.get_unix_time_from_system() - start_thinking_0)
	else:
		return time_0

func pause() -> void:
	time_0 -= Time.get_unix_time_from_system() - start_thinking_0
	paused = true
	set_physics_process(false)

func resume() -> void:
	start_thinking_0 = Time.get_unix_time_from_system()
	paused = false
	set_physics_process(true)

func end_game() -> void:
	set_physics_process(false)
	timeout.emit()
