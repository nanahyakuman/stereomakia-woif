extends VBoxContainer

const INDIVIDUAL_LEVEL_BUTTON = preload("res://individual_level_button.tscn")
@onready var level_select_root = $"../../../.."
@onready var thumb = %Thumb
@onready var difficulties = %Difficulties
@onready var name_label = %NameLabel
@onready var artist = %Artist
@onready var music_previewer: Node = %MusicPreviewer

var prev_focus = null

var all_infos = []
var which_sort = false

func _ready():
	_regenerate_file_structure()

func _input(event):
	if event.is_action_pressed("lvlr_save"):
		which_sort = !which_sort
		all_infos.sort_custom(LevelInfo.order_name_alph if !which_sort else LevelInfo.order_artist_alph)
		_assign_infos()

func _regenerate_file_structure():
	for c in get_children():
		c.queue_free()
	
	# open scoring info
	var score_file = FileAccess.open("user://scores.txt", FileAccess.READ)
	var scores_dict
	if score_file:
		scores_dict = JSON.parse_string(score_file.get_as_text())
	
	# add externals in future
	for root in ["res://lvl"]:
		var dir = DirAccess.open(root)
		# taken from godot docs
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					var known_scores = {}
					if scores_dict and scores_dict.has(file_name):
						known_scores = scores_dict[file_name]
					_add_info(root + "/" + file_name, known_scores)
				file_name = dir.get_next()
	
	#default to phonetic song-name alphabetical
	all_infos.sort_custom(LevelInfo.order_name_alph)
	# create the selection nodes
	_assign_infos()
	
	# wait a frame so everything can instantiate itself first
	get_child(0).call_deferred("take_focus")

func _add_info(file_path: String, known_scores: Dictionary):
	var file = FileAccess.open(file_path + "/meta.txt", FileAccess.READ)
	if !file:
		print("failed to load file `%s/meta.txt`" % file_path)
		return
	var dict = JSON.parse_string(file.get_as_text())
	if !dict:
		print("failed to parse file `%s/meta.txt`" % file_path)
		return
	
	var info = LevelInfo.new()
	info.folder_path = file_path
	if dict.has("full_name"):
		info.full_name = dict["full_name"]
	if dict.has("artist_name"):
		info.artist_name = dict["artist_name"]
	if dict.has("phonetic_name"):
		info.phonetic_name = dict["phonetic_name"]
	if dict.has("thumb") and dict["thumb"] != "":
		var imgpath = file_path + "/" + dict["thumb"]
		# use the correct importer based on whether we're inside or not
		if file_path.begins_with("u"):
			info.thumbnail = Image.load_from_file(imgpath)
		else:
			info.thumbnail = ResourceLoader.load(imgpath)
	# default thumbnail
	else:
		info.thumbnail = ResourceLoader.load("res://no_thumb.tres")
	if dict.has("difficulties"):
		info.difficulties = dict["difficulties"]
	# preview
	if dict.has("preview"):
		info.preview_offset = dict["preview"]
	# score
	info.highest_scores = known_scores
	
	all_infos.push_back(info)

# generated based on allinfos
func _assign_infos():
	for i in all_infos.size():
		var lvl
		if get_child_count() <= i:
			lvl = INDIVIDUAL_LEVEL_BUTTON.instantiate()
			add_child(lvl)
		else:
			lvl = get_child(i)
		lvl.assign_level(all_infos[i])

# report a button press
func report_press(info: LevelInfo):
	var diff = difficulties.get_selected_diff()
	level_select_root.get_parent().start_level(info.folder_path, diff)
	
	PlayerSettings.save_to_json()

func report_focus(info: LevelInfo):
	if prev_focus == info:
		return
	prev_focus = info
	thumb.texture = info.thumbnail
	difficulties.assign_difficulties(info.difficulties)
	name_label.text = info.full_name
	artist.text = info.artist_name
	# music preview
	MusicPlayerShinobu.load_song(info.folder_path + "/music.ogg")
	music_previewer.start(info.preview_offset)
