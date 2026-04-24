extends Node

@onready var note_holder = $"../NoteHolder"
@onready var input_manager = $"../InputManager"
@onready var notes = $"../NoteHolder/Notes"
@onready var tap_notes = $"../NoteHolder/Notes/TapNotes".get_children()
@onready var hold_notes = $"../NoteHolder/Notes/HoldNotes".get_children()
@onready var scoring_manager = $"../ScoringManager"
@onready var circle_tap_notes_left = $"../NoteHolder/Notes/CircleTapNotesLeft"
@onready var circle_tap_notes_right = $"../NoteHolder/Notes/CircleTapNotesRight"
@onready var circle_hold_notes_left = $"../NoteHolder/Notes/CircleHoldNotesLeft"
@onready var circle_hold_notes_right = $"../NoteHolder/Notes/CircleHoldNotesRight"
@onready var circle_release_notes_left = $"../NoteHolder/Notes/CircleReleaseNotesLeft"
@onready var circle_release_notes_right = $"../NoteHolder/Notes/CircleReleaseNotesRight"
@onready var beatlines = $"../NoteHolder/Notes/Beatlines"
@onready var waveform_sprite_2d: Sprite2D = $"../NoteHolder/Notes/Waveform/Sprite2D"
@onready var gui: Control = $GUI
@onready var division_label: Label = $GUI/DivisionLabel
@onready var current_division_label: Label = $GUI/CurrentDivisionLabel
@onready var logger: VBoxContainer = %Logger
@onready var circle_note_l: CircleNoteGUI = $GUI/NoteGUI/CircleNoteL
@onready var circle_note_r: CircleNoteGUI = $GUI/NoteGUI/CircleNoteR

@onready var scroll_graph_creator: GraphCreator = $"GUI/MouseGUI/TabContainer/Scroll Speed Mod/ScrollGraphCreator"
@onready var glitch_graph_creator: GraphCreator = $GUI/MouseGUI/TabContainer/Glitch/GlitchGraphCreator
@onready var graphs = [
	scroll_graph_creator,
	glitch_graph_creator
]
@onready var filterer: Filterer = $"../Filterer"

const HOLD_NOTE_CIRCULAR = preload("res://notes/hold_note_circular.tscn")
const HOLD_NOTE_LINEAR = preload("res://notes/hold_note_linear.tscn")
const TAP_NOTE_CIRCULAR = preload("res://notes/tap_note_circular.tscn")
const TAP_NOTE_LINEAR = preload("res://notes/tap_note_linear.tscn")
const RELEASE_NOTE_CIRCULAR = preload("res://notes/release_note_circular.tscn")
const BEATLINE = preload("res://beatline.tscn")

#  the input manager sets itself to the opposite of this at runtime,
# so it's not killing our notes from under us

@export var active = false

# assigned when load is called so we know where to save
var folder_path = ""
var diff = ""

# read from the file. 
var song_artist = "NO NAME"
var chart_artist = "nanashi"

var paused = false
var pause_offset = 0.0
var offset_as_frac = Fraction.new(0,0,1)

#  'official' fractions, should support weider ones later.
# keep in mind working with beats instead of bars our baseline
# is 4x closer than most other games would be, so 1/32 is a ddr 128th note
var beat_fracs = [
	Fraction.new(1,0,1, false),
	Fraction.new(0,1,2, false),
	Fraction.new(0,1,3, false),
	Fraction.new(0,1,4, false),
	Fraction.new(0,1,5, false),
	Fraction.new(0,1,6, false),
	Fraction.new(0,1,7, false),
	Fraction.new(0,1,8, false),
	Fraction.new(0,1,16, false),
	Fraction.new(0,1,24, false),
	Fraction.new(0,1,32, false),
]
var beat_frac_i = 0

# dirs in order
const dir_input_order = [
	"note_l_2",
	"note_d_2",
	"note_u_2",
	"note_r_2",
	"note_bumper_l",
	"note_bumper_r",
	
]
# use this for hold editing logic
var editor_held_dirs = {}

#  lookup dicts for notes. its a String: Array[Note] pair but notes aren't
# sorted by type, just dumped in
var notes_dict = {}

var ph: PaletteHolder

