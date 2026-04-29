extends Node2D
class_name HoldNoteCircular

var is_right = false
# these are where the note starts
var frac = Fraction.new(0)
var calculated_offset = 3.0
var realtime_offset: float = 3.0
var start_dir = 0.0
# these are where the note holds to
var frac_len = Fraction.new(1)
var calculated_len = 1.0
var realtime_len: float = 3.0
var new_dir = 0.0

var next_hold: HoldNoteCircular = null

#  whether this note is attached to a tap before it. if so, we mute
# the hold scoring on this hold for the length of the tap window so that
# aceeptably late taps aren't combo broken by holds 
var is_onset: bool = false

const def_width = 90
const def_width_2 = 110
const subdiv_mod = .05

@onready var mesh_instance_2d = $MeshInstance2D
@onready var mesh_instance_2d_2 = $MeshInstance2D2

#  it can be really annoying to chart notes that autohide themselves,
# this alleviates that
var is_editor: bool = false

func update(calculated_timer):
	# dont regen mesh if invisible
	if calculated_offset + calculated_len < calculated_timer:
		visible = false
		return
	if calculated_offset > calculated_timer + PlayerSettings.get_circ_time():
		visible = false
		return
	visible = true
	
	# regen mesh
	#  dynamically decide how much to subdivide based on length.
	# this should scale by speed in future
	var calc_subdiv = calculated_len / max(.01, abs(start_dir - new_dir)) * subdiv_mod * PlayerSettings.get_circ_time()
	calc_subdiv *= PlayerSettings.mesh_detail_inv # player set accuracy mod goes here
	var width = def_width
	for which in [mesh_instance_2d, mesh_instance_2d_2]:
		which.mesh.clear_surfaces()
		which.mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		# max to force at least 4 verts
		for i in maxi(1, calculated_len / calc_subdiv):
			var offs = calculated_offset + i * calc_subdiv
			var calc_dir = lerp_angle(start_dir, new_dir, -(calculated_offset - offs) / calculated_len)
			var coords = _dir_and_time_to_coords(calc_dir, offs, calculated_timer, width)
			var uvside = 0
			which.mesh.surface_set_uv(Vector2(uvside, 0))
			which.mesh.surface_add_vertex_2d(coords[0])
			which.mesh.surface_set_uv(Vector2(1-uvside, 0))
			which.mesh.surface_add_vertex_2d(coords[1])
		# add last point
		var coords = _dir_and_time_to_coords(new_dir, calculated_offset+calculated_len, calculated_timer, width)
		which.mesh.surface_set_uv(Vector2(0, 0))
		which.mesh.surface_add_vertex_2d(coords[0])
		which.mesh.surface_set_uv(Vector2(1, 0))
		which.mesh.surface_add_vertex_2d(coords[1])
		which.mesh.surface_end()
		width = def_width_2

func _dir_and_time_to_coords(in_dir, _tim, timer, width):
	var pos_ratio = ((timer - _tim) / PlayerSettings.get_circ_time() + 1.0)
	#pos_ratio = clamp(pos_ratio, 0.0, 1.0)
	var pos_coords = Vector2(200 * (1.0 if is_right else -1.0), -200)
	# hide the completed part of the note
	if !is_editor and pos_ratio > 1.0:
		in_dir = lerp_angle(start_dir, new_dir, -(calculated_offset - timer) / calculated_len)
		pos_ratio = 1.0
	if pos_ratio < 0.0:
		pos_ratio = 0.0
	pos_ratio = TapNoteCircular.distance_curve(pos_ratio)
	pos_coords += Vector2(200,0).rotated(in_dir) * pos_ratio
	# return both as an array
	var ret = [pos_coords, pos_coords]
	ret[0] += Vector2(width * .5, 0).rotated(in_dir + PI * .5) * pos_ratio
	ret[1] += Vector2(width * .5, 0).rotated(in_dir - PI * .5) * pos_ratio
	return ret


# get the direction at the given time
func calc_dir(timer):
	return lerp_angle(start_dir, new_dir, (timer - realtime_offset) / realtime_len)
