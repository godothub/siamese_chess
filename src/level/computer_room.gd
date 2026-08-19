extends Level

# 至少，这台电脑可以显示“统计”、“测试”、“登录”
var signal_container:SignalContainer = SignalContainer.new()

func _ready() -> void:
	Ambient.change_environment_sound(load("res://assets/audio/546047__grcekh__analog-crt-tv-electronic-static-noise.wav"))
	Player.add_inspectable_item($computer)
	$computer.set_enabled(false)
	super._ready()

func interact_computer() -> void:
	change_state("computer")
	$chessboard.set_enabled(false)
	$computer.set_enabled(true)
	$event_explore/cheshire.visible = false
	Player.force_set_camera($camera_computer)
	$computer.clear()
	$computer.print(" ____  _                                \n/ ___|(_) __ _ _ __ ___   ___  ___  ___ \n\\___ \\| |/ _` | '_ ` _ \\ / _ \\/ __|/ _ \\\n ___) | | (_| | | | | | |  __/\\__ \\  __/\n|____/|_|\\__,_|_| |_| |_|\\___||___/\\___|\n / ___| |__   ___  ___ ___              \n| |   | '_ \\ / _ \\/ __/ __|             \n| |___| | | |  __/\\__ \\__ \\             \n \\____|_| |_|\\___||___/___/ _           \n / ___|___  _ __  ___  ___ | | ___      \n| |   / _ \\| '_ \\/ __|/ _ \\| |/ _ \\     \n| |__| (_) | | | \\__ \\ (_) | |  __/     \n \\____\\___/|_| |_|___/\\___/|_|\\___|     \n")
	computer_main()

func interact_end() -> void:
	signal_container.disconnect_all()
	$chessboard.set_enabled(true)
	$computer.set_enabled(false)
	$event_explore/cheshire.visible = true
	Player.force_set_camera($camera_3d)
	change_state("")

func computer_main() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_main.procedure_end, computer_main_end)
	$computer.print("---------------------------------\n")
	$computer.print(tr("COMPUTER_ROOM_COMPUTER_GREETING") + "\n")
	$procedure_decision_main.start()

func computer_main_end(result:String) -> void:
	match result:
		"COMPUTER_ROOM_COMPUTER_STATISTICS":
			computer_statistics()
		"COMPUTER_ROOM_COMPUTER_TEST":
			computer_test()
		_:
			interact_end()

func computer_statistics() -> void:
	$computer.print(tr("COMPUTER_ROOM_COMPUTER_STATISTICS_PRINT").format({
		"match_count": Progress.get_value("match_count", 0),
		"wins": Progress.get_value("match_wins", 0),
		"play_time": "%02d:%02d" % [int(Progress.get_value("play_time", 0) / 3600), int(Progress.get_value("play_time", 0) / 60)]
	}))
	computer_main()

func computer_test() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_test.procedure_end, computer_test_decision_end)
	$procedure_decision_test.start()
	$computer.print(tr("COMPUTER_ROOM_COMPUTER_TEST_HINT") + "\n")

var assigned_key:Array = []
func computer_test_decision_end(result:String) -> void:
	signal_container.disconnect_all()
	assigned_key = []
	match result:
		"COMPUTER_ROOM_COMPUTER_TEST_ACTOR_STAGE":
			$computer.run_scene("res://scene/test/actor_stage.tscn")
		"COMPUTER_ROOM_COMPUTER_TEST_DECORATE_TEST":
			$computer.run_scene("res://scene/test/decorate_test.tscn")
			assigned_key.push_back("SELECTION_ROTATE_ITEM")
			assigned_key.push_back("SELECTION_NEXT_ITEM")
		"COMPUTER_ROOM_COMPUTER_TEST_ENGINE_PLAY":
			$computer.run_scene("res://scene/test/engine_play.tscn")
		"COMPUTER_ROOM_COMPUTER_TEST_LICHESS_PUZZLE_TEST":
			$computer.run_scene("res://scene/test/lichess_puzzle_test.tscn")
		"COMPUTER_ROOM_COMPUTER_TEST_MULTIPLAYER_TEST":
			$computer.run_scene("res://scene/test/multiplayer_test.tscn")
		"COMPUTER_ROOM_COMPUTER_TEST_ONLINE_SPEECH_TEST":
			$computer.run_scene("res://scene/test/online_speech_test.tscn")
		_:
			interact_end()
	signal_container.add_connection(Dialog.on_select, on_test_selection.call_deferred)
	assigned_key.push_back("SELECTION_CANCEL")
	Dialog.push_selection(assigned_key, "", false, false)

func on_test_selection(selected:String) -> void:
	match selected:
		"SELECTION_CANCEL":
			computer_test_end()
			return
		"SELECTION_ROTATE_ITEM":
			$computer.button_input("tab_left", true)
			$computer.button_input("tab_left", false)
		"SELECTION_NEXT_ITEM":
			$computer.button_input("tab_right", true)
			$computer.button_input("tab_right", false)
	Dialog.push_selection(assigned_key, "", false, false)

func computer_test_end() -> void:
	$computer.close_scene()
	computer_main()
