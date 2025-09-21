extends CharacterBody2D

class_name Enemy

@export var max_health: int = 50
@export var move_speed: float = 100.0
@export var attack_damage: int = 5
@export var attack_range: float = 60.0
@export var detection_range: float = 200.0
@export var attack_cooldown: float = 1.5
@export var attack_duration: float = 0.8

var current_health: int
var is_dead: bool = false
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_duration_timer: float = 0.0
var target_player: Player = null

var lose_target_timer: float = 0.0
var lose_target_time: float = 4.0
var last_known_player_position: Vector2

var patrol_timer: float = 0.0
var patrol_wait_time: float = 0.0
var patrol_direction: Vector2 = Vector2.ZERO
var patrol_speed: float = 30.0
var original_position: Vector2
var max_patrol_distance: float = 150.0

enum EnemyState {IDLE, PATROLLING, CHASING, ATTACKING, STUNNED, DEAD}
var current_state: EnemyState = EnemyState.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea

signal enemy_died
signal enemy_attacked
signal player_detected

func _ready() -> void:
	current_health = max_health
	original_position = global_position
	setup_areas()
	
	set_new_patrol_direction()
	
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_entered)
	
	collision_layer = 4
	collision_mask = 3
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func update_state_based_on_player_distance() -> void:
	"""Update enemy state based on distance to player"""
	if not target_player or target_player.is_dead:
		if current_state != EnemyState.IDLE and current_state != EnemyState.PATROLLING:
			current_state = EnemyState.IDLE
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	
	if distance > detection_range * 1.3:
		lose_target()
		return
	
	if distance <= attack_range and attack_timer <= 0 and current_state != EnemyState.ATTACKING:
		current_state = EnemyState.ATTACKING
		perform_attack()
		return
	
	if distance > attack_range * 1.2 and current_state == EnemyState.ATTACKING and is_attacking:
		end_attack()
		current_state = EnemyState.CHASING
		return
	
	if distance > attack_range and distance <= detection_range and current_state != EnemyState.CHASING:
		current_state = EnemyState.CHASING
		return

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	
	update_timers(delta)
	
	
	update_state_based_on_player_distance()
	
	
	match current_state:
		EnemyState.IDLE:
			handle_idle(delta)
		EnemyState.PATROLLING:
			handle_patrolling(delta)
		EnemyState.CHASING:
			handle_chasing(delta)
		EnemyState.ATTACKING:
			handle_attacking(delta)
		EnemyState.STUNNED:
			handle_stunned(delta)
	
	
	handle_animation()
	
	
	move_and_slide()

func update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
	
	
	if attack_duration_timer > 0:
		attack_duration_timer -= delta
		if attack_duration_timer <= 0:
			end_attack()
	
	
	if lose_target_timer > 0:
		lose_target_timer -= delta
		if lose_target_timer <= 0:
			lose_target()
	
	
	if patrol_timer > 0:
		patrol_timer -= delta
	
	if patrol_wait_time > 0:
		patrol_wait_time -= delta

func setup_areas() -> void:
	if detection_area:
		var detection_shape = CircleShape2D.new()
		detection_shape.radius = detection_range
		var detection_collision = CollisionShape2D.new()
		detection_collision.shape = detection_shape
		detection_area.add_child(detection_collision)
		detection_area.monitoring = true
		detection_area.collision_layer = 0
		detection_area.collision_mask = 1
	
	
	if attack_area:
		var attack_shape = CircleShape2D.new()
		attack_shape.radius = attack_range
		var attack_collision = CollisionShape2D.new()
		attack_collision.shape = attack_shape
		attack_area.add_child(attack_collision)
		attack_area.monitoring = false
		attack_area.collision_layer = 0
		attack_area.collision_mask = 1

func handle_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	
	
	if patrol_wait_time <= 0:
		current_state = EnemyState.PATROLLING
		set_new_patrol_direction()
		patrol_timer = randf_range(2.0, 4.0) # Patrol for 2-4 seconds

func handle_patrolling(delta: float) -> void:
	velocity = patrol_direction * patrol_speed
	
	
	if patrol_direction.x < 0:
		animated_sprite.flip_h = true
	elif patrol_direction.x > 0:
		animated_sprite.flip_h = false
	
	
	var distance_from_start = global_position.distance_to(original_position)
	if distance_from_start > max_patrol_distance:
		patrol_direction = (original_position - global_position).normalized()
	
	
	if patrol_timer <= 0:
		current_state = EnemyState.IDLE
		patrol_wait_time = randf_range(1.0, 3.0)

