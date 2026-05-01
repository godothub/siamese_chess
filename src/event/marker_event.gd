@abstract
extends Node3D
class_name MarkerEvent

@onready var level:Level = get_parent()

# 场景事件机制需要将选项和自动触发事件整合在一起
# 需要判断什么时候显示选项，在生命周期的某个时候触发

func on_init() -> void:
	pass

func on_start() -> void:
	pass

func on_turn() -> void:
	pass

func show_selection() -> String:
	return ""

func on_selection() -> void:
	pass
