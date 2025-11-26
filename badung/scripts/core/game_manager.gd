extends Node

# Track collected objectives
var has_objective: bool = false
var reported: bool = false
var collected_keys: Array[String] = []  # Track which keys have been collected

var mom_reference: CharacterBody2D = null

# Level progression tracking
var highest_level_unlocked: int = 1  # Level 1 always unlocked at start

# Current level's door configuration
var door_configs: Dictionary = {}

# Door configurations per level
var level_door_configs: Dictionary = {
	"level1": {
		'DoorAnak': {"is_locked": false, "required_key_id": ""},
		'DoorKakaH': {"is_locked": false, "required_key_id": ""},
	},
	"level2": {
		'DoorAnak': {"is_locked": true, "required_key_id": "A"},
		'DoorKakaH': {"is_locked": false, "required_key_id": ""},
		'DoorKakaV': {"is_locked": false, "required_key_id": ""},
		'DoorTamuV': {"is_locked": true, "required_key_id": "B"},
	},
	"level3": {
	},
	"level4": {
	},
	"level5": {
	},
		"level6": {
	},
}

# Level dialogue data
var level_dialogues: Dictionary = {
	"level1": [
		{"character": "Anak", "text": "Sudah malam, tapi aku belum ngantuk..", "show_character": true},
		{"character": "Anak", "text": "Pengen main Tablet, deh! Tapi Tabletnya disembunyiin, nih :(", "show_character": true},
		{"character": "Anak", "text": "Bantuin aku ambil Tablet ya!", "show_character": true},
	],
	"level2": [
		{"character": "Emak", "text": "Wah, Si Badung udah berani ambil tablet! Mulai malam ini aku harus jaga-jaga!", "show_character": true},
		{"character": "Anak", "text": "Aduh, sekarang Emak jaga-jaga di dalam rumah! Aku harus hati-hati biar gak ketauan Emak!", "show_character": true},
		{"character": "Anak", "text": "Ruangan-ruangan juga dikunci, nih! Aku harus cari kunci nya dulu baru bisa ambil tabletnya!", "show_character": true},
	],
	"level3": [
		{"character": "Anak", "text": "Susah juga ambil tablet tanpa ketauan Emak...", "show_character": true},
		{"character": "Anak", "text": "Aku harus ngerjain Emak dengan lempar barang-barang di rumah, biar Emak gak ngejar Aku!", "show_character": true},
		{"character": "Anak", "text": "Harus hati-hati juga sama mainan berantakan, kalo keinjek Emak bisa datang!", "show_character": true},
	],
	"level4": [
		{"character": "Emak", "text": "Duh, dasar Si Badung! Tiap malam ada aja caranya dapet tablet!”", "show_character": true},
		{"character": "Emak", "text": "Butuh bantuan Kakak biar Si Badung gak kabur-kaburan lagi!", "show_character": true},
	],
	"level5": [
		{"character": "Anak", "text": "Kakak ada di pihak Emak, nih! Susah banget mau ambil tablet!", "show_character": true},
		{"character": "Anak", "text": "Aha! Aku mau sembunyi-sembunyi di lemari, deh, biar gak ketauan!", "show_character": true},
	],
	"level6": [
		{"character": "Anak", "text": "Sudah malam, tapi aku belum ngantuk..", "show_character": true},
		{"character": "Anak", "text": "Pengen main Tablet, deh! Tapi Tabletnya disembunyiin, nih :(", "show_character": true},
	],
}

# Result manager state
var is_processing_result: bool = false  # Flag to prevent multiple result handling

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
		# Load door configs immediately based on scene name
		_load_configs_for_current_scene()
		# Try to find Mom in the new scene
		call_deferred("_find_mom")
		print("GameManager: New scene detected, resetting state")

func _load_configs_for_current_scene() -> void:
	"""Detect and load door configs for the current scene"""
	var scene_path = get_tree().current_scene.scene_file_path
	var level_name = ""
	
	# Extract level name from scene path
	if "level1" in scene_path:
		level_name = "level1"
	elif "level2" in scene_path:
		level_name = "level2"
	elif "level3" in scene_path:
		level_name = "level3"
	elif "level4" in scene_path:
		level_name = "level4"
	elif "level5" in scene_path:
		level_name = "level5"
	elif "level6" in scene_path:
		level_name = "level6"
	elif "tutorial" in scene_path:
		level_name = "tutorial"
	
	if level_name != "":
		load_door_configs(level_name)

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
	is_processing_result = false  # Reset result processing flag
	print("GameManager: State reset - has_objective=false, reported=false")

func start_level_with_dialogue(level_name: String) -> void:
	"""Start a level by showing its intro dialogue first"""
	# Load the door configuration for this level
	load_door_configs(level_name)
	
	# Show dialogue
	show_level_dialogue(level_name)

func load_door_configs(level_name: String) -> void:
	"""Load door configuration for a specific level"""
	if level_name in level_door_configs:
		door_configs = level_door_configs[level_name]
		print("[GameManager] Loaded door configs for level '", level_name, "': ", door_configs)
	else:
		door_configs = {}
		print("[GameManager] No door configs for level '", level_name, "'")

