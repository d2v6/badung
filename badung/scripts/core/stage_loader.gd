extends Node2D

func _ready() -> void:
	# Detect which level this is FIRST
	var level_name = get_level_name()
	
	# Load door configs BEFORE anything else initializes
	if GameManager:
		GameManager.load_door_configs(level_name)
		print("[StageLoader] Loaded door configs for '", level_name, "'")
	
	# Setup lighting for level 6
	if level_name == "level6":
		setup_level6_lighting()
	
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
	elif "level3" in scene_name:
		return "level3"
	elif "level4" in scene_name:
		return "level4"
	elif "level5" in scene_name:
		return "level5"
	elif "level6" in scene_name:
		return "level6"
	elif "tutorial" in scene_name:
		return "tutorial"
	else:
		# Default fallback - try to extract from scene name
		var scene = get_tree().current_scene
		if scene:
			return scene.name.to_lower()
		return "unknown"

func _exit_tree() -> void:
	# Reset UI when leaving the level
	if UIManager:
		UIManager.reset_ui()

func setup_level6_lighting() -> void:
	"""Enable lighting system for level 6"""
	print("[StageLoader] Setting up lighting for level 6...")
	
	# Enable player's line of sight
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var line_of_sight = player.get_node_or_null("LineOfSight")
		if line_of_sight:
			line_of_sight.visible = true
			print("[StageLoader] Enabled player LineOfSight")
	
	# Enable canvas modulate and light occlusions in background
	var background = get_tree().get_first_node_in_group("background")
	if background:
		# Enable canvas modulate
		var canvas_modulate = background.get_node_or_null("CanvasModulate")
		if canvas_modulate:
			canvas_modulate.visible = true
			print("[StageLoader] Enabled CanvasModulate")
		
		# Enable all light occlusions
		var light_occlusions = background.get_node_or_null("LightOcclusions")
		if light_occlusions:
			for child in light_occlusions.get_children():
				if child is LightOccluder2D:
					child.visible = true
			print("[StageLoader] Enabled light occlusions")
