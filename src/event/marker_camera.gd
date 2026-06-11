extends MarkerEvent
class_name MarkerCamera

@export var camera:Camera3D = null
@export var selection:String = ""
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func on_start() -> void:
	if camera && level.chessboard.state.get_bit(level.player_king) & bit:
		Player.force_set_camera(camera)

func show_selection() -> String:
	if Player.target_camera != camera:
		return selection
	return ""

func on_selection() -> void:
	Player.force_set_camera(camera)
	level.show_selection.call_deferred()
