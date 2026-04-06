##  the apps' true root. everpresent
extends Node

const GAME_ROOT = preload("res://game_root.tscn")
const SCORE_SCREEN_ROOT = preload("res://score_screen_root.tscn")
const LEVEL_SELECT_ROOT = preload("res://level_select_root.tscn")

func _ready():
	start_level_select()


func start_level_select():
	if get_child_count() > 0:
		get_child(0).queue_free()
	add_child(LEVEL_SELECT_ROOT.instantiate())
	
	#  rn you dont get prompted for difficulty if you click
	# so disabling the mouse for now
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# called by the level selector
func start_level(folder_path: String, chart_name: String):
	# kill the level selector
	get_child(0).queue_free()
	
	var game_root = GAME_ROOT.instantiate()
	add_child(game_root)
	game_root.assign_level(folder_path, chart_name)
	game_root.connect("level_complete", _end_level)
	
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

# called by gameplay root
func _end_level(scoring_info: ScoringInfo):
	get_child(0).queue_free()
	
	var score_screen_root = SCORE_SCREEN_ROOT.instantiate()
	add_child(score_screen_root)
	score_screen_root.assign_scoring_info(scoring_info)
