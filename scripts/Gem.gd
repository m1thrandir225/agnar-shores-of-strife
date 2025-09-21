extends Area2D

class_name Gem

@export var gem_number: int = 1
@export var gem_type: String = "Ruby"
@export var pickup_sound: AudioStream
@export var float_height: float = 10.0
@export var float_speed: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_collected: bool = false
var original_position: Vector2
var float_timer: float = 0.0

# Signals
signal gem_collected(gem_number: int)

func _ready() -> void:
	original_position = position
	
	
	body_entered.connect(_on_body_entered)
	
	
	collision_layer = 8 # Gem layer
	collision_mask = 1 # Detect player only
	
	
	if animated_sprite:
		animated_sprite.play("idle")
	

func _process(delta: float) -> void:
	if is_collected:
		return
	
	
	float_timer += delta * float_speed
	var float_offset = sin(float_timer) * float_height
	position = original_position + Vector2(0, float_offset)
	
	
	rotation += delta * 0.8

func _on_body_entered(body) -> void:
	if body is Player and not is_collected:
		collect_gem(body)

func collect_gem(player: Player) -> void:
	if is_collected:
		return
	
	is_collected = true
	
	
	if pickup_sound and audio_player:
		audio_player.stream = pickup_sound
		audio_player.play()
	
	
	play_collection_effect()
	
	
	gem_collected.emit(gem_number)
	
	
	collision_shape.disabled = true
	
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func play_collection_effect() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.6)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	
	tween.tween_property(self, "rotation", rotation + PI * 4, 0.6)
	

func set_gem_type_by_level(level: int) -> void:
	match level:
		1:
			gem_type = "Ruby"
			modulate = Color(1.0, 0.3, 0.3)
		2:
			gem_type = "Sapphire"
			modulate = Color(0.3, 0.3, 1.0)
		3:
			gem_type = "Emerald"
			modulate = Color(0.3, 1.0, 0.3)
		4:
			gem_type = "Diamond"
			modulate = Color(1.0, 1.0, 1.0)