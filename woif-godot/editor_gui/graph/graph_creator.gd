extends Control
class_name GraphCreator

const GRAPH_POINT = preload("uid://c3cve1xv7tu75")
const VERTICAL_GRAPH_LINE = preload("uid://5pllk36b8pnc")

@onready var graph_area: ColorRect = $MarginContainer/GraphArea
@onready var vertical_lines: Node2D = %VerticalLines
@onready var line_2d: Line2D = %Line2D
@onready var graph_points: Node2D = %GraphPoints
# used to margin the graph a bit
@onready var graph_margin_area: Control = $MarginContainer/GraphArea/MarginContainer/GraphMarginArea
@onready var mouse_circle: Sprite2D = $MarginContainer/GraphArea/MarginContainer/GraphMarginArea/MouseCircle
@onready var playhead: Line2D = $MarginContainer/GraphArea/MarginContainer/GraphMarginArea/Playhead
@onready var scroll_bar: ColorRect = $MarginContainer/GraphArea/MarginContainer/GraphMarginArea/ScrollBar
@onready var waveform_sprite_2d: Sprite2D = $MarginContainer/GraphArea/MarginContainer/GraphMarginArea/WaveformSprite2D

signal updated

# all the values
var _vals: Array[FractionPair] = []

# beatline real times so we can draw deliniators
var beat_real_times: Array[FractionPair] = []

var playhead_time: float = -2.0

#  data about the last beat_calc_time FracPair that was mouse highlighted.
# this is all overridden constantly, it just needs to be initted
var mouse_pair: FractionPair = FractionPair.new(Fraction.new(1), 0.0, 0.0)

var hovered: bool = false

# for comparison when we signal update
var key: String = ""

# visual horizontal range
var XMIN = 0.0 # this is really only ever 0, leaving some room for optimization, but im using it just in case
var XMAX = 1.0

var xRangeBegin: float = 0.0
var xRangeEnd: float = 25.0

# vertical range. you can't zoom in so it's much simpler
var yRangeBegin = 0.0
var yRangeEnd = 1.0

var _dirty: bool = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if hovered and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_add_or_update_selected_val()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_delete_selected_val()

func _process(delta: float) -> void:
	if _dirty:
		_update_chart()
		emit_signal("updated", key, _vals)
		_dirty = false
	
	# ez zoom
	if Input.is_action_just_released("scroll_u"):
		_adjust_zoom(1.0)
	if Input.is_action_just_released("scroll_d"):
		_adjust_zoom(-1.0)
	
	if beat_real_times.size() <= 0:
		return
	
	var mousePos = get_viewport().get_mouse_position()
	var mouseLocal = _translate_to_percent_coords_from_global(mousePos)
	var mouseCalcTime = lerp(xRangeBegin, xRangeEnd, mouseLocal.x)
	var mouseCalcVal = lerp(yRangeEnd, yRangeBegin, mouseLocal.y)
	var firstBeatAfterIndex = 0
	while firstBeatAfterIndex < beat_real_times.size() - 1 and beat_real_times[firstBeatAfterIndex].calc_time < mouseCalcTime:
		firstBeatAfterIndex += 1
	
	var firstBeatAfter := beat_real_times[firstBeatAfterIndex]
	var firstBeatBefore := beat_real_times[firstBeatAfterIndex-1]
	
	var xa = (firstBeatBefore.calc_time - xRangeBegin) / (xRangeEnd-xRangeBegin)
	var xb = (firstBeatAfter.calc_time - xRangeBegin) / (xRangeEnd-xRangeBegin)
	
	var aDist = abs(mouseLocal.x - xa)
	var bDist = abs(mouseLocal.x - xb)
	var beforeSelected = aDist < bDist
	var selectedX = _translate_to_graphical_coords(Vector2(firstBeatBefore.calc_time,0)).x if beforeSelected else _translate_to_graphical_coords(Vector2(firstBeatAfter.calc_time,0)).x
	
	mouse_circle.position.x = selectedX
	mouse_circle.global_position.y = mousePos.y
	
	if beforeSelected:
		mouse_pair.frac = firstBeatBefore.frac
		mouse_pair.calc_time = firstBeatBefore.calc_time
	else:
		mouse_pair.frac = firstBeatAfter.frac
		mouse_pair.calc_time = firstBeatAfter.calc_time
	mouse_pair.val = mouseCalcVal


