extends InspectableItem

var scene_instance:Node = null

func _ready() -> void:
	clear()

func print(text:String) -> void:
	$sub_viewport/texture_rect/margin_container/rich_text_label.add_text(text)

func clear() -> void:
	$sub_viewport/texture_rect/margin_container/rich_text_label.clear()

func run_scene(path:String) -> void:
	var instance:Node = load(path).instantiate()
	scene_instance = instance
	$sub_viewport.add_child(instance)
	$sub_viewport/texture_rect.hide()

func close_scene() -> void:
	scene_instance.queue_free()
	scene_instance = null
	$sub_viewport/texture_rect.show()