func _ready():
	# attach to ui signals
	for ln: LinearNoteGUI in gui.get_linear_notes():
		ln.connect("ui_erase_request", _ui_request_note_erasure)
		ln.connect("ui_add_tap_request", _ui_request_tap_note_addition)
		ln.connect("ui_add_hold_request", _ui_request_hold_note_addition)
	
	for circle_ui: CircleNoteGUI in [circle_note_l, circle_note_r]:
		circle_ui.connect("ui_erase_request", _ui_request_note_erasure)
		circle_ui.connect("ui_add_circle_tap_request", _ui_request_circle_tap_addition)
		circle_ui.connect("ui_add_circle_hold_request", _ui_request_circle_hold_addition)
		circle_ui.connect("ui_add_circle_release_request", _ui_request_circle_release_addition)
	

# only call on startup plox
func set_active(val):
	active = val
	
	gui.visible = active
	if active:
		change_subdiv(0)
		note_holder.scale = Vector2(.6,.6)
		note_holder.position.y = 360 - 80
		current_division_label.text = offset_as_frac.as_string()
		call_deferred("load_img")
		waveform_sprite_2d.visible = true
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		note_holder.scale = Vector2(1.0,1.0)
		note_holder.position.y = 360
		waveform_sprite_2d.visible = false
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# actual editing
func _process(delta):
	if !active:
		return
	
	# give the graphs the time
	for graph in graphs:
		graph.assign_time(note_holder.song_timer)
	
	# pause handling
	if Input.is_action_just_pressed("lvlr_pause"):
		_pause(!paused)
	
	# disable editing if playing (for now)
	if !paused:
		return
	
	# window toggle. relocate save once appropriate
	if Input.is_action_just_pressed("lvlr_save"):
		gui.toggle_gui()
		_save_lvl(folder_path, diff)
	
	# seeking w frac snap
	var mod = 1
	if Input.is_action_pressed("lvlr_mod_1"):
		mod *= 16
	if Input.is_action_just_pressed("lvlr_seek_back"):
		_seek(-mod)
	if Input.is_action_just_pressed("lvlr_seek_forward"):
		_seek(mod)
	
	# snap adj
	if Input.is_action_just_pressed("lvlr_snap_up"):
		change_subdiv(1)
	if Input.is_action_just_pressed("lvlr_snap_down"):
		change_subdiv(-1)
	
	#  discard input when in the mouse gui. note this means we still
	# perform the above seek logic. this is allowed
	if gui.is_mouse_mode:
		return
	
	# place note
	for i in 6:
		if Input.is_action_just_pressed(dir_input_order[i]):
			_editor_press_note(offset_as_frac, i)
		if Input.is_action_just_released(dir_input_order[i]):
			_editor_release_note(offset_as_frac, i)
	
	#  zooming.
	if Input.is_action_just_released("scroll_u"):
		PlayerSettings.player_set_scroll_mod *= 1.4
		note_holder.update_notes()
	if Input.is_action_just_released("scroll_d"):
		PlayerSettings.player_set_scroll_mod /= 1.4
		note_holder.update_notes()


func _pause(val: bool):
	if val:
		pause_offset = MusicPlayerShinobu.get_playback_position()
		MusicPlayerShinobu.pause()
		note_holder.set_process(false)
	else:
		# the player will be started by noteholder if it isnt here
		if pause_offset > 0.0:
			MusicPlayerShinobu.play(pause_offset)
		note_holder.song_timer = pause_offset # calc timer should be calc'd off of this
		note_holder.set_process(true)
		
	paused = val

func change_subdiv(amt: int):
	beat_frac_i = clampi(beat_frac_i+amt, 0, beat_fracs.size()-1)
	division_label.text = beat_fracs[beat_frac_i].as_string().substr(2)

func _seek(mod: float):
	if !paused:
		pause_offset = MusicPlayerShinobu.get_playback_position()

	# snap to beat
	offset_as_frac = note_holder.calculate_from_offset(pause_offset, beat_fracs[beat_frac_i].denominator)
	# add mod
	offset_as_frac = offset_as_frac.added(Fraction.new(0, mod, beat_fracs[beat_frac_i].denominator))
	current_division_label.text = offset_as_frac.as_string()
	pause_offset = note_holder.calculate_realtime_at(offset_as_frac)
	
	note_holder.song_timer = pause_offset
	note_holder.update_notes()
	if !paused and pause_offset >= 0.0:
		MusicPlayerShinobu.play(pause_offset)
	
	_update_ui_for_current_time()

