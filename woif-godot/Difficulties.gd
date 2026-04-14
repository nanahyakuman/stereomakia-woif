extends VBoxContainer

const DIFFICULTY_INDICATOR = preload("res://difficulty_indicator.tscn")

var current_diff_offs = 0

func assign_difficulties(arr):
	for c in get_children():
		c.queue_free()
		remove_child(c)
	
	for d in arr:
		var ind = DIFFICULTY_INDICATOR.instantiate()
		add_child(ind)
		ind.set_difficulty(d)
	 
	# just select the first defined one
	change_diff(-99)

func _input(event):
	if event.is_action_pressed("ui_left"):
		change_diff(-1)
	if event.is_action_pressed("ui_right"):
		change_diff(1)

func change_diff(dir: int):
	current_diff_offs += dir
	current_diff_offs = clampi(current_diff_offs, 0, get_child_count()-1)
	
	for i in get_child_count():
		get_child(i).set_selected(i == current_diff_offs)

func get_selected_diff():
	return get_child(current_diff_offs).get_difficulty()
