extends LevelEvent
class_name EventCamera

@export var camera:Camera3D = null
@export var selection:String = ""
@export_custom(PropertyHint.PROPERTY_HINT_FLAGS, "bitboard") var bit:int = 0

func on_start() -> void:
	#if camera && Chess.mask(Chess.x88_to_c64(Progress.get_value("player_by"))) & bit:
	Player.force_set_camera(camera)

func show_selection() -> String:
	if Player.target_camera != camera:
		return selection
	return ""

func on_selection() -> void:
	Player.force_set_camera(camera)
