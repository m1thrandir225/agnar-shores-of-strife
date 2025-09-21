extends CanvasLayer

var health_bar: ProgressBar
var health_label: Label
var gems_progress: Label
var gem_objective: Label
var enemy_objective: Label
var pause_menu: Control
var main_control: Control

var is_paused: bool = false

func _ready() -> void:
	setup_main_control()
	
	
	GameManager.gem_collected.connect(_on_gem_collected)
	GameManager.level_requirements_updated.connect(_on_requirements_updated)
	GameManager.game_completed.connect(_on_game_completed)
	
	setup_ui()

	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		toggle_pause()

func setup_main_control() -> void:
	main_control = Control.new()
	main_control.name = "MainControl"
	main_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_control.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(main_control)
	

func setup_ui() -> void:
	create_repositioned_ui()
	create_pause_menu()

func create_repositioned_ui() -> void:
	var health_panel = create_ui_panel()
	health_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	health_panel.position = Vector2(20, 20)
	health_panel.size = Vector2(300, 80)
	main_control.add_child(health_panel)
	
	var health_center = CenterContainer.new()
	health_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_panel.add_child(health_center)
	
	var health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 5)
	health_center.add_child(health_container)
	
	health_label = Label.new()
	health_label.text = "Health: 100/100"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_container.add_child(health_label)
	
	health_bar = ProgressBar.new()
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(240, 20)
	health_container.add_child(health_bar)
	
	var gems_panel = create_ui_panel()
	gems_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gems_panel.position = Vector2(-320, 20)
	gems_panel.size = Vector2(300, 80)
	main_control.add_child(gems_panel)
	
	var gems_center = CenterContainer.new()
	gems_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gems_panel.add_child(gems_center)
	
	gems_progress = Label.new()
	gems_progress.text = "Gems: 0/4"
	gems_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gems_progress.add_theme_font_size_override("font_size", 20)
	gems_progress.add_theme_color_override("font_color", Color.GOLD)
	gems_center.add_child(gems_progress)
	
	var objectives_panel = create_ui_panel()
	objectives_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	objectives_panel.position = Vector2(20, -100)
	objectives_panel.size = Vector2(400, 80)
	main_control.add_child(objectives_panel)
	
	var objectives_center = CenterContainer.new()
	objectives_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	objectives_panel.add_child(objectives_center)
	
	var objectives_container = VBoxContainer.new()
	objectives_container.add_theme_constant_override("separation", 5)
	objectives_center.add_child(objectives_container)
	
	gem_objective = Label.new()
	gem_objective.text = "✗ Collect the Gem"
	gem_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gem_objective.add_theme_font_size_override("font_size", 16)
	gem_objective.add_theme_color_override("font_color", Color.YELLOW)
	objectives_container.add_child(gem_objective)
	
	enemy_objective = Label.new()
	enemy_objective.text = "✗ Defeat All Enemies (0/0)"
	enemy_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_objective.add_theme_font_size_override("font_size", 16)
	enemy_objective.add_theme_color_override("font_color", Color.ORANGE_RED)
	objectives_container.add_child(enemy_objective)

func create_pause_menu() -> void:
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	main_control.add_child(pause_menu)
	
	var pause_bg = ColorRect.new()
	pause_bg.color = Color(0, 0, 0, 0.8)
	pause_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(pause_bg)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center_container)
	
	var menu_panel = create_ui_panel()
	menu_panel.custom_minimum_size = Vector2(400, 300)
	center_container.add_child(menu_panel)
	
	var menu_container = VBoxContainer.new()
	menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_theme_constant_override("separation", 20)
	menu_panel.add_child(menu_container)
	
	var menu_margin = MarginContainer.new()
	menu_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_margin.add_theme_constant_override("margin_left", 20)
	menu_margin.add_theme_constant_override("margin_right", 20)
	menu_margin.add_theme_constant_override("margin_top", 20)
	menu_margin.add_theme_constant_override("margin_bottom", 20)
	menu_panel.add_child(menu_margin)
	
	var inner_container = VBoxContainer.new()
	inner_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_container.add_theme_constant_override("separation", 20)
	menu_margin.add_child(inner_container)
	
	var pause_title = Label.new()
	pause_title.text = "GAME PAUSED"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 32)
	pause_title.add_theme_color_override("font_color", Color.WHITE)
	inner_container.add_child(pause_title)
	
	var resume_button = Button.new()
	resume_button.text = "Resume Game"
	resume_button.custom_minimum_size = Vector2(300, 50)
	resume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_button.pressed.connect(toggle_pause)
	inner_container.add_child(resume_button)
	
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.custom_minimum_size = Vector2(300, 50)
	main_menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	inner_container.add_child(main_menu_button)
	
	var quit_button = Button.new()
	quit_button.text = "Quit Game"
	quit_button.custom_minimum_size = Vector2(300, 50)
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_button.pressed.connect(_on_quit_pressed)
	inner_container.add_child(quit_button)

