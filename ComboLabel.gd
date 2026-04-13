extends Control

@onready var base = $Base
@onready var fraction = $Fraction


var ph: PaletteHolder

func _ready():
	ph = get_tree().get_first_node_in_group("palette_holder")
	if ph:
		ph.colorsChanged.connect(_get_color)
		_get_color()

func assign(frac: Fraction):
	base.text = str(frac.base)
	fraction.text = ("%0.1f" % (float(frac.numerator) / float(frac.denominator))).substr(1)

func _get_color():
	for l: Label in [base, fraction]:
		l.label_settings.font_color = ph.colors[PaletteHolder.WHICH_COLOR.NOTE_OUTLINE]
		l.label_settings.outline_color = ph.colors[PaletteHolder.WHICH_COLOR.NOTE_BASE]
