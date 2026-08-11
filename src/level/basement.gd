extends Level

var light_switch:bool = false

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/546047__grcekh__analog-crt-tv-electronic-static-noise.wav"))
	get_tree().call_group("lights", "set_visible", light_switch)
	light_switch = Progress.get_value("basement_light", false)
	set_light(light_switch)

func change_light() -> void:
	light_switch = !light_switch
	Progress.set_value("basement_light", light_switch)
	set_light(light_switch)

func set_light(enabled:bool) -> void:
	$reflection_probe.position = $reflection_probe.position + (Vector3(0, 0.0001, 0) if enabled else Vector3(0, -0.0001, 0))
	get_tree().call_group("lights", "set_visible", enabled)
