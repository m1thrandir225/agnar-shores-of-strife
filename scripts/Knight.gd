extends Enemy

class_name Knight

func _ready() -> void:
    super._ready()

    max_health = 80
    current_health = max_health
    move_speed = 80.0
    attack_damage = 25
    attack_range = 70
    detection_range = 250.0
    attack_cooldown = 2.0

func perform_special_attack() -> void:
    if target_player and not target_player.is_dead:
        target_player.take_damage(attack_damage * 2)
        print("Knight performs special attack!")