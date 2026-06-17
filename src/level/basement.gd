extends Level

var light_switch:bool = false

func _ready() -> void:
	super._ready()
	get_tree().call_group("lights", "set_visible", light_switch)
	$marker_teleport_computer_room.disabled = true
	$bookshelf/bookshelf_001.position.x = 0
	$marker_game.connect("procedure_end", game_end)

func change_light() -> void:
	$reflection_probe.position = $reflection_probe.position + (Vector3(0, 0.0001, 0) if light_switch else Vector3(0, -0.0001, 0))
	light_switch = !light_switch
	get_tree().call_group("lights", "set_visible", light_switch)

func game_end(result:String) -> void:
	if result == "checkmate_black" || result == "cleared_black":
		$marker_teleport_computer_room.disabled = false
		var tween:Tween = create_tween()
		tween.tween_property($bookshelf/bookshelf_001, "position:x", -2, 3)
