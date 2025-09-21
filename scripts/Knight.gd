extends Enemy

class_name Knight

func _ready() -> void:
	super._ready()
	
	max_health = 80
	current_health = max_health
	move_speed = 80.0
	attack_damage = 10
	attack_range = 70.0
	detection_range = 250.0
	attack_cooldown = 2.0
	

func perform_special_attack() -> void:
	if target_player:
		target_player.take_damage(attack_damage * 1.5)

func get_enemy_type() -> String:
	return "Knight"