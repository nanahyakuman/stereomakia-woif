##  handles all the shinobu logic. didn't want it to be an autoload
## tbh but shinobu kinda wants to be interacted with singly/persistently
## so here it is.
extends Node

var group: ShinobuGroup
var soundSource: ShinobuSoundSource
var soundPlayer: ShinobuSoundPlayer

# set and read externally an embarassing amount
var pitch_scale: float = 1.0: 
	set(val):
		pitch_scale = val
		if soundPlayer:
			soundPlayer.pitch_scale = pitch_scale

var prev_load_path: String = ""

func _ready() -> void:
	assert(Shinobu.initialize() == Error.OK, "Shinobu init failed.")
	
	group = Shinobu.create_group("def_group", null)
	group.connect_to_endpoint()
	
	Input.use_accumulated_input = false

# something to load a new song (and discard the old one)
func load_song(path: String):
	# prevent doubly loading a song
	if path == prev_load_path:
		return
	prev_load_path = path
	
	if get_child_count() > 0:
		for c in get_children():
			c.queue_free()
	
	var fa = FileAccess.open(path, FileAccess.READ)
	if !fa:
		return
	var data = fa.get_buffer(fa.get_length())
	fa.close()
	soundSource = Shinobu.register_sound_from_memory(path, data)
	soundPlayer = soundSource.instantiate(group)
	soundPlayer.pitch_scale = pitch_scale
	soundPlayer.volume = .4
	add_child(soundPlayer)
 
# something to play a new song
func pause():
	if !soundPlayer:
		return
	soundPlayer.stop()

func play(offset_s: float = 0.0):
	if !soundPlayer:
		return
	soundPlayer.seek(offset_s * 1000.0)
	soundPlayer.start()

# some realible get_time_ms for logic
func get_playback_position_msec() -> float:
	return soundPlayer.get_playback_position_msec()
func get_playback_position() -> float:
	return soundPlayer.get_playback_position_msec() * .001

func is_playing() -> bool:
	return soundPlayer.is_playing()
func get_length() -> float:
	return soundPlayer.get_length_msec() * .001