func _update_chart():
	# points
	line_2d.clear_points()
	for g in graph_points.get_children():
		g.queue_free()
	
	var has_underdrawn: bool = false
	var has_overdrawn: bool = false
	
	
	#  doing evil iterator manip to overdraw by 1 in both
	# dierctions
	var i: int = -1
	while i < _vals.size()-1:
		i += 1
		var p = _vals[i]
		
		# ez boundsing
		if p.calc_time < xRangeBegin:
			continue
		if p.calc_time > xRangeEnd:
			if !has_overdrawn:
				has_overdrawn = true
			else:
				break
		
		if !has_underdrawn:
			has_underdrawn = true
			# escape case for zeroth point being visible
			if i == 0:
				pass
			else:
				p = _vals[i-1]
				i -= 1
		
		var coords = _translate_to_graphical_coords(Vector2(p.calc_time, p.val))
		
		# line
		line_2d.add_point(coords)
		# sample and hold
		if i < _vals.size()-1:
			if _vals[i+1].interpolationMode == FractionPair.InterpolationMode.HOLD:
				line_2d.add_point(_translate_to_graphical_coords(Vector2(_vals[i+1].calc_time, p.val)))
		
		# point
		var point: GraphPoint = GRAPH_POINT.instantiate()
		graph_points.add_child(point)
		point.position = coords
		point.pair = p
		point.dirtied.connect(_point_request_update)
	
	
	for vl in vertical_lines.get_children():
		vl.queue_free()
	
	var beat_i = 0
	while beat_i < beat_real_times.size()-1 and xRangeBegin < beat_real_times[beat_i].calc_time:
		beat_i += 1
	while beat_i < beat_real_times.size() and beat_real_times[beat_i].calc_time < xRangeEnd:
		var vl: Line2D = VERTICAL_GRAPH_LINE.instantiate()
		var time = beat_real_times[beat_i].calc_time
		# 5 is the size of the margin area. not programmatic bc w/e man
		vl.add_point(_translate_to_graphical_coords(Vector2(time,yRangeBegin)))
		vl.add_point(_translate_to_graphical_coords(Vector2(time,yRangeEnd)))
		vertical_lines.add_child(vl)
		
		beat_i += 1
	
	# these lerps are %>graphical
	var left_pos = xRangeBegin/XMAX
	var right_pos = xRangeEnd/XMAX
	scroll_bar.position.x = lerp(0.0, graph_margin_area.size.x, left_pos)
	scroll_bar.size.x = lerp(0.0, graph_margin_area.size.x, right_pos - left_pos)
	
	_update_playhead()
	
	# waveform
	# put the whole thing in
	var tex_size = waveform_sprite_2d.texture.get_size()
	waveform_sprite_2d.region_rect.position.x = lerp(0.0, tex_size.x, left_pos)
	waveform_sprite_2d.region_rect.size.x = lerp(0.0, tex_size.x, right_pos - left_pos)
	
	waveform_sprite_2d.region_rect.size.y = tex_size.y
	
	# blow it up
	waveform_sprite_2d.scale = graph_margin_area.size / waveform_sprite_2d.region_rect.size
	

func _update_playhead():
	playhead.set_point_position(0, _translate_to_graphical_coords(Vector2(playhead_time,yRangeBegin)))
	playhead.set_point_position(1, _translate_to_graphical_coords(Vector2(playhead_time,yRangeEnd)))

