extends Level

var light_switch:bool = false

func _ready() -> void:
	super._ready()
	get_tree().call_group("lights", "set_visible", light_switch)
	$marker_teleport_computer_room.disabled = true
	$bookshelf/bookshelf_001.position.x = 0
	$marker_game.connect("procedure_end", game_end)
	light_switch = Progress.get_value("basement_light", false)
	set_light(light_switch)

func change_light() -> void:
	light_switch = !light_switch
	Progress.set_value("basement_light", light_switch)
	set_light(light_switch)

func set_light(enabled:bool) -> void:
	$reflection_probe.position = $reflection_probe.position + (Vector3(0, 0.0001, 0) if enabled else Vector3(0, -0.0001, 0))
	get_tree().call_group("lights", "set_visible", enabled)
	

func game_end(result:String) -> void:
	if result == "checkmate_black" || result == "cleared_black":
		$marker_teleport_computer_room.disabled = false
		var tween:Tween = create_tween()
		tween.tween_property($bookshelf/bookshelf_001, "position:x", -2, 3)
