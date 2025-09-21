extends Node

# Game progress tracking
var gems_collected: Array[bool] = [false, false, false, false] # 4 gems total
var current_level: int = 2
var total_levels: int = 4

# Level completion tracking
var current_level_gem_collected: bool = false
var current_level_enemies_defeated: bool = false

# Level scenes - configure these paths
var level_scenes: Array[String] = [
	"res://scenes/levels/Level1.tscn",
	"res://scenes/levels/Level2.tscn",
	"res://scenes/levels/Level3.tscn",
	"res://scenes/levels/Level4.tscn"
]

# Signals
signal gem_collected(gem_number: int)
signal level_completed(level_number: int)
signal game_completed
signal level_requirements_updated(gem_collected: bool, enemies_defeated: bool)
signal level_loading(level_number: int)

func _ready() -> void:
	print("GameManager initialized")
	
	# Determine current level from scene name
	detect_current_level()

func detect_current_level() -> void:
	var scene_file = get_tree().current_scene.scene_file_path
	print("Current scene: ", scene_file)
	
	# Extract level number from scene path
	for i in range(level_scenes.size()):
		if scene_file == level_scenes[i]:
			current_level = i + 1
			print("Detected level: ", current_level)
			return
	
	# If not found, assume level 1
	current_level = 1
	print("Level not detected, defaulting to level 1")

func start_new_level() -> void:
	# Reset level completion requirements
	current_level_gem_collected = false
	current_level_enemies_defeated = false
	level_requirements_updated.emit(false, false)
	print("Level ", current_level, " requirements reset")

func collect_gem(gem_number: int) -> void:
	if gem_number < 1 or gem_number > 4:
		print("Invalid gem number: ", gem_number)
		return
	
	if gems_collected[gem_number - 1]:
		print("Gem ", gem_number, " already collected!")
		return
	
	gems_collected[gem_number - 1] = true
	current_level_gem_collected = true
	
	gem_collected.emit(gem_number)
	level_requirements_updated.emit(current_level_gem_collected, current_level_enemies_defeated)
	
	print("Gem ", gem_number, " collected! Progress: ", get_collected_count(), "/4")
	
	# Check if level can be completed
	check_level_completion()

func all_enemies_defeated() -> void:
	current_level_enemies_defeated = true
	level_requirements_updated.emit(current_level_gem_collected, current_level_enemies_defeated)
	
	print("All enemies defeated!")
	
	# Check if level can be completed
	check_level_completion()

func check_level_completion() -> void:
	if current_level_gem_collected and current_level_enemies_defeated:
		print("Level requirements met! Completing level...")
		complete_level()
	else:
		var missing = []
		if not current_level_gem_collected:
			missing.append("Gem")
		if not current_level_enemies_defeated:
			missing.append("Defeat all enemies")
		
		print("Level not complete yet. Still need: ", missing)

func complete_level() -> void:
	level_completed.emit(current_level)
	print("Level ", current_level, " completed!")
	
	# Check if all gems collected
	if is_game_complete():
		complete_game()
	else:
		# Show completion message and load next level
		show_level_transition()

func show_level_transition() -> void:
	print("🎉 Level ", current_level, " Complete! 🎉")
	print("Agnar found a precious gem and advances deeper...")
	
	# Wait for celebration
	await get_tree().create_timer(3.0).timeout
	load_next_level()

func load_next_level() -> void:
	current_level += 1
	
	if current_level > total_levels:
		print("Game completed!")
		game_completed.emit()
		# Could show victory screen or restart
		restart_game()
		return
	
	# Reset level completion tracking
	current_level_gem_collected = false
	current_level_enemies_defeated = false
	
	print("Loading level ", current_level)
	
	# Give player health bonus for new level
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_level_started"):
		player.on_level_started()
	
	# Load the new level
	level_loading.emit(current_level)
	await get_tree().create_timer(0.1).timeout
	
	if current_level <= level_scenes.size():
		get_tree().change_scene_to_file(level_scenes[current_level - 1])
	else:
		print("Error: No scene defined for level ", current_level)

func is_game_complete() -> bool:
	return get_collected_count() >= 4

func get_collected_count() -> int:
	var count = 0
	for collected in gems_collected:
		if collected:
			count += 1
	return count

func complete_game() -> void:
	game_completed.emit()
	print("🏆 VICTORY! 🏆")
	print("Agnar has collected all 4 mystical gems!")
	print("The power of the gems calls him to Valhalla!")
	
	# Show victory screen
	show_victory_screen()

func show_victory_screen() -> void:
	print("=== GAME COMPLETED ===")
	print("Agnar's quest is complete!")
	print("The 4 gems of power shine with divine light!")
	print("The gods of Asgard welcome the warrior home!")
	print("Press any key to restart...")
	
	# Wait then restart
	await get_tree().create_timer(5.0).timeout
	restart_game()

func restart_game() -> void:
	print("Restarting game...")
	
	# Reset all progress
	gems_collected = [false, false, false, false]
	current_level = 1
	current_level_gem_collected = false
	current_level_enemies_defeated = false
	
	# Load first level
	if level_scenes.size() > 0:
		get_tree().change_scene_to_file(level_scenes[0])
	else:
		print("ERROR: No level scenes configured!")

func get_progress_text() -> String:
	return "Gems: " + str(get_collected_count()) + "/4"

func get_level_progress_text() -> String:
	var gem_status = "✓" if current_level_gem_collected else "✗"
	var enemies_status = "✓" if current_level_enemies_defeated else "✗"
	return "Gem: " + gem_status + " | Enemies: " + enemies_status

# Manual level loading functions (for testing)
func load_specific_level(level_number: int) -> void:
	if level_number >= 1 and level_number <= level_scenes.size():
		current_level = level_number
		get_tree().change_scene_to_file(level_scenes[level_number - 1])
	else:
		print("Invalid level number: ", level_number)

func reload_current_level() -> void:
	if current_level >= 1 and current_level <= level_scenes.size():
		get_tree().change_scene_to_file(level_scenes[current_level - 1])
