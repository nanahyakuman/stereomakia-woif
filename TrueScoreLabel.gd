extends Label

var kansuu = [
	"〇",
	"一",
	"二",
	"三",
	"四",
	"五",
	"六",
	"七",
	"八",
	"九",
]
var pretentious_kansuu = [
	"零",
	"壹",
	"貮",
	"參",
	"肆",
	"伍",
	"陸",
	"漆",
	"捌",
	"玖",
]

var ph: PaletteHolder

func _ready() -> void:
	ph = get_tree().get_first_node_in_group("palette_holder")
	if ph:
		ph.colorsChanged.connect(_get_color)
		_get_color()
	
	set_score(0)

func set_score(score: int):
	var str = ""
	while score != 0 or str.length() < 14:
		str = str(score % 10) + "\n" + str
		score /= 10
	text = str


func _get_color():
	label_settings.font_color = ph.colors[PaletteHolder.WHICH_COLOR.NOTE_BASE]
	label_settings.outline_color = ph.colors[PaletteHolder.WHICH_COLOR.NOTE_BASE].lerp(ph.colors[PaletteHolder.WHICH_COLOR.NOTE_OUTLINE], .25)