func handle_chasing(delta: float) -> void:
	if not target_player or target_player.is_dead:
		current_state = EnemyState.IDLE
		target_player = null
		return
	
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	if distance_to_player > detection_range * 1.3: # 30% buffer
		lose_target()
		return
	
	# Update last known position
	last_known_player_position = target_player.global_position
	
	# Calculate direction
	var direction = (target_player.global_position - global_position).normalized()
	
	# Slow down when close to avoid pushing through player
	var speed_multiplier = 1.0
	if distance_to_player < attack_range * 1.5:
		speed_multiplier = 0.6
	
	velocity = direction * move_speed * speed_multiplier
	
	# Face the target
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false
	
	# Attack if in range and not on cooldown
	if distance_to_player <= attack_range and attack_timer <= 0 and not is_attacking:
		current_state = EnemyState.ATTACKING
		perform_attack()
	
	# Reset lose target timer while actively chasing
	lose_target_timer = lose_target_time

func handle_attacking(delta: float) -> void:
	# Check if we still have a valid target
	if not target_player or target_player.is_dead:
		current_state = EnemyState.IDLE
		is_attacking = false
		if attack_area:
			attack_area.monitoring = false
		return
	
	# Check distance to player
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# If player moved too far away, stop attacking and start chasing
	if distance_to_player > attack_range * 1.2: # Small buffer to prevent flickering
		end_attack()
		current_state = EnemyState.CHASING
		return
	
	# Stop moving during attack
	velocity = velocity * 0.1
	
	# Face the player during attack
	var direction = (target_player.global_position - global_position).normalized()
	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false
	
	if not is_attacking:
		current_state = EnemyState.CHASING

func handle_stunned(delta: float) -> void:
	# Reduce velocity when stunned
	velocity = velocity * 0.3

func set_new_patrol_direction() -> void:
	# Choose a random direction
	var angle = randf() * 2 * PI
	patrol_direction = Vector2(cos(angle), sin(angle))

func handle_animation() -> void:
	if not animated_sprite:
		return
	
	if is_dead:
		play_animation("die")
	elif is_attacking:
		play_animation("attack")
	elif velocity.length() > 10:
		play_animation("walk")
	else:
		play_animation("idle")

func play_animation(animation_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			if animated_sprite.animation != animation_name:
				animated_sprite.play(animation_name)

func perform_attack() -> void:
	if is_attacking or is_dead:
		return
	
	
	is_attacking = true
	attack_timer = attack_cooldown
	attack_duration_timer = attack_duration
	
	# Enable attack detection
	if attack_area:
		attack_area.monitoring = true
	
	enemy_attacked.emit()

func end_attack() -> void:
	"""Properly end the attack state"""
	if not is_attacking:
		return
	
	is_attacking = false
	attack_duration_timer = 0.0
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false
	

func _on_animation_finished() -> void:
	# End attack when attack animation finishes
	if is_attacking and animated_sprite.animation == "attack":
		end_attack()

func lose_target() -> void:
	target_player = null
	lose_target_timer = 0.0
	
	# Return to patrolling instead of idle
	current_state = EnemyState.PATROLLING
	set_new_patrol_direction()
	patrol_timer = randf_range(2.0, 4.0)

func perform_special_attack() -> void:
	# Override in child classes
	pass

func take_damage(damage: int) -> void:
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	
	# Flash red when hit
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE
	
	
	if current_health <= 0:
		die()
	else:
		# Brief stun when hit
		current_state = EnemyState.STUNNED
		await get_tree().create_timer(0.3).timeout
		if not is_dead:
			if target_player:
				current_state = EnemyState.CHASING
			else:
				current_state = EnemyState.PATROLLING
				set_new_patrol_direction()

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	current_state = EnemyState.DEAD
	velocity = Vector2.ZERO
	
	# Disable all areas
	if attack_area:
		attack_area.monitoring = false
	if detection_area:
		detection_area.monitoring = false
	
	enemy_died.emit()
	
	# Wait for death animation, then remove
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_detection_area_entered(body) -> void:
	if body is Player and not is_dead:
		target_player = body
		current_state = EnemyState.CHASING
		lose_target_timer = lose_target_time
		player_detected.emit()

func _on_detection_area_exited(body) -> void:
	if body == target_player and not is_dead:
		# Only start lose timer if player is actually far enough away
		var distance = global_position.distance_to(body.global_position)
		if distance > detection_range * 0.8: # 80% of detection range
			lose_target_timer = lose_target_time

func _on_attack_area_entered(body) -> void:
	if body is Player and is_attacking and not is_dead:
		body.take_damage(attack_damage)

func get_enemy_type() -> String:
	return "Enemy"
