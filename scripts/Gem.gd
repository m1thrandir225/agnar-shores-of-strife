extends Area2D

class_name Gem

@export var gem_number: int = 1 # Which gem this is (1-4)
@export var gem_type: String = "Ruby" # Ruby, Sapphire, Emerald, Diamond
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
	
	# Set up area detection
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 8 # Gem layer
	collision_mask = 1 # Detect player only
	
	# Start floating animation
	if animated_sprite:
		animated_sprite.play("idle")
	

	print("Gem ", gem_number, " (", gem_type, ") spawned at: ", global_position)

func _process(delta: float) -> void:
	if is_collected:
		return
	
	# Floating animation
	float_timer += delta * float_speed
	var float_offset = sin(float_timer) * float_height
	position = original_position + Vector2(0, float_offset)
	
	# Gentle rotation
	rotation += delta * 0.8

func _on_body_entered(body) -> void:
	if body is Player and not is_collected:
		collect_gem(body)

func collect_gem(player: Player) -> void:
	if is_collected:
		return
	
	is_collected = true
	print("Gem ", gem_number, " (", gem_type, ") collected by Agnar!")
	
	# Play pickup sound
	if pickup_sound and audio_player:
		audio_player.stream = pickup_sound
		audio_player.play()
	
	# Play collection animation/effect
	play_collection_effect()
	
	# Emit signal with gem number
	gem_collected.emit(gem_number)
	
	# Disable collision
	collision_shape.disabled = true
	
	# Wait for sound/animation then remove
	await get_tree().create_timer(1.0).timeout
	queue_free()

func play_collection_effect() -> void:
	# Scale up and fade out with sparkle effect
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale animation
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.6)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	
	# Spin faster
	tween.tween_property(self, "rotation", rotation + PI * 4, 0.6)
	

func set_gem_type_by_level(level: int) -> void:
	match level:
		1:
			gem_type = "Ruby"
			modulate = Color(1.0, 0.3, 0.3) # Red tint
		2:
			gem_type = "Sapphire"
			modulate = Color(0.3, 0.3, 1.0) # Blue tint
		3:
			gem_type = "Emerald"
			modulate = Color(0.3, 1.0, 0.3) # Green tint
		4:
			gem_type = "Diamond"
			modulate = Color(1.0, 1.0, 1.0) # White/clear