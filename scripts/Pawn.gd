extends Enemy

class_name Pawn

func _ready() -> void:
	super._ready()
	
	# Pawn-specific stats
	max_health = 35
	current_health = max_health
	move_speed = 50.0
	attack_damage = 5
	attack_range = 70.0
	detection_range = 200.0
	attack_cooldown = 2.0
	
	print("Pawn spawned with ", max_health, " health")

func perform_special_attack() -> void:
	print("Pawn performs Shield Bash!")
	# Heavy attack that does more damage and knocks back
	if target_player:
		target_player.take_damage(attack_damage * 1.5)

func get_enemy_type() -> String: # Changed from get_class()
	return "Pawn"