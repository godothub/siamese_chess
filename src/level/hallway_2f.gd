extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))

func elevator_minus_1f() -> void:
	Progress.set_value("player_by", 0x10)
	Loading.change_scene("res://scene/level/hallway_minus_1f.tscn")

func elevator_1f() -> void:
	Progress.set_value("player_by", 0x67)
	Loading.change_scene("res://scene/level/reception_lobby.tscn")

func elevator_3f() -> void:
	Progress.set_value("player_by", 0x10)
	Loading.change_scene("res://scene/level/hallway_3f.tscn")