#  called when you try to add a note from the ingame editor. has some logic to
# toggle through note types and stuff
func _editor_press_note(time: Fraction, track: int):
	# find the note if it already exists
	var note = _find_note(time, track)
	# just add the note if it doesnt exist
	if note == null:
		editor_held_dirs[track] = _add_note(time, track, Input.is_action_pressed("lvlr_mod_2"), Input.is_action_pressed("lvlr_mod_1"), Fraction.new(0,0,1,true))
	else:
		_remove_note(note)
		# also clear associated holds
		var hold = note.associated_hold
		if hold:
			_remove_note(hold)
		editor_held_dirs.erase(track)
	# call update
	note_holder.update_notes()

func _editor_release_note(time: Fraction, track: int):
	# no hold if we havent moved
	if !editor_held_dirs.has(track) or editor_held_dirs[track].frac.equals(time) or time.less_than(editor_held_dirs[track].frac):
		return
	# otherwise add a hold
	editor_held_dirs[track].associated_hold = _add_hold(editor_held_dirs[track].frac, track, time.subtracted(editor_held_dirs[track].frac))
	# call update
	note_holder.update_notes()

# called by the indicators
func circle_pressed(is_right: bool, dir: float):
	if !active or !paused:
		return
	
	# no mods is a tap
	if !Input.is_action_pressed("lvlr_mod_1") and !Input.is_action_pressed("lvlr_mod_2"):
		# find a extant note to delete
		var note = _find_circle_note(offset_as_frac, is_right)
		if !note:
			# mod 2 is a release
			_add_circle_note(offset_as_frac, is_right, dir, false)
		else:
			while note and is_instance_valid(note):
				_remove_note(note)
				note = note.next_hold
	
	# mod1 and mod2 are not mutually exclusive,
	# so you can add a hold and a release at the same time
	
	# mod 2 is a release
	if Input.is_action_pressed("lvlr_mod_2"):
	# find a extant note to delete
		var note = _find_circle_release(offset_as_frac, is_right)
		if !note:
			# mod 2 is a release
			_add_circle_note(offset_as_frac, is_right, dir, true)
		else:
			while note and is_instance_valid(note):
				_remove_note(note)
				note = note.next_hold
	
	# mod 1 is a hold
	if Input.is_action_pressed("lvlr_mod_1"):
		_try_add_circle_hold(is_right, dir)
	
	# call update
	note_holder.update_notes()

#  pulled out so we can call it for the ui.
# creates a hold and connects it
func _try_add_circle_hold(is_right: bool, dir: float):
	var same_time_hold = _find_circle_hold_by_terminus(offset_as_frac, is_right)
	# remove a hold and its children
	if same_time_hold:
		var note = same_time_hold
		while note and is_instance_valid(note):
			_remove_note(note)
			note = note.next_hold
	else:
		var prev_info = _find_preceding_circle_note_or_hold(offset_as_frac, is_right)
		if prev_info:
			prev_info[2].next_hold = _add_circle_hold(prev_info[0], is_right, prev_info[1], offset_as_frac.subtracted(prev_info[0]), dir)


# add the indicated note
func _add_note(time: Fraction, track: int, double: bool = false, absolute: bool = false, also_hold: Fraction = Fraction.new(0,0,1,true)):
	var n = TAP_NOTE_LINEAR.instantiate()
	tap_notes[track].add_child(n)
	n.frac = time
	n.calculated_offset = note_holder.calculate_offset_at(n.frac)
	n.set_cast(track)
	n.set_doubled(double)
	n.set_absolute(absolute)
	scoring_manager.register_tap()
	
	_add_note_to_dict(n)
	
	if !also_hold.equals(Fraction.new(0)):
		var h = _add_hold(time, track, also_hold)
		n.associated_hold = h
	
	# super redundant a lot of the time
	_update_ui_for_current_time()
	
	return n

func _add_hold(time: Fraction, track: int, len: Fraction):
	var h = HOLD_NOTE_LINEAR.instantiate()
	hold_notes[track].add_child(h)
	h.frac = time
	h.calculated_offset = note_holder.calculate_offset_at(h.frac)
	h.set_len(note_holder.calculate_offset_at(h.frac.added(len)) - (note_holder.calculate_offset_at(h.frac)), len)
	h.set_cast(track)
	scoring_manager.register_hold(h._calculated_len)
	
	_add_note_to_dict(h)
	
	return h

