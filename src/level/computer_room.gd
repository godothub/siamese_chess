extends Level

# 至少，这台电脑可以显示“统计”、“测试”、“登录”
var signal_container:SignalContainer = SignalContainer.new()

func _ready() -> void:
	Ambient.change_environment_sound(load("res://assets/audio/546047__grcekh__analog-crt-tv-electronic-static-noise.wav"))
	super._ready()

func interact_computer() -> void:
	change_state("computer")
	$chessboard.set_enabled(false)
	$event_explore/cheshire.visible = false
	Player.force_set_camera($camera_computer)
	computer_main()

func interact_end() -> void:
	signal_container.disconnect_all()
	$chessboard.set_enabled(true)
	$event_explore/cheshire.visible = true
	Player.force_set_camera($camera_3d)
	change_state("")

func computer_main() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_main.procedure_end, computer_main_end)
	$computer.clear()
	$computer.print(" ____  _                                \n/ ___|(_) __ _ _ __ ___   ___  ___  ___ \n\\___ \\| |/ _` | '_ ` _ \\ / _ \\/ __|/ _ \\\n ___) | | (_| | | | | | |  __/\\__ \\  __/\n|____/|_|\\__,_|_| |_| |_|\\___||___/\\___|\n / ___| |__   ___  ___ ___              \n| |   | '_ \\ / _ \\/ __/ __|             \n| |___| | | |  __/\\__ \\__ \\             \n \\____|_| |_|\\___||___/___/ _           \n / ___|___  _ __  ___  ___ | | ___      \n| |   / _ \\| '_ \\/ __|/ _ \\| |/ _ \\     \n| |__| (_) | | | \\__ \\ (_) | |  __/     \n \\____\\___/|_| |_|___/\\___/|_|\\___|     \n")
	$computer.print("---------------------------------\n")
	$computer.print(tr("COMPUTER_ROOM_COMPUTER_GREETING") + "\n")
	$procedure_decision_main.start()

func computer_main_end(result:String) -> void:
	match result:
		"COMPUTER_ROOM_COMPUTER_STATISTICS":
			computer_statistics()
		"COMPUTER_ROOM_COMPUTER_TEST":
			computer_test()
		"COMPUTER_ROOM_COMPUTER_LOGIN":
			pass
		_:
			interact_end()

func computer_statistics() -> void:
	computer_main()

func computer_test() -> void:
	signal_container.disconnect_all()
	signal_container.add_connection($procedure_decision_test.procedure_end, computer_test_decision_end)
	$procedure_decision_test.start()
	$computer.print(tr("COMPUTER_ROOM_COMPUTER_TEST_HINT") + "\n")

func computer_test_decision_end(result:String) -> void:
	signal_container.disconnect_all()
	match result:
		"COMPUTER_ROOM_COMPUTER_TEST_ACTOR_STAGE":
			$computer.run_scene("res://scene/test/actor_stage.tscn")
		"COMPUTER_ROOM_COMPUTER_TEST_DECORATE_TEST":
			$computer.run_scene("res://scene/test/decorate_test.tscn")
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
	signal_container.add_connection(Dialog.on_next, computer_test_end.call_deferred)
	Dialog.push_selection(["SELECTION_CANCEL"], "", false, false)

func computer_test_end() -> void:
	$computer.close_scene()
	computer_main()
