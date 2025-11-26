extends Node2D

func _ready() -> void:
	# Detect which level this is FIRST
	var level_name = get_level_name()
	
	# Load door configs BEFORE anything else initializes
	if GameManager:
		GameManager.load_door_configs(level_name)
		print("[StageLoader] Loaded door configs for '", level_name, "'")
	
	# Show UI Manager's player UI (stamina bar and inventory)
	if UIManager:
		UIManager.show_ui()
	
	# Emit stage started signal and show dialogue
	if GameManager:
		GameManager.stage_started.emit()
		GameManager.show_level_dialogue(level_name)
		print("[StageLoader] Stage '", level_name, "' officially started!")

func get_level_name() -> String:
	"""Detect the current level name from the scene"""
	var scene_name = get_tree().current_scene.scene_file_path
	
	# Extract level name from path (e.g., "res://scene/levels/level1.tscn" -> "level1")
	if "level1" in scene_name:
		return "level1"
	elif "level2" in scene_name:
		return "level2"
	elif "tutorial" in scene_name:
		return "tutorial"
	else:
		# Default fallback - try to extract from scene name
		var scene = get_tree().current_scene
		if scene:
			return scene.name.to_lower()
		return "unknown"

func _exit_tree() -> void:
	# Hide UI when leaving the level
	if UIManager:
		UIManager.hide_ui()
