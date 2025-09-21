extends Node2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var gem: Gem = $Gem # Changed from horn_part
@onready var enemy_manager: EnemyManager = $EnemyManager
@onready var game_hud: CanvasLayer = $GameHUD

func _ready() -> void:
	print("Level ", GameManager.current_level, " started")
	
	# Reset level requirements in GameManager
	GameManager.start_new_level()
	
	if player:
		player.z_index = 2
		player.health_changed.connect(on_player_health_changed)
		player.player_died.connect(_on_player_died)
		player.player_respawned.connect(_on_player_respawned)
		
		# Give level start HP bonus (except for level 1)
		if GameManager.current_level > 1:
			player.on_level_started()
	
	setup_gem()
	setup_enemy_manager()
	setup_hud()
	
	GameManager.gem_collected.connect(_on_gem_collected)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_completed.connect(_on_game_completed)
	GameManager.level_requirements_updated.connect(_on_level_requirements_updated)

func setup_gem() -> void:
	if not gem:
		gem = find_gem_in_scene(self)
	
	if gem:
		gem.gem_number = GameManager.current_level
		gem.set_gem_type_by_level(GameManager.current_level)
		gem.gem_collected.connect(_on_gem_picked_up)
		print("Gem ", gem.gem_number, " (", gem.gem_type, ") ready for collection")

func setup_enemy_manager() -> void:
	if not enemy_manager:
		enemy_manager = EnemyManager.new()
		enemy_manager.name = "EnemyManager"
		add_child(enemy_manager)
	
	# Connect to enemy manager signals
	enemy_manager.all_enemies_defeated.connect(_on_all_enemies_defeated)
	enemy_manager.enemy_count_updated.connect(_on_enemy_count_updated)

func find_gem_in_scene(node: Node) -> Gem:
	if node is Gem:
		return node
	
	for child in node.get_children():
		var result = find_gem_in_scene(child)
		if result:
			return result
	
	return null

func _on_gem_picked_up(gem_number: int) -> void:
	GameManager.collect_gem(gem_number)

func _on_all_enemies_defeated() -> void:
	print("All enemies in level defeated!")

func _on_enemy_count_updated(defeated: int, total: int) -> void:
	print("Enemy progress: ", defeated, "/", total, " defeated")
	if game_hud and game_hud.has_method("show_enemy_count"):
		game_hud.show_enemy_count(defeated, total)

func _on_level_requirements_updated(gem_collected: bool, enemies_defeated: bool) -> void:
	var gem_status = "✓" if gem_collected else "✗"
	var enemy_status = "✓" if enemies_defeated else "✗"
	print("Level Progress - Gem: ", gem_status, " | Enemies: ", enemy_status)
	
	if gem_collected and enemies_defeated:
		print("💎 LEVEL COMPLETE! 💎")

func on_player_health_changed(new_health: int) -> void:
	print("Player health changed: ", new_health)
	if game_hud and game_hud.has_method("update_health"):
		game_hud.update_health(new_health, player.max_health)

func _on_player_died() -> void:
	print("Player died")


func _on_player_respawned() -> void:
	print("Player respawned")

func _on_gem_collected(gem_number: int) -> void:
	print("Gem ", gem_number, " has been added to Agnar's collection!")
	# The GameHUD handles gem collection through its own signal connection

func _on_level_completed(level_number: int) -> void:
	print("Level ", level_number, " completed! Another gem secured...")
	if game_hud and game_hud.has_method("show_temporary_message"):
		game_hud.show_temporary_message("Level " + str(level_number) + " Complete!", 3.0)

func _on_game_completed() -> void:
	print("All 4 mystical gems collected! Agnar's power is complete!")
	# The GameHUD handles game completion through its own signal connection

func setup_hud() -> void:
	if not game_hud:
		game_hud = get_node_or_null("GameHUD")
		
		if not game_hud:
			var hud_scene_path = "res://scenes/ui/GameHUD.tscn"
			if ResourceLoader.exists(hud_scene_path):
				var hud_scene = load(hud_scene_path)
				game_hud = hud_scene.instantiate()
				add_child(game_hud)
			else:
				print("Warning: GameHUD scene not found at ", hud_scene_path)
				return
	
	if game_hud:
		game_hud.add_to_group("hud")
	
	if player and game_hud:
		if game_hud.has_method("update_health"):
			game_hud.update_health(player.current_health, player.max_health)
		
		if game_hud.has_method("update_gems"):
			game_hud.update_gems(GameManager.get_collected_count(), 4)