func _add_circle_note(time: Fraction, is_right: bool, angle, is_release: bool):
	var n
	# tap
	if !is_release:
		n = TAP_NOTE_CIRCULAR.instantiate()
		if is_right:
			circle_tap_notes_right.add_child(n)
		else:
			circle_tap_notes_left.add_child(n)
	else:
		n = RELEASE_NOTE_CIRCULAR.instantiate()
		if is_right:
			circle_release_notes_right.add_child(n)
		else:
			circle_release_notes_left.add_child(n)
	
	n.frac = time
	n.calculated_offset = note_holder.calculate_offset_at(n.frac)
	n.is_right = is_right
	n._dir = angle
	scoring_manager.register_circle_tap()
	
	_add_note_to_dict(n)
	# super redundant a lot of the time
	_update_ui_for_current_time()
	return n

func _add_circle_hold(time: Fraction, is_right: bool, angle, hold_len: Fraction, hold_dir):
	var h = HOLD_NOTE_CIRCULAR.instantiate()
	var which_node = circle_hold_notes_right if is_right else circle_hold_notes_left
	which_node.add_child(h)
	h.frac = time
	h.calculated_offset = note_holder.calculate_offset_at(h.frac)
	h.start_dir = angle
	h.frac_len = hold_len
	h.calculated_len = note_holder.calculate_offset_at(h.frac.added(hold_len)) - (note_holder.calculate_offset_at(h.frac))
	h.new_dir = hold_dir
	h.is_right = is_right
	h.is_editor = active
	scoring_manager.register_circle_hold(h.calculated_len)
	
	_add_circle_hold_to_dict(h)
	# super redundant a lot of the time
	_update_ui_for_current_time()
	return h

# dict management. recall that the dict doesn't do any type enforcement
func _add_note_to_dict(note):
	var fracstr = note.frac.as_string()
	if notes_dict.has(fracstr):
		notes_dict[fracstr].append(note)
	else:
		notes_dict[fracstr] = [note]
	_update_ui_for_current_time()

#  circle holds are indexed by when they complete, not when they start.
# this makes them easier to send to the ui.
func _add_circle_hold_to_dict(note: HoldNoteCircular):
	var fracstr = note.frac.added(note.frac_len).as_string()
	if notes_dict.has(fracstr):
		notes_dict[fracstr].append(note)
	else:
		notes_dict[fracstr] = [note]
	_update_ui_for_current_time()

func _remove_note_from_dict(note):
	var fracstr
	#  holds are indexed from their ends
	if note is HoldNoteCircular:
		fracstr = note.frac.added(note.frac_len).as_string()
	else:
		fracstr = note.frac.as_string()
	if notes_dict.has(fracstr):
		notes_dict[fracstr].erase(note)
	_update_ui_for_current_time()



#  find a note. this might be really slow on bigger levels.
# TODO: rework these to take advantage of the note dict
func _find_note(time: Fraction, track: int):
	for n in tap_notes[track].get_children():
		if n.frac.equals(time):
			return n
	return null
func _find_circle_note(time: Fraction, is_right: bool):
	for n in (circle_tap_notes_right if is_right else circle_tap_notes_left).get_children():
		if n.frac.equals(time):
			return n
	return null
func _find_circle_release(time: Fraction, is_right: bool):
	for n in (circle_release_notes_right if is_right else circle_release_notes_left).get_children():
		if n.frac.equals(time):
			return n
	return null
func _find_circle_hold_by_terminus(time: Fraction, is_right: bool):
	for n in (circle_hold_notes_right if is_right else circle_hold_notes_left).get_children():
		if n.frac.added(n.frac_len).equals(time):
			return n
	return null
