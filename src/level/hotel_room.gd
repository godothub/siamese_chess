extends Level

@onready var chessboard_sandbox:Chessboard = $chessboard_sandbox

func _ready() -> void:
	super._ready()
	chessboard_sandbox.set_enabled(false)
	Player.add_inspectable_item(chessboard_sandbox)
	$procedure_game.connect("procedure_end", game_end)
	$procedure_dialog_rest.connect("procedure_end", rest_end)

func use_chessboard() -> void:
	change_state("analysis")
	$chessboard.set_enabled(false)
	chessboard_sandbox.set_enabled(true)
	var state:State = Chess.create_initial_state()
	chessboard_sandbox.state = state
	chessboard_sandbox.remove_piece_set()
	chessboard_sandbox.add_default_piece_set()
	Player.force_set_camera($camera_chessboard)
	$procedure_game.start()

func game_end(_result:String) -> void:
	$chessboard.set_enabled(true)
	chessboard_sandbox.set_enabled(false)
	Player.force_set_camera($camera_bedroom)
	change_state("")

func interact_rest() -> void:
	change_state("rest")
	$event_explore.instance.get_node("animation_tree").active = false
	Player.force_set_camera($procedure_dialog_rest/camera_3d)
	$procedure_dialog_rest.start()

func rest_end(_result:String) -> void:
	Player.force_set_camera($camera_bedroom)
	$event_explore.instance.get_node("animation_tree").active = true
	$event_explore.instance.play_animation("battle_idle")
	$event_explore.instance.set_position($chessboard.name_to_vector3("d5"))
	change_state("")
