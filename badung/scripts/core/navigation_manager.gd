extends Node

# Singleton for handling scene navigation and state resets
var current_scene: String = ""

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	print("[NavigationManager] Ready")

func _on_scene_changed() -> void:
	var new_scene = get_tree().current_scene.scene_file_path
	print("[NavigationManager] Scene changed to: ", new_scene)
	current_scene = new_scene

func goto_main_menu() -> void:
	"""Navigate to main menu and reset game state"""
	print("[NavigationManager] Going to main menu...")
	
	# Reset UI state
	if UIManager:
		UIManager.reset_ui()
		print("[NavigationManager] UIManager state reset")
	
	# Reset game state
	if GameManager:
		GameManager.reset()
		print("[NavigationManager] GameManager state reset")
	
	# Reset music to loop
	var music_manager = get_tree().get_first_node_in_group("music_manager")
	if music_manager:
		music_manager.reset_to_loop()
		print("[NavigationManager] Music reset to loop")
	
	# Unpause game if paused
	get_tree().paused = false
	
	# Change scene
	get_tree().change_scene_to_file("res://scene/menus/main_menu.tscn")

func goto_scene(scene_path: String) -> void:
	"""Navigate to a scene"""
	print("[NavigationManager] Going to scene: ", scene_path)
	
	# Reset UI when leaving a level
	if UIManager:
		UIManager.reset_ui()
	
	get_tree().change_scene_to_file(scene_path)

func reset_current_scene() -> void:
	"""Reload current scene"""
	print("[NavigationManager] Reloading scene: ", current_scene)
	
	# Reset UI before reloading
	if UIManager:
		UIManager.reset_ui()
	
	get_tree().paused = false
	get_tree().change_scene_to_file(current_scene)
