extends InspectableItem

var scene_instance:Node = null

func _ready() -> void:
	clear()

func print(text:String) -> void:
	$sub_viewport/color_rect_black/margin_container/rich_text_label.add_text(text)

func clear() -> void:
	$sub_viewport/color_rect_black/margin_container/rich_text_label.clear()

func run_scene(path:String) -> void:
	var instance:Node = load(path).instantiate()
	scene_instance = instance
	$sub_viewport.add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	$sub_viewport/color_rect_black.hide()

func close_scene() -> void:
	scene_instance.queue_free()
	scene_instance = null
	$sub_viewport/color_rect_black.show()
