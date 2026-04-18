extends ColorRect

var sampler: SamplerOverTime = SamplerOverTime.new()

func update(timer: float):
	modulate.a = sampler.at(timer)
