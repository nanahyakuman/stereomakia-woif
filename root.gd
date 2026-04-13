##  the apps' true root. everpresent
extends Node

const GAME_ROOT = preload("res://game_root.tscn")
const SCORE_SCREEN_ROOT = preload("res://score_screen_root.tscn")
const LEVEL_SELECT_ROOT = preload("res://level_select_root.tscn")
const TITLE_SCREEN_ROOT = preload("uid://exl2hvdedg3t")

func _ready():
	#_start_title_screen()
	
	start_level_select()
	
	#start_level("res://lvl/tensionnn", "3")


func _start_title_screen():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if get_child_count() > 0:
		get_child(0).queue_free()
	
	var tsr: TitleScreenRoot = TITLE_SCREEN_ROOT.instantiate()
	add_child(tsr)
	# tsr has more signals but those screens arent implemented yet
	tsr.level_select_pressed.connect(start_level_select)

func start_level_select():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if get_child_count() > 0:
		get_child(0).queue_free()
	add_child(LEVEL_SELECT_ROOT.instantiate())


# called by the level selector
func start_level(folder_path: String, chart_name: String):
	# level decides whether to hide the mouse or not
	
	# kill the level selector
	if get_child_count() > 0:
		get_child(0).queue_free()
	
	var game_root = GAME_ROOT.instantiate()
	add_child(game_root)
	game_root.assign_level(folder_path, chart_name)
	game_root.connect("level_complete", _end_level)

# called by gameplay root by signal
func _end_level(scoring_info: ScoringInfo):
	if get_child_count() > 0:
		get_child(0).queue_free()
	
	var score_screen_root = SCORE_SCREEN_ROOT.instantiate()
	add_child(score_screen_root)
	score_screen_root.assign_scoring_info(scoring_info)
