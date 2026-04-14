## root for the gameplay scene.
#  very little logic should occur here, just alert the true root
# when we're done
extends Node

@onready var editor = $Editor
@onready var end_timer = $Fader/EndTimer
@onready var scoring_manager = $ScoringManager

signal level_complete

func _ready():
	end_timer.connect("timeout", _song_complete)
	
	# load settings
	MusicPlayerShinobu.pitch_scale = PlayerSettings.get_pitch_as_mult()

# called by the parent after instantiation
func assign_level(folder_path: String, chart_name: String, editor_active: bool):
	editor.set_active(editor_active)
	editor.load_lvl(folder_path, chart_name)

# cheap force quit button. make it pause in future?
func _process(delta):
	if Input.is_action_just_pressed("lvlr_save"):
		# force break full combo
		scoring_manager.scoring_info.is_full_combo = false
		_song_complete()

# pass forward scoring info
func _song_complete():
	MusicPlayerShinobu.pause()
	if !editor.active:
		emit_signal("level_complete", scoring_manager.scoring_info)
