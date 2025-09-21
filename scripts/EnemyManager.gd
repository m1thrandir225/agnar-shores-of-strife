extends Node
class_name EnemyManager

var enemies: Array[Enemy] = []
var total_enemies: int = 0
var enemies_defeated: int = 0

# Signals
signal all_enemies_defeated
signal enemy_count_updated(defeated: int, total: int)

func _ready() -> void:
	await get_tree().process_frame
	find_and_register_enemies()

func find_and_register_enemies() -> void:
	enemies.clear()
	enemies_defeated = 0
	
	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	
	if enemy_nodes.is_empty():
		find_enemies_recursive(get_tree().current_scene)
	else:
		for enemy in enemy_nodes:
			if enemy is Enemy:
				register_enemy(enemy)
	
	total_enemies = enemies.size()
	print("EnemyManager found ", total_enemies, " enemies")
	
	# Emit initial count
	enemy_count_updated.emit(enemies_defeated, total_enemies)
	
	if total_enemies == 0:
		print("No enemies in level - enemy requirement auto-completed")
		GameManager.all_enemies_defeated()

func find_enemies_recursive(node: Node) -> void:
	if node is Enemy:
		register_enemy(node)
	
	for child in node.get_children():
		find_enemies_recursive(child)

func register_enemy(enemy: Enemy) -> void:
	if enemy in enemies:
		return # Already registered
	
	enemies.append(enemy)
	
	# Connect to enemy death signal
	enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	
	# Add enemy to group for easy finding
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")
	
	print("Registered enemy: ", enemy.get_class())

func _on_enemy_died(enemy: Enemy) -> void:
	if enemy in enemies:
		enemies.erase(enemy)
		enemies_defeated += 1
		
		# Give HP reward for killing knights
		if enemy.get_enemy_type() == "Knight":
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("heal"):
				player.heal(10)
				print("Knight defeated! Player gained 10 HP")
		
		print("Enemy defeated! Remaining: ", enemies.size(), "/", total_enemies)
		enemy_count_updated.emit(enemies_defeated, total_enemies)
		
		# Check if all enemies are defeated
		if enemies.is_empty():
			print("All enemies defeated!")
			all_enemies_defeated.emit()
			GameManager.all_enemies_defeated()

func get_enemy_count() -> Dictionary:
	return {
		"defeated": enemies_defeated,
		"total": total_enemies,
		"remaining": enemies.size()
	}

func spawn_enemy(enemy_scene: PackedScene, position: Vector2) -> void:
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	get_tree().current_scene.add_child(enemy)
	register_enemy(enemy)
	
	total_enemies += 1
	enemy_count_updated.emit(enemies_defeated, total_enemies)
