extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/405135__mjeno__autumn-forest-leaves-falling-close-to-pond-iii-loopable.wav"))
	Player.force_set_camera($camera)

func inspect_door() -> void:
	var toast:Toast = Toast.create_instance("HINT_CANT_LEAVE")
	add_child(toast)
