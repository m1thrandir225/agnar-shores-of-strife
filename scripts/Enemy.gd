extends CharacterBody2D

class_name Enemy


# Base stats for enemy
@export var max_health: int = 50
@export var move_speed: float = 100.0
@export var attack_damage: int = 10
@export var attack_range: float = 60.0
@export var detection_range: float = 200.0
@export var attack_cooldown: float = 1.5


#Current
var current_health: int
var is_dead: bool = false
var is_attacking: bool = false
var attack_timer: float = 0.0
var target_player: Player = null

enum EnemyState {
    IDLE,
    CHASING,
    ATTACKING,
    STUNNED,
    DEAD
}

var current_state: EnemyState = EnemyState.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var collision_shape: CollisionShape2D = $Collision
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent


signal enemy_died
signal enemy_attacked
signal player_detected


func _ready() -> void:
    current_health = max_health
    setup_areas()

    if detection_area:
        detection_area.body_entered.connect(_on_detection_area_entered)
        detection_area.body_exited.connect(_on_detection_area_exited)
    
    if attack_area:
        attack_area.body_entered.connect(_on_attack_area_entered)

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    
    if attack_timer > 0:
        attack_timer -= delta
        if attack_timer <= 0:
            is_attacking = false
            attack_area.monitoring = false

    match current_state:
        EnemyState.IDLE:
            handle_idle()
        EnemyState.CHASING:
            handle_chasing()
        EnemyState.ATTACKING:
            handle_attacking()
        EnemyState.STUNNED:
            handle_stunned()
    
    handle_animation()

    move_and_slide()

func setup_areas() -> void:
    if detection_area:
        var detection_shape = CircleShape2D.new()
        detection_shape.radius = detection_range

        var detection_collision = CollisionShape2D.new()
        detection_collision.shape = detection_shape
        detection_area.add_child(detection_collision)
        detection_area.monitoring = true

    if attack_area:
        var attack_shape = CircleShape2D.new()
        attack_shape.radius = attack_range

        var attack_collision = CollisionShape2D.new()
        attack_collision.shape = attack_shape
        attack_area.add_child(attack_collision)
        attack_area.monitoring = false

func handle_idle() -> void:
    velocity = Vector2.ZERO

func handle_chasing() -> void:
    if not target_player or target_player.is_dead:
        current_state = EnemyState.IDLE
        target_player = null
        return
    
    var direction = (target_player.global_position - global_position).normalized()
    velocity = direction * move_speed

    if direction.x < 0:
        animated_sprite.flip_h = true
    elif direction.x > 0:
        animated_sprite.flip_h = false

    var distance_to_player = global_position.distance_to(target_player.global_position)
    if distance_to_player <= attack_range and attack_timer <= 0:
        current_state = EnemyState.ATTACKING
        perform_attack()

func handle_attacking() -> void:
    velocity = velocity * 0.1

    if not is_attacking:
        current_state = EnemyState.CHASING

func handle_stunned() -> void:
    velocity = velocity * 0.5

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

    if attack_area:
        attack_area.monitoring = true
    
    enemy_attacked.emit()


func perform_special_attack() -> void:
    pass

func take_damage(damage: int) -> void:
    if is_dead:
        return

    current_health -= damage
    current_health = max(0, current_health)

    animated_sprite.modulate = Color.RED
    await get_tree().create_timer(0.1).timeout
    animated_sprite.modulate = Color.WHITE

    if current_health <= 0:
        die()
    else:
        current_state = EnemyState.STUNNED
        await get_tree().create_timer(0.3).timeout
        if not is_dead:
            current_state = EnemyState.CHASING

func die() -> void:
    if is_dead:
        return
    
    is_dead = true
    current_state = EnemyState.DEAD

    velocity = Vector2.ZERO

    if attack_area:
        attack_area.monitoring = false
    if detection_area:
        detection_area.monitoring = false
    
    enemy_died.emit()
    await get_tree().create_timer(2.0).timeout
    queue_free()

func _on_detection_area_entered(body: Node2D) -> void:
    if body is Player and not is_dead:
        target_player = body
        current_state = EnemyState.CHASING
        player_detected.emit()

func _on_detection_area_exited(body: Node2D) -> void:
    if body == target_player and not is_dead:
        var distance = global_position.distance_to(target_player.global_position)
        if distance > detection_range * 1.2:
            target_player = null
            current_state = EnemyState.IDLE

func _on_attack_area_entered(body: Node2D) -> void:
    if body is Player and is_attacking:
        body.take_damage(attack_damage)
