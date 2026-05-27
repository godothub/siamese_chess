extends Level

var light_switch:bool = false

func _ready() -> void:
	super._ready()
	get_tree().call_group("lights", "set_visible", light_switch)

func change_light() -> void:
	$reflection_probe.position = $reflection_probe.position + (Vector3(0, 0.0001, 0) if light_switch else Vector3(0, -0.0001, 0))
	light_switch = !light_switch
	get_tree().call_group("lights", "set_visible", light_switch)
	show_selection.call_deferred()
