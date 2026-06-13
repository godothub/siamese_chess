extends Level

@onready var standard_history_document:Document = load("res://src/doc/history.gd").new()
@onready var standard_chessboard:Chessboard = $table_0/chessboard_standard
@onready var edit_event:MarkerProcedure = $marker_edit
@onready var game_event:MarkerProcedure = $marker_game
var standard_player_group:int = 0

func _ready() -> void:
	super._ready()
	standard_history_document.set_filename("history.match_with_yulan.json")
	standard_history_document.load_file()
	Ambient.change_environment_sound(load("res://assets/audio/52645__kstein1__white-noise.wav"))
	
	standard_chessboard.set_enabled(false)
	Player.add_inspectable_item(standard_chessboard)
	$pastor.play_animation("thinking")
	edit_event.connect("procedure_end", select_turn)
	game_event.connect("procedure_end", game_end)

func interact_pastor() -> void:
	change_state("yulan_game")
	Player.force_set_camera($camera_pastor)

	var from:int = Progress.get_value("player_by", 0)
	if from != 0x54:
		$marker_explore.travel_to(0x54)
		await $marker_explore.animation_finished
	$chessboard.set_enabled(false)
	standard_chessboard.set_enabled(true)
	$marker_explore.cheshire_instance.set_position($chessboard.name_to_vector3("e2"))
	$marker_explore.cheshire_instance.set_rotation(Vector3(0, PI / 2, 0))
	$marker_explore.cheshire_instance.play_animation("thinking")
	Player.force_set_camera($camera_chessboard)

	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	edit_event.start()

func select_turn(result:String) -> void:
	if result == "canceled":
		game_end()
		return
	var selected_func:Callable
	var cancel_func:Callable
	selected_func = func (_selected:String) -> void:
		Dialog.on_cancel.disconnect(cancel_func)
		Dialog.hide_cancel()
		match _selected:
			"SELECTION_PLAY_AS_WHITE":
				standard_player_group = 0
			"SELECTION_PLAY_AS_BLACK":
				standard_player_group = 1
			"SELECTION_PLAY_AS_RANDOM":
				standard_player_group = randi() % 2
		if standard_player_group == 0:
			standard_chessboard.rotation.y = 0
		else:
			standard_chessboard.rotation.y = PI
		game_event.player_group = standard_player_group
		standard_chessboard.remove_piece_set()
		standard_chessboard.add_default_piece_set()
		game_event.start()
	cancel_func = func () -> void:
		game_end()
		Dialog.hide_cancel()
		Dialog.on_select.disconnect(selected_func)
	Dialog.on_cancel.connect(cancel_func, CONNECT_ONE_SHOT)
	Dialog.on_select.connect(selected_func, CONNECT_ONE_SHOT)
	Dialog.show_cancel()
	Dialog.push_selection(["SELECTION_PLAY_AS_BLACK", "SELECTION_PLAY_AS_WHITE", "SELECTION_PLAY_AS_RANDOM"], "", true, false)

func game_end(_result:String = "") -> void:
	Player.force_set_camera($camera)
	$marker_explore.cheshire_instance.play_animation("battle_idle")
	$marker_explore.cheshire_instance.set_position($chessboard.name_to_vector3("e3"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")
