extends Level

func _ready() -> void:
	super._ready()

func interact_computer() -> void:
	var toast:Toast = Toast.create_instance("HINT_ACCESS_DENIED")
	add_child(toast)
