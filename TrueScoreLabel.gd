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

func _ready():
	set_score(0)

func set_score(score: int):
	var str = ""
	while score != 0 or str.length() < 14:
		str = str(score % 10) + "\n" + str
		score /= 10
	text = str
