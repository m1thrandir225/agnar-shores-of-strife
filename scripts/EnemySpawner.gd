extends Node2D

class_name EnemySpawner

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 10

var current_enemies: int = 0
var spawn_timer: float = 0.0

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    spawn_timer -= delta

    if spawn_timer <= 0 and current_enemies < max_enemies:
        spawn_random_enemy()
        spawn_timer = spawn_interval

func spawn_random_enemy() -> void:
    if enemy_scenes.is_empty():
        return
    
    var random_scene = enemy_scenes[randi() % enemy_scenes.size()]
    var enemy = random_scene.instantiate()

    var spawn_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
    enemy.global_position = global_position + spawn_offset

    enemy.enemy_died.connect(_on_enemy_died)

    get_parent().add_child(enemy)
    current_enemies += 1

func _on_enemy_died() -> void:
    current_enemies -= 1
    spawn_timer = spawn_interval
