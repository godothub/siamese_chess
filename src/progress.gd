extends Node

# 全局存档系统
# 由于Archive名称已占用，故命名Progress，也就是游玩进展
# 这里的存档区分于Archive，Archive是允许跨越多个存档的文件机制

var table:Dictionary = {}

func load_file() -> void:
	var file:FileAccess = FileAccess.open("user://progress/prototype_2.json", FileAccess.READ)
	if !is_instance_valid(file):
		return
	table = JSON.parse_string(file.get_as_text())
	file.close()

func save_file() -> void:
	var dir:DirAccess = DirAccess.open("user://progress")
	if !dir:
		DirAccess.make_dir_absolute("user://progress")
		dir = DirAccess.open("user://progress")
	var file:FileAccess = FileAccess.open("user://progress/prototype_2.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(table))
	file.close()

func has_key(key:String) -> bool:
	return table.has(key)

func get_value(key:String, default:Variant = null) -> Variant:
	if table.has(key):
		return table[key]
	return default

func set_value(key:String, data:Variant) -> void:
	table[key] = data

func accumulate(key:String, data:Variant) -> void:
	if !table.has(key):
		table[key] = data
	table[key] += data

func create_if_not_exist(key:String, data:Variant) -> void:
	if !has_key(key):
		table[key] = data
