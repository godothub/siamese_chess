extends Level

@onready var standard_history_document:Document = load("res://src/doc/history.gd").new()
@onready var standard_chessboard:Chessboard = $table_0/chessboard_standard
@onready var edit_event:Procedure = $marker_edit
@onready var decision_event:Procedure = $marker_decision
@onready var game_event:Procedure = $marker_game

var signal_container:SignalContainer = SignalContainer.new()

func _ready() -> void:
	super._ready()
	standard_history_document.set_filename("history.match_with_yulan.json")
	standard_history_document.load_file()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	
	standard_chessboard.set_enabled(false)
	Player.add_inspectable_item(standard_chessboard)
	$pastor.play_animation("thinking")

func interact_pastor() -> void:
	change_state("yulan_game")
	Player.force_set_camera($camera_pastor)

	var from:int = Progress.get_value("player_by", 0)
	if from != 0x54:
		$marker_explore.travel_to(0x54)
		await $marker_explore.animation_finished
	$chessboard.set_enabled(false)
	standard_chessboard.set_enabled(true)
	$marker_explore.instance.set_position($chessboard.name_to_vector3("e2"))
	$marker_explore.instance.set_rotation(Vector3(0, PI / 2, 0))
	$marker_explore.instance.play_animation("thinking")
	Player.force_set_camera($camera_chessboard)

	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	signal_container.disconnect_all()
	signal_container.add_connection(edit_event.procedure_end, edit_end)
	edit_event.start()

func edit_end(_result:String) -> void:
	if _result == "canceled":
		game_end()
		return
	signal_container.disconnect_all()
	signal_container.add_connection(decision_event.procedure_end, decision_end)
	decision_event.start()

func decision_end(_result:String) -> void:
	match _result:
		"":
			game_end()
			return
		"SELECTION_PLAY_AS_WHITE":
			game_event.player_group = 0
		"SELECTION_PLAY_AS_BLACK":
			game_event.player_group = 1
		"SELECTION_PLAY_AS_RANDOM":
			game_event.player_group = randi() % 2
	if game_event.player_group == 0:
		standard_chessboard.rotation.y = 0
	else:
		standard_chessboard.rotation.y = PI
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	
	signal_container.disconnect_all()
	signal_container.add_connection(game_event.procedure_end, game_end)
	game_event.start()

func game_end(_result:String = "") -> void:
	signal_container.disconnect_all()
	Player.force_set_camera($camera)
	$marker_explore.instance.play_animation("battle_idle")
	$marker_explore.instance.set_position($chessboard.name_to_vector3("e3"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")
