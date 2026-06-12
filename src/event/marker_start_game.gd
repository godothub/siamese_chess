extends MarkerEvent
class_name MarkerStartGame

@export var group:int = 1
@export var game_event:MarkerEvent = null

func _ready() -> void:
	game_event.connect("procedure_end", game_end)

func on_start() -> void:
	level.change_state("game")
	game_event.start()

func game_end(_result:String = "") -> void:
	level.change_state("")
