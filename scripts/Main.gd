extends Node2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D

func _ready() -> void:
    if player:
        player.health_changed.connect(on_player_health_changed)
        player.player_died.connect(_on_player_died)
        player.player_respawned.connect(_on_player_respawned)

func setup_camera_limits() -> void:
    if camera:
        camera.limit_left = 0
        camera.limit_top = 0
        camera.limit_right = 0
        camera.limit_bottom = 0

func on_player_health_changed(new_health: int) -> void:
    print("Player health changed: ", new_health)

func _on_player_died() -> void:
    print("Player died")

    await get_tree().create_timer(3.0).timeout
    get_tree().reload_current_scene()

func _on_player_respawned() -> void:
    print("Player respawned")