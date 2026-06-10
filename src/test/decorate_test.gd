extends Level

func _ready() -> void:
	super._ready()
	change_state("decorate")
	$marker_decorate.start()
