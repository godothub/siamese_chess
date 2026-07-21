extends LevelEvent
class_name EventStartGame

@export var group:int = 1
@export var game_event:LevelProcedure = null

func _ready() -> void:
	game_event.connect("procedure_end", game_end)

func on_start() -> void:
	# level.change_state("game")
	game_event.start()

func game_end(_result:String = "") -> void:
	#level.change_state("")
	pass