#  allow us to regen holds to snap to the previous note
# return an array, first arg is fractime, second is dir
func _find_preceding_circle_note_or_hold(time: Fraction, is_right: bool):
	var hold_calc_frac = null
	var earliest_hold_note = null
	for h in circle_hold_notes_right.get_children() if is_right else circle_hold_notes_left.get_children():
		if h.frac.less_than(time) and (!hold_calc_frac or hold_calc_frac.less_than(h.frac.added(h.frac_len))):
			earliest_hold_note = h
			hold_calc_frac = earliest_hold_note.frac.added(earliest_hold_note.frac_len)
	
	var earliest_tap_note = null
	for t in circle_tap_notes_right.get_children() if is_right else circle_tap_notes_left.get_children():
		if t.frac.less_than(time) and (!earliest_tap_note or earliest_tap_note.frac.less_than(t.frac)):
			earliest_tap_note = t
	
	var ret = null
	if !hold_calc_frac and !earliest_tap_note:
		_log("no previous circle note/hold to attach to.")
		return null
	elif !hold_calc_frac:
		ret = [earliest_tap_note.frac, earliest_tap_note._dir, earliest_tap_note]
	elif !earliest_tap_note:
		ret = [hold_calc_frac, earliest_hold_note.new_dir, earliest_hold_note]
	elif hold_calc_frac.less_than(earliest_tap_note.frac):
		ret = [earliest_tap_note.frac, earliest_tap_note._dir, earliest_tap_note]
	else:
		ret = [hold_calc_frac, earliest_hold_note.new_dir, earliest_hold_note]
	
	# prevent multiple holds from the same note (for now)
	if ret[2].next_hold != null:
		_log("previous circle note/hold already has successor.")
		return null
	#  the first note in the song we check can slip through bc of null calc logic.
	# this will kill it if it's not accurate
	if !ret[0].less_than(time):
		_log("no previous circle note/hold to attach to.")
		return null
	return ret


# send data over what's currently hovered to the ui
func _update_ui_for_current_time():
	var notes_at_this_time = []
	var fracstr = offset_as_frac.as_string()
	if notes_dict.has(fracstr):
		notes_at_this_time = notes_dict[fracstr]
	gui.update_hovered_notes(notes_at_this_time)


##		Saving and Loading		##
#  levels are saved in "usr://lvl/{song name}/{chart_name}.txt".
# multiple charts will share the same audio file, and data they share
# will belong to a shared metadata file at "usr://lvl/{song name}/data.txt"

#  save the file. doing it this way with frac strings as keys breaks the ordering,
# which is annoying but lowk it prob doesnt matter if we call sort on startup
#  `save_internal` puts it in the core game, else it goes to the user folder
func _save_lvl(folder_path: String, chart_name: String):
	ph = get_tree().get_first_node_in_group("palette_holder")
	var cols = []
	if ph:
		cols = ph.get_color_hexes()
	
	var dict = {
		"metadata":
		{
			"bpms": note_holder.bpms,
			"chart_artist": chart_artist,
			"play_offset": note_holder.chart_play_offset,
			"colors": cols
		},
		"linear_notes": {},
		"circular_notes": {false: {}, true: {}},
		"samplers": {
			"scroll_speed": {},
			"glitch": {},
		}
	}
	
	# add linear notes (assumes sorted)
	var all_tap_notes = []
	for n in tap_notes:
		all_tap_notes.append_array(n.get_children())
		all_tap_notes.sort_custom(TapNoteLinear.order)
	var all_hold_notes = []
	for n in hold_notes:
		all_hold_notes.append_array(n.get_children())
		all_hold_notes.sort_custom(TapNoteLinear.order)
	for note in all_tap_notes:
		var fracstring = note.frac.as_string()
		var hold = "0+0/1"
		if note.associated_hold:
			hold = note.associated_hold.len_frac.as_string()
		# add array if not present
		if !dict["linear_notes"].has(fracstring):
			dict["linear_notes"][fracstring] = []
		# append to array
		dict["linear_notes"][fracstring].append({
			"dir": note._dir,
			"doub": note._doubled,
			"abs": note._absolute,
			"also_hold": hold
		})
	
	# add circle notes
	# taps and releases can be mixed
	var all_circle_tap_notes = []
	all_circle_tap_notes.append_array(circle_tap_notes_left.get_children())
	all_circle_tap_notes.append_array(circle_tap_notes_right.get_children())
	all_circle_tap_notes.append_array(circle_release_notes_left.get_children())
	all_circle_tap_notes.append_array(circle_release_notes_right.get_children())
	#all_circle_tap_notes.sort_custom(TapNoteLinear.order)
	var all_circle_hold_notes = []
	all_circle_hold_notes.append_array(circle_hold_notes_left.get_children())
	all_circle_hold_notes.append_array(circle_hold_notes_right.get_children())
	#all_circle_hold_notes.sort_custom(TapNoteLinear.order)
	
	for tap in all_circle_tap_notes:
		# get the basic one in
		var fracstring = tap.frac.as_string()
		# taps and releases can theoretically occur simultaneously
		if !dict["circular_notes"][tap.is_right].has(fracstring):
			dict["circular_notes"][tap.is_right][fracstring] = []
		dict["circular_notes"][tap.is_right][fracstring].append({"dir": tap._dir, "is_release": tap is ReleaseNoteCircular})
		# recursively add holds
		var next_hold = tap.next_hold
		var curr = dict["circular_notes"][tap.is_right][fracstring][-1]
		while next_hold != null:
			curr["next"] = {
				"len": next_hold.frac_len.as_string(),
				"dir": next_hold.new_dir
			}
			next_hold = next_hold.next_hold
			curr = curr["next"]
	
	# samplers
	var scroll_vals = scroll_graph_creator.get_vals()
	for v in scroll_vals:
		dict["samplers"]["scroll_speed"][v.frac.as_string()] = [v.val, v.interpolationMode]
	
	var glitch_vals = glitch_graph_creator.get_vals()
	for v in glitch_vals:
		dict["samplers"]["glitch"][v.frac.as_string()] = [v.val, v.interpolationMode]
	
	
	_ensure_folder_exists(folder_path)
	var save_file = FileAccess.open(folder_path + "/" + chart_name + ".txt", FileAccess.WRITE)
	# indent is unneccessary but nicer to look at
	save_file.store_line(JSON.stringify(dict, "\t"))
	
	_log("Saved to `%s/%s.txt`" % [folder_path, chart_name])