#  shoutout https://www.gksander.com/posts/math-of-zooming-in ,
# i am not this smart on my own
func _adjust_zoom(amount: float):
	#  this is technically a pump, like [+1 -1] x 10 zooms in slowly.
	# i'm pretty sure you'd have to keep a seperate scale value or
	# do some predictive solving for that not to be the case, but both
	# are annoying and it doesn't *really* matter
	var dW = (xRangeEnd - xRangeBegin) * .2 * -amount
	
	var mousePos = get_viewport().get_mouse_position()
	mousePos -= graph_margin_area.global_position
	var hitPercent = _translate_to_percent_coords(mousePos).x
	hitPercent = clamp(hitPercent, 0.0, 1.0)
	
	xRangeBegin = max(XMIN, xRangeBegin - hitPercent * dW)
	xRangeEnd = min(XMAX, xRangeEnd + (1.0-hitPercent) * dW)
	
	_dirty = true


func _add_or_update_selected_val():
	var val = _find_mouse_val()
	
	if val:
		remove_val(val)
	
	add_val(FractionPair.new(mouse_pair.frac, clamp(mouse_pair.val, 0.0, 1.0), mouse_pair.calc_time))

func _delete_selected_val():
	var val = _find_mouse_val()
	if val:
		remove_val(val)


func _find_mouse_val():
	for val in _vals:
		if val.frac.equals(mouse_pair.frac):
			return val
	return null

#  note that the translation functions are local to `graph_margin_area`,
# NOT ourself.
#  translate a variable in xyrange space to visual space. 
func _translate_to_graphical_coords(coords: Vector2) -> Vector2:
	return Vector2(
		remap(coords.x, xRangeBegin, xRangeEnd, 0.0, graph_margin_area.size.x),
		remap(coords.y, yRangeBegin, yRangeEnd, graph_margin_area.size.y, 0.0)
	)
# translate a variable from visual space to ranged coords
func _translate_to_percent_coords(coords: Vector2) -> Vector2:
	return Vector2(
		remap(coords.x, 0.0, graph_margin_area.size.x, 0.0, 1.0),
		remap(coords.y, graph_margin_area.size.y, 0.0, 1.0, 0.0)
	)
func _translate_to_percent_coords_from_global(coords: Vector2) -> Vector2:
	return Vector2(
		remap(coords.x, graph_margin_area.global_position.x, graph_margin_area.global_position.x + graph_margin_area.size.x, 0.0, 1.0),
		remap(coords.y, graph_margin_area.global_position.y + graph_margin_area.size.y, graph_margin_area.global_position.y, 1.0, 0.0)
	)


## signals
# rebuild when moved
func _on_visibility_changed() -> void:
	_dirty = true
func _on_resized() -> void:
	_dirty = true
func _on_item_rect_changed() -> void:
	_dirty = true


# so that points can request rebuils
func _point_request_update() -> void:
	_dirty = true


## externals
#  add a val to the chart. it's not enforced rn but there can only
# be one val per timestamp.
func add_val(val: FractionPair):
	_vals.append(val)
	_vals.sort_custom(FractionPair.compare)
	
	XMIN = min(XMIN, val.calc_time)
	XMAX = max(XMAX, val.calc_time)
	
	_dirty = true

func remove_val(val: FractionPair):
	_vals.erase(val)
	
	_dirty = true

func clear_vals():
	_vals.clear()
	_dirty = true

# return all the changes as an Array of FractionPairs
func get_vals() -> Array[FractionPair]:
	return _vals


#  give us an array of when beatlines occur in real seconds, so
# we can draw the guidelines
func assign_beatlines(arr: Array[FractionPair]):
	beat_real_times = arr
	XMAX = max(XMAX, arr.back().calc_time)

func assign_time(time: float):
	playhead_time = time
	_update_playhead()

func assign_waveform(waveform: Texture2D):
	waveform_sprite_2d.texture = waveform

# unhandled input is giving me a migraine
func _on_mouse_entered() -> void:
	hovered = true

func _on_mouse_exited() -> void:
	hovered = false
