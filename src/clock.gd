extends Node

signal timeout()

var time_left:float = 0
var start_thinking:float = 0
var extra:int = 0
var paused:bool = false

func _ready() -> void:
	set_physics_process(false)

func set_time(_time:float, _extra:int) -> void:
	time_left = _time
	extra = _extra
	start_thinking = Time.get_unix_time_from_system()
	paused = false

func _physics_process(_delta:float):
	var actual_time_left:float = get_time_left()
	Dialog.set_hint_left("%02d:%02d.%03d" % [int(actual_time_left / 60), int(fmod(actual_time_left, 60)), int(fmod(actual_time_left, 1) * 1000)])
	if get_time_left() <= 0:
		end_game()

func get_time_left() -> float:
	if !paused:
		return time_left - (Time.get_unix_time_from_system() - start_thinking)
	else:
		return time_left

func pause() -> void:
	if !paused:
		Dialog.set_hint_left("")
		time_left -= Time.get_unix_time_from_system() - start_thinking
		paused = true
		set_physics_process(false)

func resume() -> void:
	start_thinking = Time.get_unix_time_from_system()
	paused = false
	set_physics_process(true)

func end_game() -> void:
	Dialog.set_hint_left("")
	set_physics_process(false)
	timeout.emit()