func load_lvl(_folder_path: String, chart_name: String):
	folder_path = _folder_path
	diff = chart_name
	_ensure_folder_exists(folder_path)
	var load_file = FileAccess.open(folder_path + "/" + chart_name + ".txt", FileAccess.READ)
	if load_file:
		# just dump basic values in if not defined
		var dict = JSON.parse_string(load_file.get_as_text())
		if !dict:
			_save_lvl(folder_path, chart_name)
			# this file meta
			dict = JSON.parse_string(load_file.get_as_text())
			load_file = FileAccess.open(folder_path + "/" + chart_name + ".txt", FileAccess.READ)
		
		# kill extant notes
		_clear()
		
		var max_beat = 0
		
		if dict["metadata"].has("bpms"):
			note_holder.bpms = dict["metadata"]["bpms"]
		else: # load in the single bpm if there's only one defined. only needed for deprecated charts
			note_holder.bpms[0][1] = dict["metadata"]["bpm"]
		#note_holder.quarter = 60.0 / note_holder.bpms[0][1]
		if dict["metadata"].has("play_offset"):
			note_holder.chart_play_offset = dict["metadata"]["play_offset"]
		if dict["metadata"].has("colors"):
			ph = get_tree().get_first_node_in_group("palette_holder")
			if ph:
				ph.assign_colors(dict["metadata"]["colors"])
		
		chart_artist = dict["metadata"]["chart_artist"]
		
		#  prime samplers and their editors as appropriate. needs to happen b4 notes
		# fdor the scroll speed sampler
		if dict.has("samplers"):
			if dict["samplers"].has("scroll_speed"):
				for key in dict["samplers"]["scroll_speed"]:
					var frac = Fraction.from_string(key)
					var val = dict["samplers"]["scroll_speed"][key][0]
					var interpolation = dict["samplers"]["scroll_speed"][key][1]
					var realtime_pair = FractionPair.new(frac, val, note_holder.calculate_realtime_at(frac), interpolation)
					var calctime_pair = FractionPair.new(frac, val, note_holder.calculate_offset_at(frac), interpolation)
					# graph creators
					if active:
						scroll_graph_creator.add_val(realtime_pair)
					# samplers
					note_holder.scroll_speeds.append(calctime_pair)
				# this needs additional babying
				note_holder.scroll_speeds.sort_custom(FractionPair.compare)
				note_holder.offsets_dirty = true
			
			if dict["samplers"].has("glitch"):
				for key in dict["samplers"]["glitch"]:
					var frac = Fraction.from_string(key)
					var val = dict["samplers"]["glitch"][key][0]
					var interpolation = dict["samplers"]["glitch"][key][1]
					var realtime_pair = FractionPair.new(frac, val, note_holder.calculate_realtime_at(frac), interpolation)
					var calctime_pair = FractionPair.new(frac, val, note_holder.calculate_offset_at(frac), interpolation)
					# graph creators
					if active:
						glitch_graph_creator.add_val(realtime_pair)
					# samplers
					filterer.glitch_sampler.add_val(calctime_pair)
		
		# lame putting these here but we only want the connection if active
		if active:
			scroll_graph_creator.updated.connect(_on_scroll_graph_creator_updated)
			glitch_graph_creator.updated.connect(_on_glitch_graph_creator_updated)
		
		# circles
		if dict.has("circular_notes"):
			for is_right in dict["circular_notes"]:
				for fracstr in dict["circular_notes"][is_right]:
					for item in dict["circular_notes"][is_right][fracstr]:
						var head = item
						var is_release = head.has("is_release") and head["is_release"]
						
						var a = _add_circle_note(Fraction.from_string(fracstr), is_right == "true", head["dir"], is_release)
						# recursively add holds. frac.fromstr is called real redundantly
						var frac = a.frac
						while head.has("next"):
							a.next_hold = _add_circle_hold(frac, is_right == "true", head["dir"], Fraction.from_string(head["next"]["len"]), head["next"]["dir"])
							a = a.next_hold
							frac = frac.added(a.frac_len)
							head = head["next"]
						
						max_beat = maxi(max_beat, a.frac.base)
		
		# taps
		if dict.has("linear_notes"):
			for fracstr in dict["linear_notes"]:
				var note_array = dict["linear_notes"][fracstr]
				for n in note_array:
					var frac = Fraction.from_string(fracstr)
					max_beat = maxi(max_beat, frac.base)
					_add_note(frac, n["dir"], n["doub"], n["abs"], Fraction.from_string(n["also_hold"]))
		
		# resort nodes. prob really slow but like
		for nh in tap_notes + hold_notes + [circle_hold_notes_left, circle_hold_notes_right, 
		circle_tap_notes_left, circle_tap_notes_right, circle_release_notes_left, circle_release_notes_right]:
			var all_notes = nh.get_children()
			all_notes.sort_custom(TapNoteLinear.order)
			for n in nh.get_children():
				nh.remove_child(n)
			for n in all_notes:
				nh.add_child(n)
		
			#  get audio stream. this load should be ignored if we're loading from the level
		# selector, but is a fallback if fishy stuff goes on
		MusicPlayerShinobu.load_song(folder_path + "/music.ogg")
		# stop a playing sample
		MusicPlayerShinobu.pause()
		
		#  scoring info needs this so we can write scores to a file later.
		# this is obv kinda ugly but refactoring is annoying and not neccesary rn
		scoring_manager.scoring_info.song_name = folder_path.substr("res://lvl/".length())
		scoring_manager.scoring_info.chart_diff = chart_name
		
		# increase the beat marker length to the whole song in editor
		if active:
			while note_holder.calculate_realtime_at(Fraction.new(max_beat)) < MusicPlayerShinobu.get_length():
				max_beat += 1
		
		# add all the beat markers in
		for i in max_beat + 1:
			var bl = BEATLINE.instantiate()
			bl.time = note_holder.calculate_offset_at(Fraction.new(i))
			beatlines.add_child(bl)
		
		if active:
			var beatlinetimes: Array[FractionPair] = []
			for i in max_beat + 1:
				beatlinetimes.append(FractionPair.new(Fraction.new(i), 0, note_holder.calculate_realtime_at(Fraction.new(i))))
			for graph in graphs:
				graph.assign_beatlines(beatlinetimes)
		
		if active:
			_log("Loaded from `%s/%s.txt`" % [folder_path, chart_name])
	
	

