extends Node3D
class_name Level

var player_group:int = 1
var player_all:int = 0
var player_king:int = 0
var enemy_all:int = 0
var enemy_king:int = 0

@onready var chessboard:Chessboard = $chessboard
var teleport:Dictionary = {}
var events:Array = []
var title:Dictionary[int, String] = {}

func _ready() -> void:
	player_all = ord("A") if player_group == 0 else ord("a")
	player_king = ord("K") if player_group == 0 else ord("k")
	enemy_all = ord("a") if player_group == 0 else ord("A")
	enemy_king = ord("k") if player_group == 0 else ord("K")

	var state:State = State.new()
	chessboard.set_state(state)
	Player.add_inspectable_item(chessboard)
	for node:Node in get_children():
		if node is LevelEvent:
			events.push_back(node)
			node.on_init()
	Progress.create_if_not_exist("obtains", 0)
	Progress.create_if_not_exist("wins", 0)
	event_start.call_deferred()

func change_state(state:String) -> void:
	for event:LevelEvent in events:
		event.on_change_state(state)

func event_start() -> void:
	for iter:LevelEvent in events:
		iter.on_start()

var available_events:Dictionary = {}

func show_selection(by:int) -> void:
	var selections:PackedStringArray = []
	available_events.clear()
	for iter:LevelEvent in events:
		var selection:String = iter.show_selection()
		if selection != "":
			available_events[selection] = iter
			selections.push_back(selection)
	selections.erase("")
	Dialog.push_selection(selections, title.get(by, ""), false, false)

func on_exit() -> void:
	for iter:LevelEvent in events:
		iter.on_exit()
