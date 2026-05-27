extends Level

var cheshire_instance:Actor = null

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))

func _physics_process(_delta:float) -> void:
	$spot_light_follow_cheshire.look_at(cheshire_instance.global_position)