func show_level_dialogue(level_name: String) -> void:
	"""Show the intro dialogue for a level"""
	var dialogues = level_dialogues.get(level_name, [])
	
	if dialogues.size() > 0:
		print("[GameManager] Starting level '", level_name, "' with dialogue")
		if UIManager and UIManager.has_method("show_dialogue"):
			UIManager.show_dialogue(dialogues)
		else:
			push_warning("[GameManager] UIManager not found or missing show_dialogue method")
	else:
		print("[GameManager] No dialogue for level '", level_name, "'")

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
		UIManager.show_game_over(false)  # false = failure
		print("GameManager: Told UIManager to show game over")

func on_level_completed() -> void:
	"""Called by FinishZone when player completes level - signals UP from FinishZone"""
	print("GameManager: Level completed!")
	
	# Call DOWN to handle_game_result
	handle_game_result(true)  # true = success/win

func on_chase_started() -> void:
	"""Called by Mom when chase starts - signals UP from Mom"""
	print("GameManager: Chase started!")
	
	# Call DOWN to MusicManager to change music
	var music_manager = get_tree().get_first_node_in_group("music_manager")
	if music_manager and music_manager.has_method("switch_to_danger_music"):
		music_manager.switch_to_danger_music()
		print("GameManager: Told MusicManager to switch to danger music")
	else:
		push_warning("GameManager: MusicManager not found!")

func on_chase_ended() -> void:
	"""Called by Mom when chase ends - signals UP from Mom"""
	print("GameManager: Chase ended!")
	
	# Call DOWN to MusicManager to change music back
	var music_manager = get_tree().get_first_node_in_group("music_manager")
	if music_manager and music_manager.has_method("switch_to_game_music"):
		music_manager.switch_to_game_music()
		print("GameManager: Told MusicManager to switch to game music")
	else:
		push_warning("GameManager: MusicManager not found!")

func get_door_config(door_id: String) -> Dictionary:
	"""Get configuration for a specific door"""
	if door_id in door_configs:
		return door_configs[door_id]
	else:
		# Return default config for unknown doors - locked by default
		print("[GameManager] Door '", door_id, "' not found in config, defaulting to locked")
		return {"is_locked": true, "required_key_id": ""}

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

# ===== RESULT MANAGER FUNCTIONALITY =====

func handle_game_result(is_success: bool) -> void:
	"""Called when a game result occurs (win or lose)"""
	# Prevent handling multiple results simultaneously
	if is_processing_result:
		print("[GameManager] Result already being processed, ignoring duplicate call")
		return
	
	is_processing_result = true
	print("[GameManager] Handling game result: is_success=", is_success)
	
	# Unlock next level if success
	if is_success:
		var scene_path = get_tree().current_scene.scene_file_path
		if "level1" in scene_path:
			unlock_level(2)
		elif "level2" in scene_path:
			unlock_level(3)
		elif "level3" in scene_path:
			unlock_level(4)
		elif "level4" in scene_path:
			unlock_level(5)
		elif "level5" in scene_path:
			unlock_level(6)
	
	# Call DOWN to UIManager to show game over overlay
	if UIManager and UIManager.has_method("show_game_over"):
		UIManager.show_game_over(is_success)
		print("[GameManager] Told UIManager to show game over")
	else:
		push_warning("[GameManager] UIManager not found!")
	
	# Play the appropriate sound
	play_result_sound(is_success)
	
	# Note: The overlay buttons will handle transitions
	# No need to await here - buttons take control

func play_result_sound(is_success: bool) -> void:
	"""Play the appropriate result sound via the sound manager"""
	var sound_manager = get_tree().get_first_node_in_group("sound_manager")
	if sound_manager and sound_manager.has_method("play_result_sound"):
		sound_manager.play_result_sound(is_success)
		print("[GameManager] Called sound manager to play result sound")
	else:
		push_warning("[GameManager] Sound manager not found!")

func handle_success() -> void:
	"""Handle successful level completion"""
	print("[GameManager] Handling success")
	
	# Get current level info
	var current_level = get_current_level()
	
	match current_level:
		"tutorial":
			print("[GameManager] Tutorial complete - showing winning screen")
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")
		
		"stage1", "level1":
			print("[GameManager] Stage 1 complete - Unlocking level 2 and showing winning screen!")
			unlock_level(2)
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")
		
		_:
			print("[GameManager] Level complete - showing winning screen")
			await get_tree().create_timer(0.5).timeout
			SceneTransition.change_scene("res://scene/game_results/winning_bg.tscn")

func handle_failure() -> void:
	"""Handle player failure (caught by mom)"""
	print("[GameManager] Handling failure - restarting level")
	
	# Just restart the level
	get_tree().paused = false
	get_tree().reload_current_scene()

func get_current_level() -> String:
	"""Get the current level name"""
	var scene = get_tree().current_scene
	if scene:
		return scene.name.to_lower()
	return ""

func get_next_level_path() -> String:
	"""Get the path to the next level based on current level"""
	var scene_path = get_tree().current_scene.scene_file_path
	
	if "level1" in scene_path:
		return "res://scene/levels/level2.tscn"
	elif "level2" in scene_path:
		return "res://scene/levels/level3.tscn"
	elif "level3" in scene_path:
		return "res://scene/levels/level4.tscn"
	elif "level4" in scene_path:
		return "res://scene/levels/level5.tscn"
	elif "level5" in scene_path:
		return "res://scene/levels/level6.tscn"
	else:
		return "res://scene/menu/main_menu.tscn"
