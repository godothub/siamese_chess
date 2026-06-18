extends Level

@onready var standard_chessboard:Chessboard = $garden_steel_table/chessboard
var standard_player_group:int = 0


func _ready() -> void:
	super._ready()
	Ambient.change_environment_sound(load("res://assets/audio/405135__mjeno__autumn-forest-leaves-falling-close-to-pond-iii-loopable.wav"))
	Player.force_set_camera($camera)
	$marker_actor_carnation.instance.play_animation("sit_and_think")
	$marker_decision.connect("procedure_end", decision_end)
	$marker_game.connect("procedure_end", game_end)

func interact_carnation() -> void:
	change_state("game")
	var carnation_pos:Vector3 = $marker_actor_carnation.global_position
	var current_position_2d:Vector2 = Vector2(global_position.x, global_position.z)
	var target_position_2d:Vector2 = Vector2(carnation_pos.x, carnation_pos.z)
	var target_angle:float = -current_position_2d.angle_to_point(target_position_2d) + PI / 2
	target_angle = global_rotation.y + angle_difference(global_rotation.y, target_angle)
	var cheshire_instance:Actor = $marker_explore.cheshire_instance
	cheshire_instance.rotation.y = target_angle
	standard_chessboard.state = Chess.create_initial_state()
	$marker_decision.start()
	
func decision_end(_result:String) -> void:
	match _result:
		"":
			interact_carnation_end()
			return
		"SELECTION_PLAY_AS_WHITE":
			$marker_game.player_group = 0
		"SELECTION_PLAY_AS_BLACK":
			$marker_game.player_group = 1
		"SELECTION_PLAY_AS_RANDOM":
			$marker_game.player_group = randi() % 2
	if $marker_game.player_group == 0:
		standard_chessboard.rotation.y = -PI / 2
	else:
		standard_chessboard.rotation.y = PI / 2
	standard_chessboard.remove_piece_set()
	Player.force_set_camera($camera_chessboard)
	$marker_game.start()

func game_end(_result:String) -> void:
	interact_carnation_end()

func interact_carnation_end() -> void:
	Player.force_set_camera($camera)
	$marker_explore.cheshire_instance.play_animation("battle_idle")
	$marker_explore.cheshire_instance.set_position($chessboard.name_to_vector3("d6"))
	$chessboard.set_enabled(true)
	standard_chessboard.set_enabled(false)
	change_state("")
