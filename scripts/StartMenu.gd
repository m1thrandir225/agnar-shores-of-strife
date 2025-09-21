extends Control

@onready var start_button: Button = $Container/ButtonContainer/StartButton
@onready var quit_button: Button = $Container/ButtonContainer/QuitButton
@onready var title_label: Label = $Container/Title
@onready var subtitle_label: Label = $Container/Subtitle
@onready var background: ColorRect = $Background
@onready var main_container: VBoxContainer = $Container

func _ready() -> void:
	# IMPORTANT: Set this Control to fill the entire screen first
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	setup_ui()
	connect_signals()
	animate_title()

func setup_ui() -> void:
	# Set up background to fill entire screen
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.1, 0.1, 0.2, 0.9) # Dark blue
	
	# SIMPLE FIX: Use CenterContainer to properly center everything
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Remove the main container from its current parent and add to center container
	main_container.get_parent().remove_child(main_container)
	center_container.add_child(main_container)
	add_child(center_container)
	
	# Set up title
	title_label.text = "AGNAR: SHORES OF STRIFE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	
	# Set up subtitle
	subtitle_label.text = "A Viking's Quest for the Sacred Gems"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 28)
	subtitle_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	
	# Set up buttons
	start_button.text = "BEGIN QUEST"
	quit_button.text = "LEAVE REALM"
	
	# Style buttons for fullscreen
	for button in [start_button, quit_button]:
		button.add_theme_font_size_override("font_size", 32)
		button.custom_minimum_size = Vector2(300, 70)
		
		# Add some styling
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.2, 0.1, 0.0, 0.8)
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_color = Color.GOLD
		style_box.corner_radius_top_left = 10
		style_box.corner_radius_top_right = 10
		style_box.corner_radius_bottom_left = 10
		style_box.corner_radius_bottom_right = 10
		
		button.add_theme_stylebox_override("normal", style_box)
	
	# Add version label at bottom
	var version_label = Label.new()
	version_label.text = "v1.0.0"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 16)
	version_label.add_theme_color_override("font_color", Color.GRAY)
	version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	version_label.position.y -= 20
	add_child(version_label)

func connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func animate_title() -> void:
	# Fade in title with scale effect
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0)
	
	# Animate subtitle after title
	subtitle_label.modulate.a = 0.0
	await tween.finished
	
	var subtitle_tween = create_tween()
	subtitle_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)

func _on_start_pressed() -> void:
	print("Starting game...")
	
	# Fade out menu
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	
	# Load first level
	get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

func _on_quit_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()
