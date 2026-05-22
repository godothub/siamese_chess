extends NotableView
class_name PrintedView

var instance:Node = null

func set_document(_document:Document) -> void:
	assert(_document is Printed)
	super.set_document(_document)
	update_instance()

func open() -> void:
	super.open()

func close() -> void:
	super.close()

func update_instance() -> void:
	if instance:
		instance.queue_free()
	instance = document.page_list[page_index].scene.instantiate() 
	add_child(instance)

func turn_page(_page:int) -> void:
	super.turn_page(_page)
	update_instance()
