extends Level

func _ready() -> void:
	Ambient.change_environment_sound(load("res://assets/audio/546047__grcekh__analog-crt-tv-electronic-static-noise.wav"))
	super._ready()

func interact_computer() -> void:
	var toast:Toast = Toast.create_instance("HINT_ACCESS_DENIED")
	add_child(toast)
