extends Palettizer

func update(timer):
	for c in get_children():
		c.update(timer)
