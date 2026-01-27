extends CanvasLayer

var current:Node = null

func _ready() -> void:
	current = get_tree().current_scene
	$texture_rect.modulate = Color(1, 1, 1, 0)
	$texture_rect.visible = false

func change_scene(path:String, meta:Dictionary, wait_time:float = 0.3) -> void:
	Progress.set_value("current_level", path)
	Progress.save_file()
	var tween:Tween = create_tween()
	tween.tween_property($texture_rect, "visible", true, 0)
	tween.tween_property($texture_rect, "modulate", Color(1, 1, 1, 1), wait_time)
	await tween.finished
	var instance:Node = load(path).instantiate()
	for key:String in meta:
		instance.set_meta(key, meta[key])
	if is_instance_valid(current):
		current.queue_free()
	get_tree().root.add_child(instance)
	current = instance
	tween.kill()
	tween = create_tween()
	tween.tween_property($texture_rect, "modulate", Color(1, 1, 1, 0), wait_time)
	tween.tween_property($texture_rect, "visible", false, 0)
