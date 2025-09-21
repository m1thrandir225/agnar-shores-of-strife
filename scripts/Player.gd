extends CharacterBody2D

class_name Player

@export var walk_speed: float = 200.0
@export var run_speed: float = 400.0
@export var acceleration: float = 2000.0
@export var friction: float = 2000.0

@export var max_health: int = 100
@export var attack_damage: int = 30
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 0.3
@export var attack_duration: float = 0.8
@export var attack_duration_timer: float = 0.0

var current_health: int
var is_dead: bool = false
var is_attacking: bool = false
var is_running: bool = false
var attack_timer: float = 0.0
var can_attack: bool = true

var input_vector: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

signal health_changed(new_health: int)
signal player_died
signal player_attacked
signal player_respawned

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health)
	
	add_to_group("player")
	
	collision_layer = 1
	collision_mask = 6
	
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)
		attack_area.collision_layer = 0
		attack_area.collision_mask = 4
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
	

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	handle_input()
	handle_movement(delta)
	handle_animation()

func handle_input() -> void:
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	input_vector = input_vector.normalized()
	
	is_running = Input.is_action_pressed("run") and input_vector != Vector2.ZERO and not is_attacking
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_dead:
		perform_attack()

func handle_movement(delta: float) -> void:
	var movement_input = Vector2.ZERO if is_attacking else input_vector
	
	if movement_input != Vector2.ZERO:
		var target_speed = run_speed if is_running else walk_speed
		velocity = velocity.move_toward(movement_input * target_speed, acceleration * delta)
	else:
		var friction_multiplier = 3.0 if is_attacking else 1.0
		velocity = velocity.move_toward(Vector2.ZERO, friction * friction_multiplier * delta)
	
	move_and_slide()

func handle_animation() -> void:
	if not animated_sprite:
		return
	
	if not is_attacking:
		if input_vector.x < 0:
			animated_sprite.flip_h = true
		elif input_vector.x > 0:
			animated_sprite.flip_h = false
	
	if is_dead:
		play_animation("die")
	elif is_attacking:
		play_animation("attack")
	elif velocity.length() > 10:
		if is_running:
			play_animation("run")
		else:
			play_animation("walk")
	else:
		play_animation("idle")

func play_animation(animation_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			if animated_sprite.animation != animation_name:
				animated_sprite.play(animation_name)
		else:
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
			elif animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.play("walk")

func perform_attack() -> void:
	if is_attacking or is_dead or not can_attack:
		return
	
	
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown
	attack_duration_timer = attack_duration
	
	if attack_area:
		attack_area.monitoring = true
	
	player_attacked.emit()

func _on_animation_finished() -> void:
	if is_attacking and animated_sprite.animation == "attack":
		is_attacking = false
		if attack_area:
			attack_area.monitoring = false

func _on_attack_area_body_entered(body) -> void:
	if not is_attacking:
		return
	
	if body.has_method("take_damage") and body != self:
		body.take_damage(attack_damage)

func _on_attack_area_body_exited(body) -> void:
	pass

func take_damage(damage: int) -> void:
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	health_changed.emit(current_health)
	
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	var old_health = current_health
	current_health = min(current_health + amount, max_health)
	var actual_heal = current_health - old_health
	
	if actual_heal > 0:
		health_changed.emit(current_health)
		show_heal_effect(actual_heal)

func show_heal_effect(amount: int) -> void:
	var heal_label = Label.new()
	heal_label.text = "+" + str(amount) + " HP"
	heal_label.modulate = Color.GREEN
	heal_label.position = global_position + Vector2(0, -30)
	heal_label.z_index = 10
	
	get_tree().current_scene.add_child(heal_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(heal_label, "position", heal_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(heal_label, "modulate:a", 0.0, 1.0)
	
	tween.tween_callback(heal_label.queue_free)

func on_level_started() -> void:
	heal(25)

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	velocity = Vector2.ZERO
	is_attacking = false
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()
	
	player_died.emit()

func respawn() -> void:
	is_dead = false
	is_attacking = false
	can_attack = true
	current_health = max_health
	attack_timer = 0.0
	
	health_changed.emit(current_health)
	player_respawned.emit()
