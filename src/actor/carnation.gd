extends Actor

func _ready() -> void:
	$animation_tree.get("parameters/playback").start("idle")

func set_direction(_rotation:float) -> Actor:
	global_rotation.y = _rotation
	return self

func play_animation(anim:String) -> void:
	$animation_tree.get("parameters/playback").start(anim)
