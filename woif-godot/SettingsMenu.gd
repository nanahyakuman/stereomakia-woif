extends PanelContainer

@onready var pitch_slider = $VBoxContainer/PitchSlider
@onready var speed_slider = $VBoxContainer/SpeedSlider
@onready var def_node = $VBoxContainer/PitchSlider/HSlider
@onready var detail_slider = $VBoxContainer/DetailSlider
@onready var offset_slider = $VBoxContainer/OffsetSlider

# tracks what had focus previously so we can return to the button
var prev_focus_node = null

func _ready():
	visible = false
	
	PlayerSettings.load_from_json()
	
	# abstracting this out is gonna be more work than doing it manually
	pitch_slider.connect("value_changed", _repitch)
	pitch_slider.set_value(PlayerSettings.player_set_repitch_semitones * 100)
	
	speed_slider.connect("value_changed", _change_speed)
	speed_slider.set_value(PlayerSettings.player_set_scroll_mod)
	
	detail_slider.connect("value_changed", _change_detail)
	detail_slider.set_value(PlayerSettings.mesh_detail)
	
	offset_slider.connect("value_changed", _change_offset)
	offset_slider.set_value(PlayerSettings.player_set_game_offset)
	
	# saving is perfomed by the selector

func _input(event):
	if event.is_action_pressed("lvlr_pause"):
		visible = !visible
		
		if visible:
			prev_focus_node = get_viewport().gui_get_focus_owner()
			def_node.grab_focus()
		else:
			prev_focus_node.grab_focus()

func _repitch(val):
	PlayerSettings.player_set_repitch_semitones = val / 100
	MusicPlayerShinobu.pitch_scale = PlayerSettings.get_pitch_as_mult()

func _change_speed(val):
	PlayerSettings.player_set_scroll_mod = val

func _change_detail(val):
	PlayerSettings.mesh_detail = val

func _change_offset(val):
	PlayerSettings.player_set_game_offset = val
	
