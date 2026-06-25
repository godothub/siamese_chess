extends MarkerEvent
class_name MarkerProcedure

signal procedure_end(result:String)

func start() -> void:
	pass

func end() -> void:
	procedure_end.emit("")
