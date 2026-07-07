extends Level

@onready var standard_history_document:Document = load("res://src/doc/history.gd").new()
@onready var standard_chessboard:Chessboard = $table_0/chessboard_standard

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
		$event_explore.travel_to(0x54)
		await $event_explore.animation_finished
	$chessboard.set_enabled(false)
	standard_chessboard.set_enabled(true)
	$event_explore.instance.set_position($chessboard.name_to_vector3("e2"))
	$event_explore.instance.set_rotation(Vector3(0, PI / 2, 0))
	$event_explore.instance.play_animation("thinking")
	signal_container.add_connection($procedure_dialog.procedure_end, dialog_end)
	$procedure_dialog.start()

func dialog_end(_result:String) -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision.procedure_end, decision_end)
	$procedure_decision.start()

func decision_end(_result:String) -> void:
	match _result:
		"":
			interact_pastor_end()
		"YULAN_TALK_DEMO_LEAVE":
			interact_pastor_end()
		"YULAN_TALK_DEMO_MATCH":
			game()
		"YULAN_TALK_DEMO_ANALYSE":
			analyse()

func game() -> void:
	Player.force_set_camera($camera_chessboard)
	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	side_decision()

func side_decision(_result:String = "") -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_side.procedure_end, side_decision_end)
	$procedure_decision_side.start()

func side_decision_end(_result:String) -> void:
	signal_container.disconnect_all()
	match _result:
		"":
			interact_pastor_end()
			return
		"SELECTION_PLAY_AS_WHITE":
			$procedure_game.player_group = 0
		"SELECTION_PLAY_AS_BLACK":
			$procedure_game.player_group = 1
		"SELECTION_PLAY_AS_RANDOM":
			$procedure_game.player_group = randi() % 2
		"YULAN_TALK_DEMO_EDIT":
			edit()
			return
	if $procedure_game.player_group == 0:
		standard_chessboard.rotation.y = 0
	else:
		standard_chessboard.rotation.y = PI
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_game.procedure_end, game_end)
	$procedure_game.start()

func edit() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_edit.procedure_end, edit_end)
	$procedure_edit.start()

func edit_end(_result:String) -> void:
	if _result == "canceled":
		side_decision()
		return
	signal_container.disconnect_all()
	side_decision()

func game_end(_result:String) -> void:
	signal_container.disconnect_all()
	signal_container.add_connection(Dialog.on_next, interact_pastor_end)
	match _result:
		"checkmate_black":
			Dialog.push_dialog("HINT_BLACK_CHECKMATE", "", true, true)
		"checkmate_white":
			Dialog.push_dialog("HINT_WHITE_CHECKMATE", "", true, true)
		"stalemate_black":
			Dialog.push_dialog("HINT_DRAW", "", true, true)
		"stalemate_white":
			Dialog.push_dialog("HINT_DRAW", "", true, true)
		"50_moves":
			Dialog.push_dialog("HINT_DRAW", "", true, true)
		"cleared_black":
			Dialog.push_dialog("HINT_BLACK_CLEARED", "", true, true)
		"cleared_white":
			Dialog.push_dialog("HINT_WHITE_CLEARED", "", true, true)
		"":
			interact_pastor_end()

func interact_pastor_end(_result:String = "") -> void:
	signal_container.disconnect_all()
	Player.force_set_camera($camera)
	$event_explore.instance.play_animation("battle_idle")
	$event_explore.instance.set_position($chessboard.name_to_vector3("e3"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")

func analyse() -> void:
	Player.force_set_camera($camera_chessboard)
	standard_chessboard.state = Chess.create_initial_state()
	standard_chessboard.remove_piece_set()
	standard_chessboard.add_default_piece_set()
	analyse_decision()

func analyse_decision(_result:String = "") -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_analyse.procedure_end, analyse_decision_end)
	$procedure_decision_analyse.start()
	
func analyse_decision_end(_selection:String) -> void:
	signal_container.disconnect_all()
	match _selection:
		"YULAN_TALK_DEMO_PLAY":
			analyse_game()
		"YULAN_TALK_DEMO_EDIT":
			analyse_edit()
		"YULAN_TALK_DEMO_LEAVE":
			interact_pastor_end()
		"":
			interact_pastor_end()
	
func analyse_edit() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_edit.procedure_end, analyse_decision)
	$procedure_edit.start()

func analyse_game() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_game_analyse.procedure_end, analyse_decision)
	$procedure_game_analyse.clean_history()
	$procedure_game_analyse.start()
