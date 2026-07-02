extends LevelProcedure
class_name ProcedureDialog

# 目前的对话，除了显示对话内容以外，还有角色动画播放，以及镜头的转移
# 这个过程是非常线性的

class DialogSentence extends RefCounted:
	@export var content:String
	@export var animation:String

# 一般情况下，文本使用的是key，以至于直接识别逗号是没问题的
@export_multiline("monospace", "no_wrap") var sequence_str:String = ""
@export var animation_player:AnimationPlayer = null
@export var cutscene_camera:Camera3D = null
var sequence:Array[DialogSentence] = []
var signal_container:SignalContainer = SignalContainer.new()

func _ready() -> void:
	var rows:PackedStringArray = sequence_str.split('\n')
	for line:String in rows:
		var sentence:DialogSentence = DialogSentence.new()
		var cols:PackedStringArray = line.split(',')
		sentence.content = cols[0]
		sentence.animation = cols[1]
		sequence.push_back(sentence)

func start() -> void:
	Dialog.set_border_position(false)
	if cutscene_camera:
		Player.force_set_camera(cutscene_camera)
	show_dialog(0)
	
func show_dialog(index:int) -> void:
	signal_container.disconnect_all()
	if index == sequence.size():
		end()
		return
	if sequence[index].animation != "-":
		animation_player.play(sequence[index].animation)
	Dialog.push_dialog(tr(sequence[index].content), "", false, true, false)
	signal_container.add_connection(Dialog.on_next, show_dialog.bind(index + 1))

func end() -> void:
	signal_container.disconnect_all()
	Dialog.set_border_position(Setting.get_value("dialog_border"))
	procedure_end.emit("")
