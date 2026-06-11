extends Level

@onready var chessboard_sandbox:Chessboard = $chessboard_sandbox

func _ready() -> void:
	super._ready()
	chessboard_sandbox.set_enabled(false)
	Player.add_inspectable_item(chessboard_sandbox)
	$marker_game.connect("procedure_end", game_end)

func use_chessboard() -> void:
	change_state("analysis")
	$chessboard.set_enabled(false)
	chessboard_sandbox.set_enabled(true)
	var state:State = Chess.create_initial_state()
	chessboard_sandbox.state = state
	chessboard_sandbox.remove_piece_set()
	chessboard_sandbox.add_default_piece_set()
	Player.force_set_camera($camera_chessboard)
	$marker_game.start()

func game_end(_result:String) -> void:
	$chessboard.set_enabled(true)
	chessboard_sandbox.set_enabled(false)
	Player.force_set_camera($marker_camera_2/camera)
	change_state("")
