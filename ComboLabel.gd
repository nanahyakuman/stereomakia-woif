extends Control

@onready var base = $Base
@onready var fraction = $Fraction

func assign(frac: Fraction):
	base.text = str(frac.base)
	fraction.text = ("%0.1f" % (float(frac.numerator) / float(frac.denominator))).substr(1)