#  uses ffmpeg (if present) to create a sample image in the editor so you know broadly
# what the waveform looks like
func load_img():
	var ffmpegpath = "./../ffmpeg/bin/ffmpeg.exe"
	var oggpath = folder_path + "/music.ogg"
	var imgpath = "../img/outputwaveform.png"
	
	# 10 samples a second
	var len = MusicPlayerShinobu.get_length()*64.0
	var arg = "showwavespic=s=%dx150:colors=#ffffff" % len
	
	var output = []
	OS.execute(ffmpegpath, ["-i", oggpath, "-filter_complex", arg, "-update", "1", "-frames:v", "1", "-y", imgpath], output, true)
	#for o in output:
		#print(o)
	
	var file = FileAccess.open("res://../img/outputwaveform.png", FileAccess.READ)
	if file.is_open():
		var bytes = file.get_buffer(file.get_length())
		var img = Image.new()
		var err = img.load_png_from_buffer(bytes)
		if err == Error.OK:
			var imgtex = ImageTexture.create_from_image(img)
			waveform_sprite_2d.texture = imgtex
	file.close()
	
	

#  save and load functions will fail if any part of the folder string is absent from the computer,
# so we manually create them on startup to prevent issues
#  woif update: i forget why i disabled this, investigate mayb. i kno we originally
# wanted to be able to open from both inside the game and externally but we only
# open externally now, so whatever this was trying to do is almost certainly deprecated
func _ensure_folder_exists(folder_path: String):
	return
	## lvl folder
	#var dir = DirAccess.open("user://" if folder_path.begins_with("u") else "res://")
	#if !dir.dir_exists("lvl"):
		#dir.make_dir("lvl")
	## this lvl's folder
	#dir.change_dir("lvl")
	#if !dir.dir_exists(folder_name):
		#dir.make_dir(folder_name)

