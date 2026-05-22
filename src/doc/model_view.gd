extends DocumentView
class_name ModelView

var model_instance:Node3D = null

var last_position:Vector2 = Vector2(0, 0)

func set_document(_document:Document) -> void:
	assert(_document is Model)
	if document:
		document.disconnect("content_changed", update_model)
	super.set_document(_document)
	_document.connect("content_changed", update_model)

func start_dragging(_start_position:Vector2) -> void:
	last_position = _start_position

func dragging(_drawing_position:Vector2) -> void:
	model_instance.rotation.y += (_drawing_position.x - last_position.x) / 300
	last_position = _drawing_position

func update_model() -> void:
	if is_instance_valid(model_instance):
		model_instance.queue_free()
	model_instance = load(document.model_path).instantiate()
	$sub_viewport.add_child(model_instance)