func create_ui_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	
	panel.add_theme_stylebox_override("panel", style_box)
	
	return panel

func toggle_pause() -> void:
	is_paused = !is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	get_tree().paused = is_paused

func show_game_over() -> void:
	get_tree().paused = true
	create_game_over_screen()

func show_victory() -> void:
	get_tree().paused = true
	create_victory_screen()

func create_game_over_screen() -> void:
	var game_over_screen = Control.new()
	game_over_screen.name = "GameOverScreen"
	game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	game_over_screen.mouse_filter = Control.MOUSE_FILTER_PASS
	main_control.add_child(game_over_screen)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_screen.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	game_over_screen.add_child(center)
	
	var panel = create_ui_panel()
	panel.custom_minimum_size = Vector2(500, 400)
	center.add_child(panel)
	
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_theme_constant_override("separation", 30)
	panel.add_child(container)
	
	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.RED)
	container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Agnar has fallen..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(subtitle)
	
	var restart_button = Button.new()
	restart_button.text = "Try Again"
	restart_button.custom_minimum_size = Vector2(300, 60)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.pressed.connect(_on_restart_pressed)
	container.add_child(restart_button)
	
	var menu_button = Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(300, 60)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_on_main_menu_pressed)
	container.add_child(menu_button)

func create_victory_screen() -> void:
	var victory_screen = Control.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	victory_screen.mouse_filter = Control.MOUSE_FILTER_PASS
	main_control.add_child(victory_screen)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.05, 0, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	victory_screen.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	victory_screen.add_child(center)
	
	var panel = create_ui_panel()
	panel.custom_minimum_size = Vector2(600, 500)
	center.add_child(panel)
	
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_theme_constant_override("separation", 30)
	panel.add_child(container)
	
	var title = Label.new()
	title.text = "VICTORY!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color.GOLD)
	container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Agnar has conquered the Shores of Strife!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(subtitle)
	
	var message = Label.new()
	message.text = "All gems have been collected and enemies defeated.\nThe Viking hero returns triumphant!"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	container.add_child(message)
	
	var play_again_button = Button.new()
	play_again_button.text = "Play Again"
	play_again_button.custom_minimum_size = Vector2(300, 60)
	play_again_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_again_button.pressed.connect(_on_restart_pressed)
	container.add_child(play_again_button)
	
	var menu_button = Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(300, 60)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_on_main_menu_pressed)
	container.add_child(menu_button)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_game()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/StartMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_game_completed() -> void:
	show_victory()

func update_health(current: int, maximum: int) -> void:
	if health_bar and health_label:
		health_bar.max_value = maximum
		health_bar.value = current
		health_label.text = "Health: " + str(current) + "/" + str(maximum)

func update_gems(collected: int, total: int) -> void:
	if gems_progress:
		gems_progress.text = "Gems: " + str(collected) + "/" + str(total)

func _on_gem_collected(gem_number: int) -> void:
	var collected = GameManager.get_collected_count()
	update_gems(collected, 4)
	if gem_objective:
		gem_objective.text = ("✓" if collected >= 4 else "✗") + " Collect the Gem"

func _on_requirements_updated(gem_collected: bool, enemies_defeated: bool) -> void:
	if gem_objective:
		gem_objective.text = ("✓" if gem_collected else "✗") + " Collect the Gem"

func show_enemy_count(defeated: int, total: int) -> void:
	if enemy_objective:
		enemy_objective.text = ("✓" if defeated >= total else "✗") + " Defeat All Enemies (" + str(defeated) + "/" + str(total) + ")"

func show_temporary_message(text: String, duration: float = 3.0) -> void:
	if not main_control:
		return
		
	var message = Label.new()
	message.text = text
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color.YELLOW)
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message.position = Vector2(-100, -50)
	message.size = Vector2(200, 100)
	main_control.add_child(message)
	
	var tween = create_tween()
	tween.tween_property(message, "modulate:a", 0.0, duration)
	await tween.finished
	
	message.queue_free()
