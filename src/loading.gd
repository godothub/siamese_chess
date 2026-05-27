extends CanvasLayer

var current:Node = null
var path:String = ""
var meta:Dictionary = {}

func _ready() -> void:
	current = get_tree().current_scene
	$texture_rect.modulate = Color(1, 1, 1, 0)
	$texture_rect.visible = false

func reset_scene() -> void:
	Progress.set_value("time_left", 60 * 15)
	Clock.set_time(60 * 15, 0)
	change_scene(path, meta)

func change_scene(_path:String, _meta:Dictionary, wait_time:float = 0.3) -> void:
	Progress.set_value("current_level", _path)
	Progress.set_value("current_level_meta", _meta)
	Progress.save_file()
	path = _path
	meta = _meta
	var tween:Tween = create_tween()
	tween.tween_property($texture_rect, "visible", true, 0)
	tween.tween_property($texture_rect, "modulate", Color(1, 1, 1, 1), wait_time)
	await tween.finished
	var instance:Node = load(_path).instantiate()
	for key:String in _meta:
		instance.set_meta(key, _meta[key])
	if is_instance_valid(current):
		if current.has_method("on_exit"):
			current.on_exit()
		current.queue_free()
	get_tree().root.add_child.call_deferred(instance)
	current = instance
	tween.kill()
	tween = create_tween()
	tween.tween_property($texture_rect, "modulate", Color(1, 1, 1, 0), wait_time)
	tween.tween_property($texture_rect, "visible", false, 0)
