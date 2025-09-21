extends Control

@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var tip_label: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var background: ColorRect = $Background
@onready var center_container: CenterContainer = $CenterContainer

var loading_tips: Array[String] = [
	"Use WASD to move Agnar around the battlefield",
	"Hold Shift while moving to run faster",
	"Attack with Space, Z, or Left Mouse Button",
	"Collect gems and defeat all enemies to complete levels",
	"Each level contains one sacred gem to collect",
	"Agnar grows stronger with each gem collected"
]

var target_scene: String = ""
var current_progress: float = 0.0
var target_progress: float = 100.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	setup_ui()
	show_random_tip()

func setup_ui() -> void:
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	loading_label.text = "Loading..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 48)
	loading_label.add_theme_color_override("font_color", Color.WHITE)
	
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(600, 40)
	
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 24)
	tip_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	tip_label.custom_minimum_size = Vector2(800, 100)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func show_random_tip() -> void:
	var random_tip = loading_tips[randi() % loading_tips.size()]
	tip_label.text = "TIP: " + random_tip

func load_scene(scene_path: String) -> void:
	target_scene = scene_path
	start_loading()

func start_loading() -> void:
	var tween = create_tween()
	tween.tween_method(update_progress, 0.0, 100.0, 2.0)
	await tween.finished
	
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		print("Error: Scene not found: ", target_scene)

func update_progress(value: float) -> void:
	progress_bar.value = value
	
	if value < 33:
		loading_label.text = "Loading..."
	elif value < 66:
		loading_label.text = "Preparing battlefield..."
	elif value < 90:
		loading_label.text = "Summoning enemies..."
	else:
		loading_label.text = "Almost ready..."