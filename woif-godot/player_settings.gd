extends Node

# speed vars that we actually expose to player.
# inverting here saves a ton of divisions
@export var player_set_scroll_mod = 8.0: 
	set(val):
		player_set_scroll_mod = val
		player_set_scroll_mod_inv = 1.0 / val
var player_set_scroll_mod_inv = .1

@export var player_set_repitch_semitones = 0.0

# game offset
@export var player_set_game_offset = -.03

# mesh detail. inverted here to save a million divisions a frame
@export var mesh_detail = 2.0: 
	set(val):
		mesh_detail = val
		mesh_detail_inv = 1.0 / val
var mesh_detail_inv = 1.0 / mesh_detail

# linear speed
const base_scroll_mult = 60.0
# circ speed (inv)
const base_circle_time = 14.0


# these are calculated at runtime rn
func get_speed():
	return base_scroll_mult * player_set_scroll_mod
func get_circ_time():
	return base_circle_time * player_set_scroll_mod_inv

# get the pitch mod as a multiplier
const semitone_ratio = pow(2, 1.0 / 12.0)
func get_pitch_as_mult():
	return pow(semitone_ratio, player_set_repitch_semitones)


func load_from_json():
	var load_file = FileAccess.open("user://settings.txt", FileAccess.READ)
	var dict = {} 
	if load_file:
		dict = JSON.parse_string(load_file.get_as_text())
	
	if dict.has("player_set_scroll_mod"):
		player_set_scroll_mod = dict["player_set_scroll_mod"]
	if dict.has("player_set_repitch_semitones"):
		player_set_repitch_semitones = dict["player_set_repitch_semitones"]
	if dict.has("player_set_game_offset"):
		player_set_game_offset = dict["player_set_game_offset"]
	if dict.has("mesh_detail"):
		mesh_detail = dict["mesh_detail"]

func save_to_json():
	var load_file = FileAccess.open("user://settings.txt", FileAccess.WRITE)
	var dict = {
		"player_set_scroll_mod": player_set_scroll_mod,
		"player_set_repitch_semitones": player_set_repitch_semitones,
		"player_set_game_offset": player_set_game_offset,
		"mesh_detail": mesh_detail
	}
	load_file.store_line(JSON.stringify(dict, "\t"))
	
