extends Level

func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/405135__mjeno__autumn-forest-leaves-falling-close-to-pond-iii-loopable.wav"))
	Player.force_set_camera($camera)
	$event_teleport_garden.disabled = true
	$procedure_game.connect("procedure_end", game_end)
	$elevate_fence.position.y = 0

func game_end(result:String) -> void:
	if result == "checkmate_black" || result == "cleared_black":
		$event_teleport_garden.disabled = false
		var tween:Tween = create_tween()
		tween.tween_property($elevate_fence, "position:y", -1.8, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func inspect_door() -> void:
	var toast:Toast = Toast.create_instance("HINT_CANT_LEAVE")
	add_child(toast)
