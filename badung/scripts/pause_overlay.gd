extends CanvasLayer

@onready var overlay_container: Control = $Control
@onready var resume_button: Button = $Control/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Control/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $Control/VBoxContainer/MainMenuButton

var settings_scene = preload("res://scene/menus/settings/settingpage.tscn")
var settings_instance = null

func _ready() -> void:
	# Hide initially
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused
	
	# Connect button signals
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	# Toggle pause with Escape key or Start button
	if event.is_action_pressed("ui_cancel"):  # Escape key by default
		# Don't toggle pause if settings is open
		if settings_instance:
			close_settings()
		elif get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	visible = true
	get_tree().paused = true
	# Make sure audio continues playing
	var music_node = get_node_or_null("/root/Music")
	if music_node:
		music_node.process_mode = Node.PROCESS_MODE_ALWAYS

func resume_game() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_pressed() -> void:
	resume_game()

func _on_settings_pressed() -> void:
	# Open settings as an overlay
	if not settings_instance:
		settings_instance = settings_scene.instantiate()
		settings_instance.process_mode = Node.PROCESS_MODE_ALWAYS
		# Hide pause menu buttons while in settings
		overlay_container.visible = false
		
		# Create a new CanvasLayer to ensure settings renders on top
		var settings_layer = CanvasLayer.new()
		settings_layer.layer = 101  # Above pause overlay (which is 100)
		settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(settings_layer)
		settings_layer.add_child(settings_instance)
		
		# Store reference to the layer so we can remove it later
		settings_instance.set_meta("settings_layer", settings_layer)
		
		# Position settings at (0, 0) since CanvasLayer uses screen coordinates
		if settings_instance is Node2D:
			settings_instance.position = Vector2(0, 0)


func close_settings() -> void:
	if settings_instance:
		# Remove the CanvasLayer that contains the settings
		var settings_layer = settings_instance.get_meta("settings_layer", null)
		if settings_layer:
			settings_layer.queue_free()
		else:
			settings_instance.queue_free()
		settings_instance = null
		# Show pause menu again
		overlay_container.visible = true

func _on_main_menu_pressed() -> void:
	# Return to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main/main_menu.tscn")
