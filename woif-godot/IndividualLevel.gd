extends Control

@onready var button = $IndividualLevel/Button
@onready var artist_label = $IndividualLevel/ArtistLabel
@onready var high_score_labels = $IndividualLevel/HBoxContainer

var lvl_info: LevelInfo

func _ready():
	button.connect("pressed", _on_press)
	button.connect("focus_entered", _on_focus)

func assign_level(_lvl_info: LevelInfo):
	lvl_info = _lvl_info
	button.text = lvl_info.full_name
	artist_label.text = lvl_info.artist_name
	# copy in known clears
	while high_score_labels.get_child_count() < lvl_info.difficulties.size():
		high_score_labels.add_child(high_score_labels.get_child(0).duplicate())
	var index = 0
	for d in lvl_info.difficulties:
		if lvl_info.highest_scores.has(d):
			high_score_labels.get_child(index).text = lvl_info.highest_scores[d]
		else:
			high_score_labels.get_child(index).text = "-"
		index += 1
	for i in range(lvl_info.difficulties.size(), high_score_labels.get_child_count()):
		high_score_labels.get_child(-1).queue_free()

func take_focus():
	button.grab_focus()

func _on_press():
	get_parent().report_press(lvl_info)

func _on_focus():
	get_parent().report_focus(lvl_info)
