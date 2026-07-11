extends Node2D

func _ready() -> void:
	Dialog.push_dialog("这是一段测试对话", "CHAR_YULAN", true, true)
	await Dialog.on_next
	Dialog.push_dialog("这次使用全局对话框，可能会占用一部分的画面", "CHAR_YULAN", true, true)
	await Dialog.on_next
	Dialog.push_dialog("不过，我们会在操作时穿插对话、注解以及选项", "CHAR_YULAN", true, true)
	await Dialog.on_next
	Dialog.push_dialog("现在进行3秒间隔测试，该对话不可跳过", "CHAR_YULAN", true, false)
	await get_tree().create_timer(3).timeout
	Dialog.push_dialog("接下来是选项", "CHAR_YULAN", false, true)
	await Dialog.on_next
	Dialog.push_selection(["选项1", "选项2", "选项3"], "", false, false)
	await Dialog.on_next
	Dialog.push_selection(["选项4", "选项5", "选项6"], "", true, true)
