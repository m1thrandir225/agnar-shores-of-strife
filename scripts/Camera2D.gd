extends Camera2D

var shake_strength: float = 0.0
var shake_duration: float = 0.0

func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		shake_strength = lerp(shake_strength, 0.0, 5.0 * delta)
		
		if shake_duration <= 0:
			offset = Vector2.ZERO
			shake_strength = 0.0

func shake(duration: float, strength: float) -> void:
	shake_duration = duration
	shake_strength = strength