# its feels insane that this is typeless but it is
func _remove_note(note):
	if note:
		note.queue_free()
		_remove_note_from_dict(note)
		
		if note is TapNoteLinear and note.associated_hold:
			_remove_note(note.associated_hold)

func _clear():
	for nh in tap_notes + hold_notes + [circle_hold_notes_left, circle_hold_notes_right, circle_tap_notes_left, circle_tap_notes_right, beatlines]:
		for n in nh.get_children():
			_remove_note(n)
	for graph in graphs:
		graph.clear_vals()
	scoring_manager.deregister_all()

# regen all the noyes, for when bpm or scroll speed changes at runtime
func _recalc_all_notes():
	for time in notes_dict:
		for note in notes_dict[time]:
			note.calculated_offset = note_holder.calculate_offset_at(note.frac)
			if note is HoldNoteLinear:
				note.set_len(note_holder.calculate_offset_at(note.frac.added(note.len_frac)) - (note_holder.calculate_offset_at(note.frac)), note.len_frac)
			if note is HoldNoteCircular:
				note.calculated_len = note_holder.calculate_offset_at(note.frac.added(note.frac_len)) - (note_holder.calculate_offset_at(note.frac))
	
	for i in beatlines.get_child_count():
		beatlines.get_child(i).time = note_holder.calculate_offset_at(Fraction.new(i))

# interpret signals from the editor ui
func _ui_request_tap_note_addition(index: TapNoteLinear.DIRS):
	#  just one-tap this, you need to use the holds par of the ui to edit holds
	# with the ui (no arrowvortex drag logic)
	_editor_press_note(offset_as_frac, index)
	_editor_release_note(offset_as_frac, index)

func _ui_request_hold_note_addition(index: TapNoteLinear.DIRS, note: TapNoteLinear, len: Fraction):
	_remove_note(note.associated_hold)
	note.associated_hold = _add_hold(note.frac, index, len)
	note_holder.update_notes()

func _ui_request_note_erasure(note):
	_remove_note(note)

func _ui_request_circle_tap_addition(is_right: bool, dir: float):
	_add_circle_note(offset_as_frac, is_right, dir, false)
	note_holder.update_notes()

func _ui_request_circle_release_addition(is_right: bool, dir: float):
	_add_circle_note(offset_as_frac, is_right, dir, true)
	note_holder.update_notes()

func _ui_request_circle_hold_addition(is_right: bool, dir: float):
	_try_add_circle_hold(is_right, dir)
	note_holder.update_notes()


func _log(msg: String):
	logger.new_msg(msg)


#  graph signals. doing all these individually is kinda inelegant but some of them
# want to be slightly different sooo
func _on_scroll_graph_creator_updated(vals: Array[FractionPair]) -> void:
	note_holder.scroll_speeds = vals
	_recalc_all_notes()

func _on_glitch_graph_creator_updated(vals: Array[FractionPair]) -> void:
	filterer.glitch_sampler.set_vals(vals)
