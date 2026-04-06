extends Node

@onready var score_label = $Control/VBoxContainer/ScoreLabel
@onready var count_labels = $Control/VBoxContainer/CountLabels
@onready var grade_label = $Control/GradeLabel

func assign_scoring_info(info: ScoringInfo):
	score_label.text = "%07d" % info.get_displayed_score()
	for i in 6:
		count_labels.get_child(i*2+1).text = str(info.eval_counts[i])
	for i in 2:
		count_labels.get_child((i+1)*2+1).text += " (%d/%d)" % [info.early_eval_count[i], info.late_eval_count[i]]
	
	grade_label.text = info.calculate_grade()
	
	# write score to file
	if is_zero_approx(PlayerSettings.player_set_repitch_semitones):
		var score_file = FileAccess.open("user://scores.txt", FileAccess.READ_WRITE)
		var scores_dict = {}
		if score_file:
			scores_dict = JSON.parse_string(score_file.get_as_text())
		if !scores_dict.has(info.song_name):
			scores_dict[info.song_name] = {}
		# no previous score means justr pipe this one in
		if !scores_dict[info.song_name].has(info.chart_diff):
			scores_dict[info.song_name][info.chart_diff] = grade_label.text
		# else we compare previous scores
		else:
			#  this is a little crusty ig but its the easiest way to find
			# out an order thats not quite alphabetic
			var prev_score = scores_dict[info.song_name][info.chart_diff]
			var ratings = "SABCDEFGHIJKLMNO"
			var prevfind = ratings.find(prev_score.substr(0,1))
			var thisfind = ratings.find(grade_label.text.substr(0,1))
			# higher precendance scores
			if thisfind < prevfind:
				scores_dict[info.song_name][info.chart_diff] = grade_label.text
			# s tie breakers
			elif thisfind == prevfind and thisfind == 0:
				if prev_score == "S*" or grade_label.text == "S*":
					scores_dict[info.song_name][info.chart_diff] = "S*"
				elif prev_score == "S+" or grade_label.text == "S+":
					scores_dict[info.song_name][info.chart_diff] = "S+"
				else:
					scores_dict[info.song_name][info.chart_diff] = "S"
		
		if !score_file:
			score_file = FileAccess.open("user://scores.txt", FileAccess.WRITE)
		score_file.store_line(JSON.stringify(scores_dict, "\t"))

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_parent().start_level_select()
