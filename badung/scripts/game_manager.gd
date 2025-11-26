extends Node

# Track collected objectives
var has_objective: bool = false
var reported: bool = false
var collected_keys: Array[String] = []  # Track which keys have been collected

var mom_reference: CharacterBody2D = null

# Level progression tracking
var highest_level_unlocked: int = 1  # Level 1 always unlocked at start

# Door configuration: door_id -> {is_locked: bool, required_key_id: String}
var door_configs: Dictionary = {
	"DoorA": {"is_locked": true, "required_key_id": "key_orange"},
	# Add more doors here as needed
	# "DoorB": {"is_locked": false, "required_key_id": ""},
}

signal objective_collected()
signal player_reported()
signal stage_started()

func _ready() -> void:
	# Reset initial state
	reset()
	print("GameManager ready - State reset for new scene")
	
	# Connect to scene tree to detect scene changes
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	# When the root node changes, it means a new scene was loaded
	if node == get_tree().current_scene:
		reset()
		# Try to find Mom in the new scene
		call_deferred("_find_mom")
		print("GameManager: New scene detected, resetting state")

func _find_mom() -> void:
	"""Find and register Mom node in the current scene"""
	var current_scene = get_tree().current_scene
	if current_scene:
		mom_reference = current_scene.get_node_or_null("Mom")
		if mom_reference:
			print("GameManager: Found and registered Mom from scene")
		else:
			print("GameManager: No Mom node found in scene")

func reset() -> void:
	# Reset all game state variables (but keep highest_level_unlocked for progression)
	has_objective = false
	reported = false
	mom_reference = null
	print("GameManager: State reset - has_objective=false, reported=false")

func collect_objective() -> void:
	has_objective = true
	objective_collected.emit()
	print("GameManager: Objective collected, has_objective = ", has_objective)

func register_mom(mom: CharacterBody2D) -> void:
	"""Mom registers itself with the GameManager when ready"""
	mom_reference = mom
	print("GameManager: Mom registered")

func on_player_reported() -> void:
	"""Called by Kaka when player is spotted - signals UP from Kaka"""
	reported = true
	print("GameManager: Player has been reported!")
	
	# Call DOWN to Mom to activate hunt mode
	if mom_reference and mom_reference.has_method("activate_hunt_mode"):
		mom_reference.activate_hunt_mode()
		print("GameManager: Told Mom to activate hunt mode")

func on_player_caught() -> void:
	"""Called by Mom when player is caught - signals UP from Mom"""
	print("GameManager: Player caught!")
	
	# Call DOWN to UIManager to show game over screen
	if UIManager:
		UIManager.show_game_over_failure()
		print("GameManager: Told UIManager to show game over")

func get_door_config(door_id: String) -> Dictionary:
	"""Get configuration for a specific door"""
	if door_id in door_configs:
		return door_configs[door_id]
	else:
		# Return default config for unknown doors
		return {"is_locked": false, "required_key_id": ""}

func on_key_collected(key_id: String) -> void:
	"""Called when player picks up a key - signals UP from Player"""
	if key_id not in collected_keys:
		collected_keys.append(key_id)
		print("GameManager: Key collected - ", key_id)

func unlock_level(level_number: int) -> void:
	"""Unlock a level after completing the current level"""
	if level_number > highest_level_unlocked:
		highest_level_unlocked = level_number
		print("GameManager: Level ", level_number, " unlocked! Highest unlocked: ", highest_level_unlocked)

func is_level_unlocked(level_number: int) -> bool:
	"""Check if a level is unlocked"""
	return level_number <= highest_level_unlocked
