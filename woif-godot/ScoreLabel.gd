extends Node2D

@onready var score_label = $ScoreLabel
@onready var sub_label = $ScoreLabel/SubLabel

# 0 as perfect, then +1 per
var ratings = [
	"清", #chinitsu
	"純", #junchan
	"混", #honitsu
	"無" #muyaku
]
var ratings_en = [
	"ABSOLUTE", #chinitsu
	"PURE", #junchan
	"IMPURE", #honitsu
	"ABSENT" #muyaku
]

var colors = [
	Color.WHITE,
	Color("ffd66f"),
	Color("b37e4b"),
	Color("71052b"),
	#Color.WHITE,
	#Color.WHITE.darkened(.06),
	#Color.WHITE.darkened(.4),
	#Color.WHITE.darkened(.95),
]

@onready var target_pos = position

func _ready():
	visible = false

func change_rating(rating: int, offset: float):
	rating = min(rating, ratings.size() - 1)
	score_label.text = ratings[rating]
	sub_label.text = ratings_en[rating]
	modulate = colors[rating]
	position.y = target_pos.y + 10
	rotation = rating * .1 * sign(offset)
	visible = true
	return rating

func _process(delta):
	position = hlp.exdc(position, target_pos, 3, delta)
	rotation = hlp.exdc(rotation, 0, 3, delta)
