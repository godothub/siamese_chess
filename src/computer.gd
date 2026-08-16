extends InspectableItem

func print(text:String) -> void:
	$sub_viewport/texture_rect/margin_container/rich_text_label.add_text(text)

func clear() -> void:
	$sub_viewport/texture_rect/margin_container/rich_text_label.clear()
