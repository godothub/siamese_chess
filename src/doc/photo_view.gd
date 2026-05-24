extends NotableView
class_name PhotoView

func set_document(_document:Document) -> void:
	assert(_document is Photo)
	super.set_document(_document)
	update_image()

func open() -> void:
	super.open()

func close() -> void:
	super.close()

func update_image() -> void:
	$sprite_2d.texture = ImageTexture.create_from_image(document.page_list[page_index].image)

func turn_page(_page:int) -> void:
	super.turn_page(_page)
	update_image()
