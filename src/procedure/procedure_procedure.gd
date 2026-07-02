@abstract
extends Node3D
class_name LevelProcedure

signal procedure_end(result:String)

@onready var level:Level = get_parent()

func start() -> void:
	pass

func end() -> void:
	procedure_end.emit("")
