extends Control

# 准备好lichess.org的评分数据库，解压后大约89GB
@export_global_file("*.jsonl") var filepath:String = ""
var file:FileAccess = null
var nnue:NNUE = null
var loss_sum:float = 0
var loss_list:Array = []
var step:int = 0
var desire:float = 0
var actual:float = 0
@onready var chessboard:Node2D = $chessboard_flat
@onready var label_actual:Label = $label_actual
@onready var label_desire:Label = $label_desire

func _ready() -> void:
	nnue = NNUE.new()
	nnue.randomize_weight()
	var thread:Thread = Thread.new()
	thread.start(read_file)

func _physics_process(_delta:float) -> void:
	label_actual.text = "loss: %.3f%%\nstep: %d" % [loss_sum / loss_list.size() * 100 if loss_list.size() else 0.0, step]
	label_desire.text = "desire %.3f%%\n actual:%.3f%%" % [desire * 100, actual * 100]

func read_file() -> void:
	file = FileAccess.open(filepath, FileAccess.READ)
	if !file:
		print(error_string(FileAccess.get_open_error()))
		return
	while !file.eof_reached():
		var json:String = file.get_line()
		var dict:Dictionary = JSON.parse_string(json)
		var state:State = Chess.parse(dict["fen"])
		var score:float = 0
		var first_evals:Dictionary = dict["evals"][0]
		var first_pvs:Dictionary = first_evals["pvs"][0]
		if first_pvs.has("mate"):
			if first_pvs["mate"] > 0:
				score = 1
			else:
				score = 0
		else:
			score = (first_pvs["cp"]) / 200.0
			score = 1.0 / (1.0 + exp(-score))
		learn(state, score)

func learn(state:State, desire_score:float) -> void:
	var nnue_instance:NNUEInstance = nnue.create_instance(state)
	nnue.feedforward(state, nnue_instance)
	desire = desire_score
	actual = nnue_instance.get_output()
	var loss = (nnue_instance.get_output() - desire_score) * (nnue_instance.get_output() - desire_score)
	loss_sum += loss
	if loss_list.size() >= 1000:
		loss_sum -= loss_list.front()
		loss_list.pop_front()
	loss_list.push_back(loss)
	step += 1
	nnue.feedback(nnue_instance, desire_score)
	await get_tree().create_timer(0.5).timeout
