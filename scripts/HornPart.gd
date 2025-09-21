extends Area2D
class_name HornPart

@export var part_number: int = 1 # Which part of the horn this is (1-4)
@export var pickup_sound: AudioStream
@export var float_height: float = 10.0
@export var float_speed: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var particles: GPUParticles2D = $GPUParticles2D

var is_collected: bool = false
var original_position: Vector2
var float_timer: float = 0.0

# Signals
signal horn_part_collected(part_number: int)

func _ready() -> void:
	original_position = position
	
	body_entered.connect(_on_body_entered)
	
	collision_layer = 8 # Horn layer
	collision_mask = 1 # Detect player only
	
	# Start floating animation
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Start particle effect if available
	if particles:
		particles.emitting = true
	
	print("Horn Part ", part_number, " spawned at: ", global_position)

func _process(delta: float) -> void:
	if is_collected:
		return
	
	# Floating animation
	float_timer += delta * float_speed
	var float_offset = sin(float_timer) * float_height
	position = original_position + Vector2(0, float_offset)
	
	# Gentle rotation
	rotation += delta * 0.5

func _on_body_entered(body) -> void:
	if body is Player and not is_collected:
		collect_horn_part(body)

func collect_horn_part(player: Player) -> void:
	if is_collected:
		return
	
	is_collected = true
	print("Horn Part ", part_number, " collected by Agnar!")
	
	# Play pickup sound
	if pickup_sound and audio_player:
		audio_player.stream = pickup_sound
		audio_player.play()
	
	# Play collection animation/effect
	play_collection_effect()
	
	# Emit signal with part number
	horn_part_collected.emit(part_number)
	
	# Disable collision
	collision_shape.disabled = true
	
	# Wait for sound/animation then remove
	await get_tree().create_timer(1.0).timeout
	queue_free()

func play_collection_effect() -> void:
	# Scale up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale animation
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.5)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Spin faster
	tween.tween_property(self, "rotation", rotation + PI * 2, 0.5)
	
	# Particle burst
	if particles:
		particles.amount = particles.amount * 3
		particles.emitting = true